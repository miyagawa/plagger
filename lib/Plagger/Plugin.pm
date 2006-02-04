package Plagger::Plugin;
use strict;

use Plagger::Rule;
use Plagger::Rule::Compound;

sub new {
    my($class, $opt) = @_;
    my $self = bless {
        conf => $opt->{config} || {},
        rule => $opt->{rule},
        stash => {},
    }, $class;
    $self->init();
    $self;
}

sub init {
    my $self = shift;
    if (my $rule = $self->{rule}) {
        $rule = [ $rule ] if ref($rule) eq 'HASH';
        $self->{rule} = Plagger::Rule::Compound->new(@$rule);
    } else {
        $self->{rule} = Plagger::Rule->new({ module => 'Always' });
    }
}

sub conf { $_[0]->{conf} }
sub rule { $_[0]->{rule} }

1;
