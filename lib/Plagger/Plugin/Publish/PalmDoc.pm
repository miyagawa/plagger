# Plagger::Plugin::Publish::PalmDoc
# $Id$
package Plagger::Plugin::Publish::PalmDoc;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use File::Spec;
use Plagger::Date;
use Palm::PalmDoc;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    )
}

sub feed {
    my($self, $context, $args) = @_;
    
    push @{ $self->{_feeds} }, $args->{feed};
}

sub finalize {
    my($self, $context, $args) = @_;
    
    my $path = $self->conf->{path}  || './';
    my $prefix = $self->conf->{prefix} || 'PalmDoc';

    my $feed_count = 0;
    foreach my $feed (@{ $self->{_feeds} }) {
        $feed_count++;
        my $text;
        $text = $self->makeText($feed, $context);
        $text = encode("sjis", $text);

        my $filename = $prefix . '-' . $feed_count . '.pdb';
        my $outfile = File::Spec->catfile($path, $filename);
        my $title = encode("sjis", $feed->title);
        my $doc = Palm::PalmDoc->new({OUTFILE=>$outfile, TITLE=>$title});
        $doc->compression(1);
        $doc->body($text);
        $doc->write_text();
    }
}

sub makeEntryText {
    my($self, $entry, $context) = @_;
    
    my $entry_text = $self->templatize('palmdoc.tt', {
        entry => $entry,
        now   => Plagger::Date->now,
    });

    $entry_text;
}

sub makeMeDocText {
    my($self, $feed, $context) = @_;

    my @entries = @{$feed->entries};
    my $entry_num = @entries;

    my $text;
    $text = "#!Medoc index " . $entry_num . "\n"; 
    my $toc;
    my $body;
    my $lines;
    my $all_lines = 2 + $entry_num;
    foreach my $entry (@entries) {
        my $entry_text = $self->makeEntryText($entry, $context);
        $lines = ($entry_text =~ tr/\n/\n/);
        $toc .= $all_lines . ':' . $entry->title . "\n";
        $body .= $entry_text;
        $all_lines += $lines;
    }
    
    $text .= $toc . $body;
}

sub makeDocText {
    my($self, $feed, $context) = @_;

    my $text;
    foreach my $entry ($feed->entries) {
        my $entry_text = $self->makeEntryText($entry, $context);
        $text .= '[BM]' . $entry_text;
    }    
    $text .= '<[BM]>';

    $text;
}

sub makeText {
    my($self, $feed, $context) = @_;

    my $text;
    if ($self->conf->{medoc}) {
        $text = $self->makeMeDocText($feed, $context)
    } else {
        $text = $self->makeDocText($feed, $context)
    }

    $text;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::PalmDoc - Publish as PalmDoc 

=head1 SYNOPSIS

  - module: Publish::PalmDoc
    config:
      path: /path/to/
      prefix: PalmDoc
      medoc: 1
      
=head1 DESCRIPTION

This plugin publishes feeds as PalmDoc format.

=head1 CONFIG

=over 4

=item path

The directory to save the PalmDoc file.

=item prefix

The prefix to use for the output file. The filename will become <prefix-n.pdb>. (n: integer)

=item medoc

controls the output format. 1 for MeDoc format, 0 for Doc format.

=back

=head1 AUTHOR

Motokazu Sekine (CHEEBOW) @M-Logic, Inc.


=head1 SEE ALSO

L<Plagger>, L<Palm::PalmDoc>

=cut
