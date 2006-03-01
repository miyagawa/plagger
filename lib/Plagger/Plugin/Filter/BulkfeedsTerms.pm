package Plagger::Plugin::Filter::BulkfeedsTerms;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Plagger::UserAgent;
use XML::Simple;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    $context->log(debug => "calling Bulkfeeds Terms API for " . $args->{entry}->link);

    # TODO: needs cache based on URL
    my $ua = Plagger::UserAgent->new;
    my $body = encode("utf-8", $args->{entry}->body_text);

    my %param  = (content => $body);
    $param{apikey} = $self->conf->{apikey} if $self->conf->{apikey};

    my $res = $ua->post("http://bulkfeeds.net/app/terms.xml", \%param);

    unless ($res->is_success) {
        $context->log(error => "Bulkfeeds API failed: " . $res->status_line);
        return;
    }

    my @terms = grep !ref, @{ XMLin($res->content)->{term} };
    $context->log(info => "Terms for " . $args->{entry}->link . ": " . join(", ", @terms));

    for my $term (@terms) {
        $args->{entry}->add_tag($term);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::BulkfeedsTerms - Bulkfeeds Terms API for auto-tagging

=head1 SYNOPSIS

  - module: Filter::BulkfeedsTerms
    config:
      apikey: XXXXXXXXXXXXXXXXXX

=head1 DESCRIPTION

This plugin queries Bulkfeeds (L<http://bulkfeeds.net/> for specific
terms used in entry body and auto-tag them.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://bulkfeeds.net/app/developer.html>

=cut
