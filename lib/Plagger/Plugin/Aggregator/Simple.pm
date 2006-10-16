package Plagger::Plugin::Aggregator::Simple;
use strict;
use base qw( Plagger::Plugin );

use Feed::Find;
use Plagger::Enclosure;
use Plagger::FeedParser;
use Plagger::UserAgent;
use Plagger::Text;
use List::Util qw(first);
use UNIVERSAL::require;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle'  => \&aggregate,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    my $res = $self->fetch_content($url) or return;

    my $content_type = eval { $res->content_type } ||
                       $res->http_response->content_type ||
                       "text/xml";

    $content_type =~ s/;.*$//; # strip charset= cruft

    my $feed_url = Plagger::FeedParser->discover($res);
    if ($url eq $feed_url) {
        $self->handle_feed($url, \$res->content, $args->{feed});
    } elsif ($feed_url) {
        $res = $self->fetch_content($feed_url) or return;
        $self->handle_feed($feed_url, \$res->content, $args->{feed});
    } else {
        return;
    }

    return 1;
}

sub fetch_content {
    my($self, $url) = @_;

    my $context = Plagger->context;
    $context->log(info => "Fetch $url");

    my $agent = Plagger::UserAgent->new;
    my $response = $agent->fetch($url, $self);

    if ($response->is_error) {
        $context->log(error => "GET $url failed: " .
                      $response->http_status . " " .
                      $response->http_response->message);
        return;
    }

    # TODO: handle 301 Moved Permenently and 410 Gone
    $context->log(debug => $response->status . ": $url");

    $response;
}

sub handle_feed {
    my($self, $url, $xml_ref, $feed) = @_;

    my $context = Plagger->context;

    my $args = { content => $$xml_ref };
    $context->run_hook('aggregator.filter.feed', $args);

    my $remote = eval { Plagger::FeedParser->parse(\$args->{content}) };
    if ($@) {
        $context->log(error => "Parser $url failed: $@");
        return;
    }

    $feed ||= Plagger::Feed->new;
    $feed->title(_u($remote->title)) unless defined $feed->title;
    $feed->url($url);
    $feed->link($remote->link);
    $feed->description(_u($remote->tagline)); # xxx should support Atom 1.0
    $feed->language($remote->language);
    $feed->author(_u($remote->author));
    $feed->updated($remote->modified);

    Encode::_utf8_on($$xml_ref);
    $feed->source_xml($$xml_ref);

    if ($remote->format eq 'Atom') {
        $feed->id( $remote->{atom}->id );
    }

    if ($remote->format =~ /^RSS/) {
        $feed->image( \%{$remote->{rss}->image} )
            if $remote->{rss}->image;
    } elsif ($remote->format eq 'Atom') {
        $feed->image({ url => $remote->{atom}->logo })
            if $remote->{atom}->logo;
    }

    for my $e ($remote->entries) {
        my $entry = Plagger::Entry->new;
        $entry->title(_u($e->title));
        $entry->author(_u($e->author));

        my $category = $e->category;
           $category = [ $category ] if $category && (!ref($category) || ref($category) ne 'ARRAY');
        $entry->tags([ map _u($_), @$category ]) if $category;

        # XXX XML::Feed doesn't support extracting atom:category yet
        if ($remote->format eq 'Atom' && $e->{entry}->can('categories')) {
            my @categories = $e->{entry}->categories;
            for my $cat (@categories) {
                $entry->add_tag( _u($cat->label || $cat->term) );
            }
        }

        my $date = eval { $e->issued } || eval { $e->modified };
        $entry->date( Plagger::Date->rebless($date) ) if $date;

        # xxx nasty hack. We should remove this once XML::Atom or XML::Feed is fixed
        if (!$entry->date && $remote->format eq 'Atom' && $e->{entry}->version eq '1.0') {
            if ( $e->{entry}->published ) {
                my $dt = XML::Atom::Util::iso2dt( $e->{entry}->published );
                $entry->date( Plagger::Date->rebless($dt) ) if $dt;
            }
        }

        $entry->link($e->link);
        $entry->feed_link($feed->link);
        $entry->id($e->id);

        my $content = feed_to_text($e, $e->content);
        my $summary = feed_to_text($e, $e->summary);
        $entry->body($content || $summary);
        $entry->summary($summary) if $summary;

        # per-entry level language support in Atom
        if ($remote->format eq 'Atom' && $e->{entry}->content && $e->{entry}->content->lang) {
            $entry->language($e->{entry}->content->lang);
        }

        # enclosure support, to be added to XML::Feed
        if ($remote->format =~ /^RSS / and my $encls = $e->{entry}->{enclosure}) {
            # some RSS feeds contain multiple enclosures, and we support them
            $encls = [ $encls ] unless ref $encls eq 'ARRAY';

            for my $encl (@$encls) {
                my $enclosure = Plagger::Enclosure->new;
                $enclosure->url( URI->new($encl->{url}) );
                $enclosure->length($encl->{length});
                $enclosure->auto_set_type($encl->{type});
                $entry->add_enclosure($enclosure);
            }
        } elsif ($remote->format eq 'Atom') {
            for my $link ( grep { defined $_->rel && $_->rel eq 'enclosure' } $e->{entry}->link ) {
                my $enclosure = Plagger::Enclosure->new;
                $enclosure->url( URI->new($link->href) );
                $enclosure->length($link->length);
                $enclosure->auto_set_type($link->type);
                $entry->add_enclosure($enclosure);
            }
        }

        # entry image support
        if ($remote->format =~ /^RSS / and my $img = $e->{entry}->{image}) {
            $entry->icon(\%$img);
        }

        my $args = {
            entry      => $entry,
            feed       => $feed,
            orig_entry => $e,
            orig_feed  => $remote,
        };
        $context->run_hook('aggregator.entry.fixup', $args);

        $feed->add_entry($entry);
    }

    $context->log(info => "Aggregate $url success: " . $feed->count . " entries.");
    $context->update->add($feed);
}

sub feed_to_text {
    my($e, $content) = @_;
    return unless $content->body;

    if (ref($e) eq 'XML::Feed::Entry::Atom') {
        # in Atom, be a little strict with TextConstruct
        # TODO: this actually doesn't work since XML::Feed and XML::Atom does the right
        # thing with Atom 1.0 TextConstruct
        if ($content->type eq 'text/plain' || $content->type eq 'text') {
            return Plagger::Text->new(type => 'text', data => $content->body);
        } else {
            return Plagger::Text->new(type => 'html', data => $content->body);
        }
    } elsif (ref($e) eq 'XML::Feed::Entry::RSS') {
        # in RSS there's no explicit way to declare the type. Just guess it
        return Plagger::Text->new_from_text($content->body);
    } else {
        die "Something is wrong: $e";
    }
}

sub _u {
    my $str = shift;
    Encode::_utf8_on($str);
    $str;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Aggregator::Simple - Dumb simple aggregator

=head1 SYNOPSIS

  - module: Aggregator::Simple

=head1 DESCRIPTION

This plugin implements a Plagger dumb aggregator. It crawls
subscription sequentially and parses XML feeds using L<XML::Feed>
module.

It can be also used as a base class for custom aggregators. See
L<Plagger::Plugin::Aggregator::Xango> for example.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XML::Feed>, L<XML::RSS::LibXML>

=cut
