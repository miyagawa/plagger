package Plagger::Plugin::Publish::LivedoorClip;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Time::HiRes qw(sleep);
use URI;
use Plagger::Mechanize;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry.fixup' => \&add_entry,
        'publish.init'        => \&initialize,
    );
}

sub initialize {
    my $self = shift;
    unless ($self->{mech}) {
        my $mech = Plagger::Mechanize->new;
        $mech->agent_alias('Windows IE 6');
        $mech->quiet(1);
        $self->{mech} = $mech;
    }
    $self->login_livedoor_clip;
}


sub add_entry {
    my ($self, $context, $args) = @_;

    my @tags = @{$args->{entry}->tags};
    my $tag_string = @tags ? join(' ', @tags) : '';

    my $summary;
    if ($self->conf->{post_body}) {
        $summary = encode('utf-8', $tag_string . $args->{entry}->body_text); # xxx should be summary
    } else {
        $summary = encode('utf-8', $tag_string);
    }

    my $uri = URI->new('http://clip.livedoor.com/clip/add');
    $uri->query_form(
        link  => $args->{entry}->link,
        jump  => 'page',
        tags  => encode('utf-8', $tag_string),
        title => encode('utf-8', $args->{entry}->title),
        notes => $summary,
    );

    my $add_url = $uri->as_string;
    my $res = eval { $self->{mech}->get($add_url) };
    if ($res && $res->is_success) {
        eval { $self->{mech}->submit_form(form_name => 'clip') };
        if ($@) {
           $context->log(info => "can't submit: " . $args->{entry}->link);
        } else {
            $context->log(info => "Post entry success.");
        }
    } else {
       $context->log(info => "fail to clip $add_url HTTP Status: " . $res->code);
    }
 
    my $sleeping_time = $self->conf->{interval} || 3;
    $context->log(info => "sleep $sleeping_time.");
    sleep( $sleeping_time );
}

sub login_livedoor_clip {
    my $self = shift;
    unless ($self->conf->{livedoor_id} && $self->conf->{password}) {
        Plagger->context->log(error => 'set your livedoor_id and password before login.');
    }
    unless ($self->_has_clip_account) {
        Plagger->context->log(error => 'register to livedoor clip before using this module.');
    }
    my $res = $self->{mech}->get('http://clip.livedoor.com/register/');
    $self->{mech}->submit_form(
        form_name => 'loginForm',
        fields => {
            livedoor_id => $self->conf->{livedoor_id},
            password    => $self->conf->{password},
        },
    );
    # XXX login checking (WWW::Mechanize->uri() doesn't work correct).
    $self->{mech}->get('http://clip.livedoor.com/register/');
    $self->{_logged_in} = $self->{mech}->uri =~ m{^http://clip\.livedoor\.com/} ? 1 : 0;
    unless ($self->{_logged_in}) {
        Plagger->context->log(error => "failed to login to livedoor clip.");
    }
}

sub _has_clip_account {
    my $self = shift;
    my $myclip_url = sprintf('http://clip.livedoor.com/clips/%s', $self->conf->{livedoor_id});
    my $res = $self->{mech}->get($myclip_url);
    return $res->is_success ? 1 : 0;
}


1;

__END__

=head1 NAME

Plagger::Plugin::Publish::LivedoorClip - Post to livedoor clip automatically

=head1 SYNOPSIS

  - module: Publish::LivedoorClip
    config:
      livedoor_id: your-username
      password: your-password
      interval: 2
      post_body: 1

=head1 DESCRIPTION

This plugin automatically posts feed updates to livedoor clip
L<http://clip.livedoor.com/>. It supports automatic tagging as well. It
might be handy for syncronizing delicious feeds into livedoor clip.

=head1 AUTHOR

Kazuhiro Osawa, Koichi Taniguchi

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Publish::HatenaBookmark>, L<Plagger::Mechanize>

=cut
