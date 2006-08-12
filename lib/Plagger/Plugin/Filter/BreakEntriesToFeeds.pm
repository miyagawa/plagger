package Plagger::Plugin::Filter::BreakEntriesToFeeds;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&break,
    );
}

sub break {
    my($self, $context, $args) = @_;

    for my $entry ($args->{feed}->entries) {
        my $feed = $args->{feed}->clone;
        $feed->clear_entries;
        $feed->add_entry($entry);
        $feed->title($entry->title)
            if $self->conf->{use_entry_title};
        $context->update->add($feed);
    }

    $context->update->delete_feed($args->{feed});
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::BreakEntriesToFeeds - 1 entry = 1 feed

=head1 SYNOPSIS

  - module: Filter::BreakEntriesToFeeds

=head1 DESCRIPTION

This plugin breaks all the updated entries into a single feed. This is
a bit hackish plugin but allows things like sending a single mail
containing single entry, rather than a feed containing multiple
entries, with Publish::Gmail plugin.

=head1 CONFIG

=over 4

=item use_entry_title

Use entry's title as a newly genrated feed title. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
