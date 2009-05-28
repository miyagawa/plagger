package Plagger::Location;
use strict;
use warnings;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( address ));

# XXX add datum here?
# For now latitude/longitude should be in WGS84

sub latitude {
    my $self = shift;
    if (@_) {
        $self->{latitude} = shift() + 0; # numify
    }
    $self->{latitude};
}

sub longitude {
    my $self = shift;
    if (@_) {
        $self->{longitude} = shift() + 0; # numify
    }
    $self->{longitude};
}

sub altitude {
    my $self = shift;
    if (@_) {
        $self->{altitude} = shift() + 0; # numify
    }
    $self->{altitude};
}

1;

