package Plagger::Plugin::Filter::StripRSSAd;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;
    my $body = $self->filter($args->{entry}->body);
    $args->{entry}->body($body);
}

sub filter {
    my($self, $body) = @_;

    # rssad.jp
    my $count = $body =~ s!<br clear="all" /><a href="http://rss\.rssad\.jp/rss/ad/.*?" target="_blank".*?><img .*? src="http://rss\.rssad\.jp/rss/img/.*?" border="0"/></a><br.*?>!!;
    Plagger->context->log(debug => "Stripped rssad.jp ad") if $count;

    # plaza.rakuten.co.jp
    $count = $body =~ s!<br clear?=all /><br><SMALL>\n(?:<SCRIPT LANGUAGE="Javascript">\n<\!--\nfunction random\(\).*?infoseek.*?RssPlaza.*</SCRIPT>)?\n<NOSCRIPT>.*?infoseek.*?RssPlaza.*?</NOSCRIPT>\n</SMALL>!!s;
    Plagger->context->log(debug => "Stripped plaza.rakuten ad") if $count;

    # Google AdSense for Feeds
    $count = $body =~ s!<p><map name="google_ad_map_\d+\-\d+"><area.*?></map><img usemap="#google_ad_map_\d+-\d+" border="0" src="http://imageads\.googleadservices\.com/pagead/ads\?.*?" /></p>!!;

    # Google AdSense for Feeds, part 2.
    $count += $body =~ s!<table [^>]*>\n\s*<tr>\n\s*<td><(?:defanged-)?span[^>]*> <br[^>]*></(?:defanged-)?span></td>\n\s*</tr>\s*\n\s*<tr>\n\s*<td><a href="http://imageads\.googleadservices\.com/pagead/imgclick/[^"]*"[^>]*>\n<img [^>]* src="http://imageads\.googleadservices\.com/pagead/ads\?[^"]*" / ></a></td>\n\s*</tr>\n\s*<tr>\n\s*<td><div align="right"><a href="http://www\.google\.com/ads_by_google\.html" [^>]*>Ads by Google</a></div></td>\n\s*</tr>\n\s*</table>!!s;

    Plagger->context->log(debug => "Stripped Google AdSense for feeds") if $count;

    $body;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::StripRSSAd - Strip RSS Ads from feed content

=head1 SYNOPSIS

  - module: Filter::StripRSSAd

=head1 DESCRIPTION

This plugin strips RSS context based ads from feed content, like
Google AdSense or rssad.jp. It uses quick regular expression to strip
the images and map tags.

=head1 AUTHOR

Tatsuhiko Miyagawa, Masahiro Nagano

=head1 SEE ALSO

L<Plagger>

=cut
