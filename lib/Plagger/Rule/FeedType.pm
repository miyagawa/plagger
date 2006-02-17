package Plagger::Rule::FeedType;
use strict;
use base qw( Plagger::Rule );

use Plagger::Operator;

sub init {
    my $self = shift;

    if (my $type = $self->{type}) {
        $type = [ $type ] if ref($type) ne 'ARRAY';
	$self->{type} = $type;
    } else {
	Plagger->context->error("Can't parse type");
    }

    $self->{op} ||= 'OR';
    unless (Plagger::Operator->is_valid_op($self->{op})) {
        Plagger->context->error("Unsupported operator $self->{op}");
    }
}

sub dispatch {
    my($self, $args) = @_;

    my $feed = $args->{feed}
        or Plagger->context->error("No feed object in this plugin phase");

    my @bool;
    for my $want (@{$self->{type}}) {
        push @bool, ($feed->type eq $want);
    }

    Plagger::Operator->call($self->{op}, @bool);
}

1;
