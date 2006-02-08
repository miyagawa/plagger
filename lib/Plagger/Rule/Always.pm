package Plagger::Rule::Always;
use base qw( Plagger::Rule );

sub hooks    { Plagger->context->active_hooks }
sub dispatch { 1 }

1;
