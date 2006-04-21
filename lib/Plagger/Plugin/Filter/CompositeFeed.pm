package Plagger::Plugin::Filter::CompositeFeed;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'smartfeed.init' => \&initialize,
        'smartfeed.feed' => \&feed,
        'smartfeed.finalize' => \&finalize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;

    $self->{feed} = Plagger::Feed->new;
    $self->{feed}->title( $self->conf->{title} || "All feeds" );
    $self->{feed}->link( $self->conf->{link} );
}

sub feed {
    my($self, $context, $args) = @_;

    my $entry = Plagger::Entry->new;
    $entry->title($args->{feed}->title);
    $entry->link($args->{feed}->link);
    $entry->body($args->{feed}->description);
    $entry->add_tag($_) for @{ $args->{feed}->tags };

    $self->{feed}->add_entry($entry);
}

sub finalize {
    my($self, $context, $args) = @_;
    $context->update->{feeds} = [ $self->{feed} ];
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::CompositeFeed - Multi feeds = Entries of one feed

=head1 SYNOPSIS

  - module: Filter::CompositeFeed

=head1 DESCRIPTION

This plugin composites all the feeds as entries of one feed. This is
kind of other way round to what Filter::BreaakEntriesToFeeds does, and
is considered as yet another hackish plugin to change the behavior of
Publish and Notify plugins.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::BreakEntriesToFeeds>

=cut
