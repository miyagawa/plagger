package Plagger::Plugin::Subscription::Planet;
use strict;
use base qw( Plagger::Plugin::Subscription::Config );

use Encode;
use URI::Escape;

sub load {
    my($self, $context) = @_;

    my $keyword = $self->conf->{keyword};
       $keyword = [ $keyword ] unless ref $keyword;

    my $lang = $self->conf->{lang} || 'default';
    $lang = [ $lang ] unless ref $lang;

    $self->load_assets(
        File::Find::Rule->file->name([ map "$_.yaml", @$lang ]),
        sub {
            my($file) = @_;
            my $data = YAML::LoadFile($file);
            push @{ $self->{engines} }, @{ $data->{engines} };
        },
    );

    for my $kw (@$keyword) {
	for my $site (@{ $self->{engines} }) {
	    my $site_url = $site; # copy

            # use eval ... die to skip if there's no url/keyword
            eval {
                $site_url =~ s{{([\w\-\:]+)}}{
                    my($key, $encoding) = split /:/, $1;

                    my $data = $self->conf->{$key} or die "$key is not there";
                    if ($encoding && $encoding ne 'utf-8') {
                        Encode::from_to($data, "utf-8" => $encoding);
                    }

                    my $chunk = URI::Escape::uri_escape($data);
                    $chunk =~ s/%20/+/g; # hack
                    $chunk;
                }eg;
                push @{$self->conf->{feed}}, { url => $site_url }
            };
	}
    }

    $self->SUPER::load($context);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::Planet - Ego search subscription

=head1 SYNOPSIS

  - module: Subscription::Planet
    config:
      keyword: Plagger
      lang: en

=head1 DESCRIPTION

This plugin gives a handy way to subscribe to dozens of feed / web
search engine results by just supplying keywords.

=head1 CONFIG

=over 4

=item keyword

The keyword to use as a query in web search engines. Required.

=item lang

Language code to either 1) specify list of search engines or 2) pass
to search query.  Optional.

For example, technorati.jp will be added if you use I<ja>, while
technorati.com will be if you use I<en>. Default is to search
everything.

=back

=head1 EXAMPLES

  # search "Plagger" on default engines
  - module: Subscription::Planet
    config:
      keyword: Plagger

  # search "Pokemon" on Japanese search engines
  - module: Subscription::Planet
    config:
      keyword: Pokemon
      lang: ja

  # search "Plagger" and pages linking to "http://plagger.org/"
  - module: Subscription::Planet
    config:
      keyword: Plagger
      url: http://plagger.org/

=head1 AUTHOR

youpy

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
