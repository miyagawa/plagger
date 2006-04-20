package Plagger::Plugin::Subscription::LivedoorReader;
use strict;
use base qw( Plagger::Plugin );

use JSON::Syck;
use URI;
use URI::QueryParam;
use WWW::Mechanize;

sub plugin_id {
    my $self = shift;
    $self->class_id . '-' . $self->conf->{username};
}

sub register {
    my($self, $context) = @_;

    $self->init_reader;
    $context->register_hook(
        $self,
        'subscription.load' => \&notifier,
    );
}

sub init_reader {
    my $self = shift;
    $self->{mech} = WWW::Mechanize->new(cookie_jar => $self->cache->cookie_jar);

    unless (defined($self->conf->{username}) && defined($self->conf->{password})) {
        Plagger->context->error("username and/or password is missing");
    }
}

sub notifier {
    my($self, $context) = @_;

    $self->{mech}->get("http://rpc.reader.livedoor.com/notify?user=" . $self->conf->{username});
    my $content = $self->{mech}->content;

    # copied from WebService/Bloglines.pm

    # |A|B| where A is the number of unread items
    $content =~ /\|([\-\d]+)|(.*)|/
	or $context->error("Bad Response: $content");

    my($unread, $url) = ($1, $2);

    # A is -1 if the user email address is wrong.
    if ($unread == -1) {
	$context->error("Bad username: $self->{username}");
    }

    return unless $unread;

    $context->log(info => "You have $unread unread item(s) on livedoor Reader.");

    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->sync(@_) });
    $context->subscription->add($feed);
}

sub sync {
    my($self, $context, $args) = @_;

    my $mark_read = $self->conf->{mark_read};
       $mark_read = 1 unless defined $mark_read;

    $self->login_reader();

    my $subs = $self->_request("/api/subs", { unread => 1 });

    for my $sub (@$subs) {
        $context->log(debug => "get unread items of $sub->{subscribe_id}");
        my $data = $self->_request("/api/unread", { subscribe_id => $sub->{subscribe_id} });
        $self->_request("/api/touch_all", { subscribe_id => $sub->{subscribe_id} })
            if $mark_read;

        my $feed = Plagger::Feed->new;
        $feed->type('livedoorReader');
        $feed->title($data->{channel}->{title});
        $feed->link($data->{channel}->{link});
        $feed->url($data->{channel}->{feedlink});
        $feed->image({ url => $data->{channel}->{image} || $sub->{icon} });
        $feed->meta->{livedoor_reader_id} = $sub->{subscribe_id};
        $feed->meta->{rate} = $sub->{rate};
        $feed->add_tag($_) for @{$sub->{tags}};
        $feed->add_tag($sub->{folder}) if $sub->{folder};
        $feed->updated( Plagger::Date->from_epoch($sub->{modified_on}) ) if $sub->{modified_on};
        $feed->description($data->{channel}->{description});
        $feed->meta->{livedoor_reader_subscribers_count} = $data->{channel}->{subscribers_count};

        for my $item ( @{$data->{items}} ) {
            my $entry = Plagger::Entry->new;
            $entry->title($item->{title});
            $entry->author($item->{author}) if $item->{author};
            $entry->link($item->{link});
            # TODO support enclosure
            $entry->tags([ $item->{category} ]) if $item->{category};
            $entry->date( Plagger::Date->from_epoch($item->{modified_on}) ); # xxx created_on as well
            $entry->meta->{livedoor_reader_item_id} = $item->{id};
            $entry->feed_link($feed->link);
            $entry->body($item->{body});

            $feed->add_entry($entry);
        }

        $context->update->add($feed);
    }
}

sub login_reader {
    my $self = shift;

    local $^W; # input type="search" warning
    $self->{mech}->get("http://reader.livedoor.com/reader/");

    if ($self->{mech}->content =~ /name="loginForm"/) {
        Plagger->context->log(debug => "Logging in to Livedoor Reader");
        $self->{mech}->submit_form(
            form_name => 'loginForm',
            fields => {
                livedoor_id => $self->conf->{username},
                password    => $self->conf->{password},
            },
        );

        if ( $self->{mech}->content =~ /class="headcopy"/ ) {
            Plagger->context->error("Failed to login using username & password");
        }
    }
}

sub _request {
    my($self, $method, $param) = @_;

    my $uri = URI->new_abs($method, "http://reader.livedoor.com/");
    $uri->query_param(%$param) if $param;

    $self->{mech}->get($uri->as_string);

    return JSON::Syck::Load($self->{mech}->content);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::LivedoorReader - Synchronize livedoor Reader with JSON API

=head1 SYNOPSIS

  - module: Subscription::LivedoorReader
    config:
      username: your-livedoor-id
      password: your-password
      mark_read: 1

=head1 DESCRIPTION

This plugin allows you to synchronize your subscription using Livedoor
Reader JSON API.

=head1 CONFIGURATION

=over 4

=item username, password

Your username & password to use with livedoor Reader.

=item mark_read

C<mark_read> specifies whether this plugin I<marks as read> the items
you synchronize. With this option set to 0, you will get the
duplicated updates everytime you run Plagger, until you mark them
unread using Livedoor Reader web interface.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::Bloglines>, L<http://reader.livedoor.com/>

=cut

