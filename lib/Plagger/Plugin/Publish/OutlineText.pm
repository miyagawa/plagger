# Plagger::Plugin::Publish::OutlineText
# $Id$
package Plagger::Plugin::Publish::OutlineText;
use strict;
use base qw( Plagger::Plugin );

use Encode;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    )
}

my $feed_count = 0;

sub feed {
    my($self, $context, $args) = @_;
    
    push @{ $self->{_feeds} }, $args->{feed};
}

sub finalize {
    my($self, $context, $args) = @_;
    
    my $filename = $self->conf->{filename}  || './outline.txt';
    my $encoding = $self->conf->{encoding} || 'utf8';

    my $out;
    foreach my $feed (@{ $self->{_feeds} }) {
        $out .= '.' . $feed->title . "\n";

        foreach my $entry (@{ $feed->entries }) {
            $out .= '..' . ($entry->title || '') . "\n";

            my $body = $entry->body_text;
            $body =~ s/^\./ \./g;
            $out .= $body . "\n";
        }
    }
    
    $out = encode($encoding, $out);
    
    open my $fh, ">", $filename or $context->error("$filename: $!");
    print $fh $out;
    close $fh;
    
}


1;

__END__

=head1 NAME

Plagger::Plugin::Publish::OutlineText - Publish as hierarchical text

=head1 SYNOPSIS

  - module: Publish::OutlineText
    config:
      filename: /path/to/outline.txt
      encoding: utf8

=head1 DESCRIPTION

This plugin publishes feeds as hierarchical text format.

=head1 CONFIG

=over 4

=item filename

The output filename

=item encoding

The encoding name for the output file. (ex: utf8, shiftjis, euc-jp)

=back

=head1 AUTHOR

Motokazu Sekine (CHEEBOW) @M-Logic, Inc.

=head1 SEE ALSO

L<Plagger>, L<Encode::Supported>

=cut
