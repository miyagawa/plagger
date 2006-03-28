package Plagger::Plugin::Filter::BitTorrent;
use strict;
use warnings;
use base qw (Plagger::Plugin);
use Data::Dumper;

our $VERSION = '0.01';

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook( $self, 'update.feed.fixup' => \&filter, );
}

sub filter {
    my ( $self, $context, $args ) = @_;
    for my $entry ( $args->{feed}->entries ) {
        my $to_del = 1;
        for my $torrent ( @{ $self->conf } ) {
            if ( $entry->title =~ /$torrent->{'regexp'}/i ) {
                $to_del = 0;
                $context->log( info => "Found " . $entry->title );
                if ( defined $torrent->{'tag'} ) {
                    for my $tag ( split " ", $torrent->{'tag'} ) {
                        $entry->add_tag($tag);
                    }
                }
            }
        }
        if ( $to_del == 1 ) {
            $args->{feed}->delete_entry($entry);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::BitTorrent - Filtering torrent file

=head1 SYNOPSIS

    - module: Filter::BitTorrent
      config:
        - name: Lost
          regexp: lost\.?\s?s02e\d+\.?\s?(proper)?\.?\s?hdtv\.?\s?xvid
          tag: tv series lost fantastic
        - name: what ever
          regexp: the regex
          tag: tag1 tag2 ...
    

=head1 DESCRIPTION


=head1 AUTHOR

Franck Cuny 

=head1 SEE ALSO

L<Plagger>

=cut
