package Plagger::Plugin::Publish::HatenaBookmark;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Time::HiRes qw(sleep);
use XML::Atom::Client;
use XML::Atom::Entry;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.init'        => \&initialize,
        'publish.entry.fixup' => \&add_entry,
    );
}

sub rule_hook { 'publish.entry.fixup' }

sub initialize {
    my ($self, $context, $args) = @_;
    $self->{client} = XML::Atom::Client->new;
    $self->{client}->username($self->conf->{username});
    $self->{client}->password($self->conf->{password});
}

sub add_entry {
    my ($self, $context, $args) = @_;

    my @tags = @{$args->{entry}->tags};
    my $tag_string = @tags ? join('', map "[$_]", @tags) : '';

    my $entry = XML::Atom::Entry->new;
    $entry->title(encode('utf-8', $args->{entry}->title));

    my $link  = XML::Atom::Link->new;
    $link->rel('related');
    $link->type('text/html');
    $link->href($args->{entry}->link);
    $entry->add_link($link);

    if ($self->conf->{post_body}) {
        $entry->summary( encode('utf-8', $tag_string . $args->{entry}->body_text) ); # xxx should be summary
    } else {
        $entry->summary( encode('utf-8', $tag_string) );
    }

    my $loc = $self->{client}->createEntry('http://b.hatena.ne.jp/atom/post', $entry);
    unless ($loc) {
        $context->log(error => $self->{client}->errstr);
        return;
    }

    my $sleeping_time = $self->conf->{interval} || 3;
    $context->log(info => "Post entry success. sleep $sleeping_time.");
    sleep( $sleeping_time );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::HatenaBookmark - Post to Hatena::Bookmark automatically

=head1 SYNOPSIS

  - module: Publish::HatenaBookmark
    config:
      username: your-username
      password: your-password
      interval: 2
      post_body: 1

=head1 DESCRIPTION

This plugin automatically posts feed updates to Hatena Bookmark
L<http://b.hatena.ne.jp/>. It supports automatic tagging as well. It
might be handy for syncronizing delicious feeds into Hatena Bookmark.

=head1 AUTHOR

fuba

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Publish::Delicious>, L<XML::Atom>

=cut
