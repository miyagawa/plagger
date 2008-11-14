package Plagger::FeedParser;
use strict;

use Feed::Find;
use XML::Atom;
use XML::Feed;
use XML::Feed::RSS;
$XML::Feed::Format::RSS::PREFERRED_PARSER = $XML::Feed::RSS::PREFERRED_PARSER = "XML::RSS::LibXML";
$XML::Atom::ForceUnicode = 1;

use Plagger::Util;

sub parse {
    my($class, $content_ref) = @_;

    # override XML::LibXML with Liberal
    my $sweeper; # XML::Liberal >= 0.13

    eval { require XML::Liberal };
    if (!$@ && $XML::Liberal::VERSION >= 0.10) {
        $sweeper = XML::Liberal->globally_override('LibXML');
    }

    my $remote = eval { XML::Feed->parse($content_ref) }
        or Carp::croak("Parsing content failed: " . ($@ || XML::Feed->errstr));

    return $remote;
}

sub discover {
    my($self, $res) = @_;

    my $content_type = eval { $res->content_type } ||
                       $res->http_response->content_type ||
                       "text/xml";

    $content_type =~ s/;.*$//; # strip charset= cruft

    my $content = $res->content;
    if ( $Feed::Find::IsFeed{$content_type} || $self->looks_like_feed(\$content) ) {
        return $res->uri;
    } else {
        $content  = Plagger::Util::decode_content($res);
        my @feeds = Feed::Find->find_in_html(\$content, $res->uri);
        if (@feeds) {
            return $feeds[0];
        } else {
            return;
        }
    }
}

sub looks_like_feed {
    my($self, $content_ref) = @_;
    $$content_ref =~ m!<rss |<rdf:RDF\s+.*?xmlns="http://purl\.org/rss|<feed\s+xmlns="!s;
}

1;
