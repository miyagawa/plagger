package Plagger::Plugin;
use strict;

use Plagger::Condition;
use Plagger::Condition::Compound;

sub new {
    my($class, $opt) = @_;
    my $self = bless {
        conf => $opt->{config} || {},
        condition => $opt->{condition},
        stash => {},
    }, $class;
    $self->init();
    $self;
}

sub init {
    my $self = shift;
    if (my $cond = $self->{condition}) {
        $cond = [ $cond ] if ref($cond) eq 'HASH';
        $self->{condition} = Plagger::Condition::Compound->new(@$cond);
    } else {
        $self->{condition} = Plagger::Condition->new({ module => 'Always' });
    }
}

sub conf      { $_[0]->{conf} }
sub condition { $_[0]->{condition} }

1;
