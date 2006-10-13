package Plagger::Plugin::Search::Estraier;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Search::Estraier;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{url}      ||= "http://localhost:1978/node/plagger";
    $self->conf->{username} ||= "admin";
    $self->conf->{password} ||= "admin";
    $self->conf->{timeout}  ||= 30;

    $self->{node} = Search::Estraier::Node->new(
        url => $self->conf->{url},
        debug => $self->conf->{debug},
    );
    $self->{node}->set_auth($self->conf->{username}, $self->conf->{password});
    $self->{node}->set_timeout($self->conf->{timeout});
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
        'searcher.search'  => \&search,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    return unless $args->{entry}->permalink;

    my $id  = $self->{node}->uri_to_id($args->{entry}->permalink);
    $context->log(info => "Going to index entry " . $args->{entry}->permalink . ($id ? " with id=$id" : ""));

    my $doc = Search::Estraier::Document->new;
    $doc->add_attr('@uri' => $args->{entry}->permalink);
    $doc->add_attr('@title' => $args->{entry}->title->utf8);
    $doc->add_attr('@cdate' => $args->{entry}->date->format('W3CDTF')) if $args->{entry}->date;
    $doc->add_attr('@author' => $args->{entry}->author->utf8) if $args->{entry}->author;

    $doc->add_text($args->{entry}->body->utf8);
    $doc->add_hidden_text($args->{entry}->title->utf8);

    $doc->add_attr('@id' => $id) if $id; # update mode

    $self->{node}->put_doc($doc) or $context->error("Put failure: " . $self->{node}->status);
}

sub search {
    my($self, $context, $args) = @_;

    my $cond = Search::Estraier::Condition->new;
    $cond->set_phrase( encode_utf8($args->{query}) );

    my $nres = $self->{node}->search($cond, 0);
    defined $nres or $context->error("search failed: " . $self->{node}->status);

    my $feed = Plagger::Feed->new;
    $feed->type('search:Estraier');
    $feed->title("Search: $args->{query}");

    for my $i ( 0 .. $nres->doc_num - 1 ) {
        my $doc = $nres->get_doc($i);
        my $entry = Plagger::Entry->new;

        $entry->link( $doc->attr('@uri') );
        $entry->title( decode_utf8($doc->attr('@title')) );
        $entry->date( $doc->attr('@cdate') )    if $doc->attr('@cdate');
        $entry->author( decode_utf8($doc->attr('@author')) ) if $doc->attr('@author');
        $entry->body( decode_utf8($doc->snippet) );

        $feed->add_entry($entry);
    }

    return $feed;
}

sub _u {
    my $str = shift;
    Encode::_utf8_off($str);
    $str;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Search::Estraier - Search entries using Hyper Estraier P2P

=head1 SYNOPSIS

  - module: Search::Estraier
    config:
      url: http://localhost:1978/node/plagger
      username: foobar
      password: p4ssw0rd

=head1 DESCRIPTION

This plugin uses Hyper Estraier
(L<http://hyperestraier.sourceforge.net/>) and its P2P Node API to
search feed entries aggregated by Plagger.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://hyperestraier.sourceforge.net/>, L<Search::Estraier>

=cut
