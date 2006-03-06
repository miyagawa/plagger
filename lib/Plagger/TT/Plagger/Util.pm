package Plagger::TT::Plagger::Util;
use strict;
use base qw( Template::Plugin );

our $AUTOLOAD;
use Carp;
use Plagger::Util;

sub new {
    bless {}, shift;
}

sub AUTOLOAD {
    no strict 'refs';
    my $self = shift;
    (my $func = $AUTOLOAD) =~ s/^.*:://;
    if (defined &{"Plagger::Util::$func"}) {
        my $ref = \&{"Plagger::Util::$func"};
        return &$ref(@_);
    } else {
        Carp::croak("$func not found in Plagger::Util");
    }
}

1;
