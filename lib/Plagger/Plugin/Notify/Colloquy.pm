package Plagger::Plugin::Notify::Colloquy;

use strict;
use base qw( Plagger::Plugin );
use Data::Dumper;
use Encode;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook( $self, 'publish.entry' => \&update, );
}

sub update {
    my ( $self, $context, $args ) = @_;

    $context->log(
        info => "Notifying " . $args->{entry}->title . " to Colloquy" );

    for my $entry ( $args->{feed}->entries ) {
        my ( $header_line, $body_line ) = $self->colloquy_templatize($entry);

        Encode::_utf8_off($header_line) if Encode::is_utf8($header_line);
        Encode::from_to( $header_line, 'utf-8', $self->conf->{charset} )
            if $self->conf->{charset} && $self->conf->{charset} ne 'utf-8';

        foreach my $chan ( @{$self->conf->{channels}} ) {
            system( 'osascript', 'bin/colloquy_tell.scpt', $header_line,
                $body_line, $chan ) == 0
                or Plagger->context->error("$!");
            sleep(1);
        }
    }
}

sub colloquy_templatize {
    my ( $self, $entry ) = @_;
    my ( $header_line, $body_line );
    if ( $entry->title ) {
        $header_line = $entry->title_text . ": ";
    }
    if ( $entry->author ) {
        $header_line .= "(" . $entry->author . ")";
    }
    $body_line = $entry->permalink;
    return ( $header_line, $body_line );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Colloquy - Notify feed updates to IRC via Colloquy

=head1 SYNOPSIS

  - module: Notify::Colloquy
    config:
      channels: 
				- #tirnanog
				- #plagger
	  	charset: iso-8859-1

=head1 DESCRIPTION

This plugin allows you to notify feed updates to an IRC channel using
the Colloquy client. 

=head1 AUTHOR

Franck Cuny

=head1 SEE ALSO

L<Plagger>

=cut
