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
    $body =~ s!<br clear="all" /><a href="http://rss\.rssad\.jp/rss/ad/.*?" target="_blank".*?><img .*? src="http://rss\.rssad\.jp/rss/img/.*?" border="0"/></a><br/>!!;

    # Google AdSense for Feeds
    $body =~ s!<p><map name="google_ad_map_\d+\-\d+"><area.*?></map><img usemap="#google_ad_map_\d+-\d+" border="0" src="http://imageads\.googleadservices\.com/pagead/ads\?.*?" /></p>!!;

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
