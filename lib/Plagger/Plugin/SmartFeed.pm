package Plagger::Plugin::SmartFeed;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Tag;

sub rule_hook { 'smartfeed.entry' }

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'smartfeed.init'  => $self->can('feed_init'),
        'smartfeed.entry' => $self->can('feed_entry'),
        'smartfeed.finalize' => $self->can('feed_finalize'),
    );
}

sub feed_init {
    my($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('smartfeed');
    $feed->id( $self->conf->{id} || ('smartfeed:' . $self->rule->id) );
    $feed->title( $self->conf->{title} || "Entries " . $self->rule->as_title );
    $feed->link( $self->conf->{link} );

    $self->{feed} = $feed;
}

sub feed_entry {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry}->clone;
    my $feed  = $args->{feed}->clone;
       $feed->clear_entries;
    $entry->source($feed); # xxx is it only valid for SmartFeed?
    $entry->icon($feed->image) if !$entry->icon && $feed->image;

    $self->{feed}->add_entry($entry);
}

sub feed_finalize {
    my($self, $context, $args) = @_;
    $context->update->add($self->{feed}) if $self->{feed}->count;
}

1;
