package Plagger::Plugin;
use strict;

sub new {
    my($class, $opt) = @_;
    bless { conf => $opt->{config}, stash => {} }, $class;
}

sub conf  { $_[0]->{conf} }

1;
