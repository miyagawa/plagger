package Plagger::Tag;
use strict;

use Text::Tags::Parser;

sub parse {
    my($class, $string) = @_;
    Text::Tags::Parser->new->parse_tags($string);
}

1;
