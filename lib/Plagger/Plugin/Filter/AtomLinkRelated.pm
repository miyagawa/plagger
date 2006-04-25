package Plagger::Plugin::Filter::AtomLinkRelated;
use strict;
use base qw( Plagger::Plugin );

use List::Util qw(first);

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.entry.fixup' => \&fixup,
    );
}

# Note: Bloglines doesn't return link rel="related" value in its API and we're doomed

sub fixup {
    my($self, $context, $args) = @_;

    # Use Atom's link rel="related"
    if (my $orig_link = $args->{orig_feed}->format eq 'Atom') {
        my $rel = first { $_->rel eq 'related' } $args->{orig_entry}->{entry}->link; # XXX uses XML::Feed internal
        if ($rel) {
            $args->{entry}->link($rel->href);
            $context->log(info => "Link rewritten to " . $rel->href);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::AtomLinkRelated - Use link rel="related" as entry link

=head1 SYNOPSIS

  - module: Filter::AtomLinkRelated

=head1 DESCRIPTION

This plugin looks for Atom link elements with C<< rel="related" >>
relationship set. This way you can use original link defined in Social
Bookmark atom feeds like L<http://b.hatena.ne.jp/miyagawa/atomfeed>.

Note that this plugin only works with Plagger's own aggregator like
I<Aggregator::Simple> plugin, since Bloglines API doesn't return
related links in its response data.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
