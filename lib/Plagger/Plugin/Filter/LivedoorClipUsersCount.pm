package Plagger::Plugin::Filter::LivedoorClipUsersCount;
use strict;
use base qw( Plagger::Plugin );

use XMLRPC::Lite;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&update,
    );
}

sub update {
    my ( $self, $context, $args ) = @_;

    my @permalink = map $_->permalink, $args->{feed}->entries;

    $context->log( info => 'Requesting XMLRPC call to livedoorClip with '
            . scalar(@permalink)
            . ' link(s)' );

    my $map = XMLRPC::Lite
        ->proxy('http://rpc.clip.livedoor.com/count')
        ->call( 'clip.getCount', @permalink )
        ->result;

    unless ($map) {
        $context->log( warn => 'livedoorClip XMLRPC failed' );
        return;
    }

    $context->log( info => 'XMLRPC request success.' );

    for my $entry ( $args->{feed}->entries ) {
        if ( defined( my $count = $map->{ $entry->permalink } ) ) {
            $entry->meta->{livedoorclip_users} = $count;
        }
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::LivedoorClipUsersCount - Queries livedoorClip users count

=head1 SYNOPSIS

  - module: Filter::LivedoorClipUsersCount

=head1 DESCRIPTION

This plugin queries livedoor Clip (L<http://clip.livedoor.com/>) how
many people clipped each of feed entries, using its XMLRPC API
C<clip.getCount>.

Users count is stored in C<livedoorclip_users> metadata of
Plagger::Entry so that other plugins or smartfeeds can make use of.

=head1 AUTHOR

Masafumi Otsune

=head1 SEE ALSO

L<Plagger>, L<http://wiki.livedoor.jp/staff_clip/d/%a5%af%a5%ea%a5%c3%a5%d7%b7%ef%bf%f4%bc%e8%c6%c0%20API>

=cut
