package Plagger::Rule::Compound;
use strict;

sub new {
    my($class, @rules) = @_;
    bless {
        rules => [ map Plagger::Rule->new($_), @rules ],
    }, $class;
}

sub dispatch {
    my($self, @args) = @_;

    my $bool = 1;
    for my $rule (@{ $self->{rules} }) {
        $bool = 0 unless $rule->dispatch(@args); # AND mode
    }

    $bool;
}

1;
