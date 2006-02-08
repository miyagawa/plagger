package Plagger::Rules;
use strict;
use Plagger::Operator;

sub new {
    my($class, $op, @rules) = @_;
    Plagger::Operator->is_valid_op(uc($op))
        or Plagger->context->error("operator $op not supported");

    bless {
        op => uc($op),
        rules => [ map Plagger::Rule->new($_), @rules ],
    }, $class;
}

sub dispatch {
    my($self, $hook, $args) = @_;

    my @bool;
    for my $rule (@{ $self->{rules} }) {
        next unless $rule->can_run($hook);
        push @bool, ($rule->dispatch($args) ? 1 : 0);
    }

    # can't find rules for this phase: execute it
    return 1 unless @bool;

    Plagger::Operator->call($self->{op}, @bool);
}

1;
