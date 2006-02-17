package Plagger::Plugin;
use strict;

use Plagger::Rule;
use Plagger::Rules;

sub new {
    my($class, $opt) = @_;
    my $self = bless {
        conf => $opt->{config} || {},
        rule => $opt->{rule},
        rule_op => $opt->{rule_op} || 'AND',
        stash => {},
    }, $class;
    $self->init();
    $self;
}

sub init {
    my $self = shift;
    if (my $rule = $self->{rule}) {
        $rule = [ $rule ] if ref($rule) eq 'HASH';
        my $op = $self->{rule_op};
        $self->{rule} = Plagger::Rules->new($op, @$rule);
    } else {
        $self->{rule} = Plagger::Rule->new({ module => 'Always' });
    }
}

sub conf { $_[0]->{conf} }
sub rule { $_[0]->{rule} }

sub rule_hook { '' }

sub dispatch_rule_on {
    my($self, $hook) = @_;
    $self->rule_hook eq $hook;
}

1;
