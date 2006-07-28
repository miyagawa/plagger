package Plagger::Plugin::Search::KinoSearch;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use KinoSearch::Index::Term;
use KinoSearch::InvIndexer;
use KinoSearch::Searcher;
use KinoSearch::Analysis::PolyAnalyzer;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{language} ||= "en";
    $self->conf->{invindex} ||= $self->cache->path_to('invindex');

    # TODO: CJKAnalyzer
    $self->{analyzer} = KinoSearch::Analysis::PolyAnalyzer->new(
        analyzers => [
            KinoSearch::Analysis::LCNormalizer->new,
            KinoSearch::Analysis::Tokenizer->new,
        ],
    );

    $self->{indexer} = KinoSearch::InvIndexer->new(
        invindex => $self->conf->{invindex},
        create   => 1,
        analyzer => $self->{analyzer},
    );

    $self->{indexer}->spec_field( name => 'link' );
    $self->{indexer}->spec_field( name => 'title', boost => 3 );
    $self->{indexer}->spec_field( name => 'body' );
    $self->{indexer}->spec_field( name => 'date' );
    $self->{indexer}->spec_field( name => 'author' );
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry'    => \&entry,
        'publish.finalize' => \&finalize,
        'searcher.search'  => \&search,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    return unless $args->{entry}->permalink;
    $context->log(info => "Going to index entry " . $args->{entry}->permalink );

    my $term = KinoSearch::Index::Term->new( url => $args->{entry}->permalink );
    $self->{indexer}->delete_docs_by_term($term);

    my $doc = $self->{indexer}->new_doc;
    $doc->set_value( link   => $args->{entry}->permalink );
    $doc->set_value( title  => $args->{entry}->title );
    $doc->set_value( body   => $args->{entry}->body_text );
    $doc->set_value( date   => $args->{entry}->date->format('W3CDTF') ) if $args->{entry}->date;
    $doc->set_value( author => $args->{entry}->author ) if $args->{entry}->author;

    $self->{indexer}->add_doc($doc);
}

sub finalize {
    my($self, $context, $args) = @_;
    $self->{indexer}->finish;

    $self->search($context, { query => "murakami" });
}

sub search {
    my($self, $context, $args) = @_;

    my $searcher = KinoSearch::Searcher->new(
        invindex => $self->conf->{invindex},
        analyzer => $self->{analyzer},
    );

    my $feed = Plagger::Feed->new;
    $feed->type('search:KinoSearch');
    $feed->title("Search: $args->{query}");

    my $hits = $searcher->search( query => $args->{query} );
    while ( my $hit = $hits->fetch_hit_hashref ) {
        my $entry = Plagger::Entry->new;

        for my $col (qw( link title body date author )) {
            $entry->$col($hit->{$col}) if defined $hit->{$col};
        }
        $feed->add_entry($entry);
    }

    return $feed;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Search::KinoSearch - Index entries using KinoSearch

=head1 SYNOPSIS

  - module: Search::KinoSearch
    config:
      invindex: /path/to/invindex

=head1 DESCRIPTION


=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<KinoSearch>

=cut
