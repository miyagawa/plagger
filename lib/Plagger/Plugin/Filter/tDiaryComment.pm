package Plagger::Plugin::Filter::tDiaryComment;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    return unless $self->tdiary_magic($args->{feed});

    $context->log(debug => "Found tDiary feed " . $args->{feed}->url);

    for my $entry ($args->{feed}->entries) {
        if ($entry->link =~ /\.html#c\d+$/) {
            # TODO: make it work with Plagger::Action framework
            $context->log(info => "Strip comment " . $entry->link);
            $args->{feed}->delete_entry($entry);
        }
    }
}

# http://cvs.sourceforge.net/viewcvs.py/tdiary/plugin/makerss.rb?rev=1.37
our $FeedMagic = <<'MAGIC';
^<\?xml version="1.0" encoding=".*?"\?>
<\?xml-stylesheet href="rss\.css" type="text/css"\?>
<rdf:RDF xmlns="http://purl\.org/rss/1\.0/" xmlns:rdf="http://www\.w3\.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl\.org/dc/elements/1\.1/" xmlns:content="http://purl\.org/rss/1\.0/modules/content/" xml:lang=".*?">
MAGIC

sub tdiary_magic {
    my($self, $feed) = @_;

    my $xml = $feed->source_xml or return;
    $xml =~ /$FeedMagic/o;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::tDiaryComment - Rate tDiary comment

=head1 SYNOPSIS

    - module: Filter::tDiaryComment

=head1 DESCRIPTION

tDiary (L<http://www.tdiary.org/>) RSS feed by default contains
comments to the blog as well. They're useful to keep track of the
discussion, but sometimes are annoying to read.

This plugin strips the comment entries from tDiary RSS feeds.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhiro at mobilefactory.jpE<gt>

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
