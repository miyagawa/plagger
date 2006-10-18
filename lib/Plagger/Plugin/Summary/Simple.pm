package Plagger::Plugin::Summary::Simple;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $text = $args->{text};
    $text = Plagger::Text->new_from_text($text) unless ref $text;

    if ($text->is_html) {
        # HTML: grab first block paragraph, or until first <br />
        local $HTML::Tagset::isBodyElement{div} = 0;
        my $html = $text->data;
        while ($html =~ s|^\s*<(\w*)\s*[^>]*>(.*?)</\1>|$2|gs) {
            if ($HTML::Tagset::isBodyElement{lc($1)}) {
                return "<$1>$2</$1>";
            }
        }

        if ($text->data =~ m!^(.*?)<br\s*/?>!s) {
            return $1;
        } else {
            return $text->data;
        }
    } else {
        # text: strip until the ending dots
        # TODO: make this 255 configurable?
        if ($text =~ /^(.+?(\x{3002}|\.\s))/ && length($1) <= 255) {
            (my $summary = $1) =~ s/\s*$//;
            return $summary;
        }

        if (length($text) > 255) {
            return substr($text, 0, 255) . "...";
        } else {
            return $text;
        }
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::Simple - Default summary generator

=head1 SYNOPSIS

  # this is not actually needed
  - module: Summary::Simple

=head1 DESCRIPTION

Summary::Simple is a core plugin that does simple generation of summary
using HTML snippet extraction algorithm. This plugin is autoloaded
from Plagger core and if you don't load any Summary plugins, or all of
your plugins declined to handle summary generation, Plagger fallbacks
to this plugin.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
