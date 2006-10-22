package Plagger::Plugin::Filter::Markdown;
use strict;
use warnings;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use Text::Markdown 'markdown';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    my $cfg = $self->conf;
    my $entry = $args->{entry};
    my $html = markdown($entry->body, {
        empty_element_suffix => $cfg->{empty_element_suffix} || ' />',
        tab_width => $cfg->{tab_width} || '4',
    } );
    $entry->body($html);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Markdown - Text formatting filter with Markdown

=head1 SYNOPSIS

  - module: Filter::Markdown
    config:
      empty_element_suffix: ' />'
      tab_width: '4'

=head1 DESCRIPTION

This filter allows you to format the content with Markdown. You
can get html string from simple text with syntax like Wiki.

=head1 CONFIG

Any configurations will be passed to the constructor of
Text::Markdown. See L<Text::Markdown> in detail.

=head1 AUTHOR

Nobuhito Sato

=head1 SEE ALSO

L<Plagger>, L<Text::Markdown>

=cut
