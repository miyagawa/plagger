package Plagger::Condition::Compound;
use strict;

sub new {
    my($class, @cond) = @_;
    bless {
        conditions => [ map Plagger::Condition->new($_), @cond ],
    }, $class;
}

sub dispatch {
    my($self, @args) = @_;

    my $bool = 1;
    for my $condition (@{ $self->{conditions} }) {
        $bool = 0 unless $condition->dispatch(@args); # AND mode
    }

    $bool;
}

1;
