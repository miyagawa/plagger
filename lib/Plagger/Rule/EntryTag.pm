package Plagger::Rule::EntryTag;
use strict;
use base qw( Plagger::Rule );

use Plagger::Operator;
use Plagger::Tag;

sub init {
    my $self = shift;

    unless (ref($self->{tag})) {
        $self->{tag} = [ Plagger::Tag->parse($self->{tag}) ];
    }

    $self->{op}   ||= 'AND';

    unless (Plagger::Operator->is_valid_op($self->{op})) {
        Plagger->context->error("Unsupported operator $self->{op}");
    }
}

sub id {
    my $self = shift;
    return "tag:" . join '+', @{$self->{tag}};
}

sub as_title {
    my $self = shift;
    return "tagged with " . join(" $self->{op} ", map "'$_'", @{$self->{tag}});
}

sub dispatch {
    my($self, $args) = @_;

    my $entry = $args->{entry}
        or Plagger->context->error("No entry object in this plugin phase");

    my @bool;
    for my $want (@{$self->{tag}}) {
        push @bool, $entry->has_tag($want);
    }

    Plagger::Operator->call($self->{op}, @bool);
}

1;
