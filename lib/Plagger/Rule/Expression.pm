package Plagger::Rule::Expression;
use strict;
use base qw( Plagger::Rule );

sub hooks {
    my $self = shift;
    $self->{hooks} || Plagger->context->active_hooks;
}

sub dispatch {
    my($self, $args) = @_;
    my $status = eval $self->{expression};
    if ($@) {
        Plagger->context->log(error => "Expression error: $@ with '$self->{expression}'");
    }
    $status;
}

1;
