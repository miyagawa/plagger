package Plagger::Plugin::Summary::TrackbackRDF;
use strict;
use base qw( Plagger::Plugin );

use HTML::Entities;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    # XXX share fetched content with EntryFullText. #387
    my $url   = $args->{entry}->permalink;
    my $agent = Plagger::UserAgent->new;
       $agent->parse_head(0);
    my $res   = $agent->fetch($url, $self, { NoNetwork => 12 * 3600 });

    if ($res->is_error) {
        $context->log(error => "Fetch $url failed: " . $res->status);
    }

    my $content = Plagger::Util::decode_content($res->content);
    while ($content =~ m!(<rdf:RDF.*?</rdf:RDF>)!sg) {
        my $rdf = $1;
        if ($rdf =~ /\s*dc:description="(.*?)"\s*/) {
            return HTML::Entities::decode($1);
        }
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::TrackbackRDF - Extract description from Trackback RDF

=head1 SYNOPSIS

  - module: Summary::TrackbackRDF

=head1 DESCRIPTION

This plugin fetches individual permalink and extracts dc:description
tag in Trackback RDF, to use as summary.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
