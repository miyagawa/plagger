package Plagger::Cache::Null;
use strict;

sub new {
    bless {}, shift;
}

sub get {
    my($self, $key) = @_;
    $self->{$key};
}

sub set {
    my($self, $key, $value, $expiry) = @_;
    $self->{$key} = $value;
}

sub remove {
    my($self, $key) = @_;
    delete $self->{$key};
}

1;

