package Plagger::Plugin::Filter::TTP;
use strict;
use base qw( Plagger::Plugin::Filter::Base );

use URI::Find;
use URI::http;

sub filter {
    my($self, $body) = @_;

    local @URI::ttp::ISA = qw(URI::http);

    my $count = 0;
    my $finder = URI::Find->new(sub {
        my ($uri, $orig_uri) = @_;
        if ($uri->scheme eq 'ttp') {
            $count++;
            return qq{<a href="h$orig_uri">$orig_uri</a>};
        } else {
            return $orig_uri;
        }
    });

    $finder->find(\$body);
    ($count, $body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::TTP - Replace ttp:// with http://

=head1 SYNOPSIS

  - module: Filter::TTP

=head1 DESCRIPTION

This plugin replaces C<ttp://> with C<http://>. C<ttp://> is a widely
adopted way of linking an URL without leaking a referer.

=head1 CONFIG

=over 4

=item text_only

When set to 1, uses HTML::Parser to avoid replacing C<ttp://> inside
HTML attributes. Defaults to 0.

=back

=head1 AUTHOR

Matsuno Tokuhiro

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
