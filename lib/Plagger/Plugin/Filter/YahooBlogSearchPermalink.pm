package Plagger::Plugin::Filter::YahooBlogSearchPermalink;
use strict;
use base qw( Plagger::Plugin );

use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    my $permalink = $entry->permalink;
    if ($permalink =~ s!^http://rd\.yahoo\.co\.jp/rss/l/blogsearch/search/\*!) {
        $entry->permalink($permalink);
        $context->log(info => "Permalink rewritten to $permalink");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::YahooBlogSearchPermalink - Fix Yahoo! Blog Search permalink

=head1 SYNOPSIS

  - module: Filter::YahooBlogSearchPermalink

=head1 DESCRIPTION

This plugin replaces Yahoo! Blog Search feed's redirector URL with
original target URL for entry permalinks. It works with
http://blog-search.yahoo.co.jp/search?p=* feeds.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://blog-search.yahoo.co.jp/>, L<Plagger::Plugin::Subscription::Planet>

=cut
