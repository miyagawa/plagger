package Plagger::Plugin::Filter::ResolveRelativeLink;
use strict;
use base qw( Plagger::Plugin );

use HTML::ResolveLink;
use Text::Diff;

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

    my $base = $entry->permalink || $args->{feed}->link;
    unless ($base) {
        $context->log(warn => "No base link found");
        return;
    }

    my $resolver = HTML::ResolveLink->new(base => $base);
    my $html = $resolver->resolve($entry->body);

    if (my $count = $resolver->resolved_count) {
        $context->log(info => "Resolved $count link(s) in " . $entry->permalink);
        $entry->body($html);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::ResolveRelativeLink - Resolve relative links in feed content

=head1 SYNOPSIS

  - module: Filter::ResolveRelativeLink

=head1 DESCRIPTION

Some feeds contain relative URIs in their content in C<<
<content:encoded> >> or C<< <description> >> element. That's not a
valid thing to do, but because RSS and content module specification
doesn't clearly say about it, some feeds still do it.

This plugins tries to fix the relative links in feed content, using
entry's permalink as a base URL.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::ResolveLink>

=cut
