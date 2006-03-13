package Plagger::Plugin::Filter::HatenaFormat;
use strict;
use warnings;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use Text::Hatena;

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
    my $parser = Text::Hatena->new(%{$self->conf});
    $parser->parse($entry->body);
    $entry->body($parser->html);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaFormat - Text formatting filter with Hatena Style

=head1 SYNOPSIS

  - module: Filter::HatenaFormat
    config:
      ilevel: 1
      sectionanchor: '@'

=head1 DESCRIPTION

This filter allows you to format the content with Hatena Style. You
can get html string from simple text with syntax like Wiki.

=head1 CONFIG

Any configurations will be passed to the constructor of
Text::Hatena. See L<Text::Hatena> in detail.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>, L<Text::Hatena>

=cut
