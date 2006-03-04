package Plagger::Plugin::Publish::Playlog;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use XML::Atom::Client;
use XML::Atom::Entry;

sub rule_hook { 'publish.feed' }

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $api = XML::Atom::Client->new;
    $api->username($self->conf->{username});
    $api->password($self->conf->{password});

   for (@{$args->{feed}->entries}){
        my $entry = XML::Atom::Entry->new;
        my $otolog = XML::Atom::Namespace->new(otolog => 'http://otolog.org/ns/music#');
        for my $key (keys %{$_->meta}){
            $entry->set($otolog, 'otolog:' . $key, $_->meta->{$key});
        }
        $context->log( info => $_->meta->{artist} . ' ' . $_->meta->{track});
        $api->createEntry('http://mss.playlog.jp/playlog', $entry);
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::Playlog - Publish music data to playlog.jp

=head1 SYNOPSIS

  - module: Publish::Playlog
    config:
      username: your-playlog-id
      password: xxxxxxxx

=head1 DESCRIPTION

This plugin publish music data to playlog.jp with AtomPP.

=head1 CONFIG

=over 4

=item username, password

Your playlog ID and password to login.

=back

=head1 AUTHOR

Gosuke Miyashita, E<lt>gosukenator@gmail.comE<gt>

=head1 SEE ALSO

L<Plagger>

=cut
