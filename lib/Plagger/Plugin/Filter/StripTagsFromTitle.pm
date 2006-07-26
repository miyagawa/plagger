package Plagger::Plugin::Filter::StripTagsFromTitle;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    if (defined $args->{entry}->title) {
        $args->{entry}->title( Plagger::Util::strip_html($args->{entry}->title) );
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::StripTagsFromTitle - Strip tags from entry title

=head1 SYNOPSIS

  - module: Filter::StripTagsFromTitle

=head1 DESCRIPTION

This plugin filters entries to remove HTML tags from its title. Some
feeds like blog search engine's result feeds contain HTML tags e.g.:

  <title>&lt;b&gt;Plagger&lt;/b&gt; rocks</title>

But with RSS spec, there's no way to declare if it's a markup or an
escaped text, while Atom 1.0 has by using I<title@type>
attribute. This plugin normalizes those titles by simply stripping
HTML tags from them.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://feedvalidator.org/docs/warning/ContainsHTML.html>

=cut
