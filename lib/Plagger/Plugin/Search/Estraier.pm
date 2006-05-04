package Plagger::Plugin::Search::Estraier;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Search::Estraier;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{url}      ||= "http://localhost:1978/node/Plagger";
    $self->conf->{username} ||= "admin";
    $self->conf->{password} ||= "admin";
    $self->conf->{timeout}  ||= 30;

    $self->{node} = Search::Estraier::Node->new(
        url => $self->conf->{url},
    );
    $self->{node}->set_auth($self->conf->{username}, $self->conf->{password});
    $self->{node}->set_timeout($self->conf->{timeout});
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    my $id  = $self->{node}->uri_to_id($args->{entry}->permalink);
    $context->log(info => "Going to index entry ", $args->{entry}->permalink . ($id ? " with id=$id" : ""));

    my $doc = Search::Estraier::Document->new;
    $doc->add_attr('@uri' => $args->{entry}->permalink);
    $doc->add_attr('@title' => _u($args->{entry}->title));
    $doc->add_attr('@cdate' => $args->{entry}->date->format('W3CDTF'));
    $doc->add_attr('@author' => _u($args->{entry}->author)) if $args->{entry}->author;

    $doc->add_text(_u($args->{entry}->body_text));
    $doc->add_hidden_text(_u($args->{entry}->title));

    $doc->add_attr('@id' => $id) if $id; # update mode

    $self->{node}->put_doc($doc) or $context->error("Put failure: " . $self->{node}->status);
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
      url: http://localhost:1978/node/Plagger
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
