package Plagger::Plugin::Filter::BreakEntriesToFeeds;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&entry,
        'update.fixup' => \&fixup,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed}->clone;
    $feed->clear_entries;
    $feed->add_entry($args->{entry});
    $feed->title($args->{entry}->title);

    push @{$self->{feeds}}, $feed;
}

sub fixup {
    my($self, $context, $args) = @_;

    $context->update->{feeds} = $self->{feeds}
        if $self->{feeds};
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

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
