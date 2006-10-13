package Plagger::Plugin::Summary::HatenaBookmark;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $permalink = $args->{entry}->permalink;
       $permalink =~ s/\#/%23/;
    my $uri = "http://b.hatena.ne.jp/entry/rss/$permalink";

    my $agent = Plagger::UserAgent->new;
    my $summary;
    eval {
        my $feed = $agent->fetch_parse($uri);
        $summary = $feed->tagline;
    };

    if ($@) {
        $context->log(warn => "Fetch $uri failed: $@");
        return;
    }

    return $summary;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::HatenaBookmark - Generate summary using Hatena Bookmark summary field

=head1 SYNOPSIS

  - module: Summary::HatenaBookmark

=head1 DESCRIPTION

This plugin calls Hatena Bookmark Feed API (atomfeed) to get summary
from a certain web page.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
