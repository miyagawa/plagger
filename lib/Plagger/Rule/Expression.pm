package Plagger::Rule::Expression;
use strict;
use base qw( Plagger::Rule );

sub dispatch {
    my($self, $feed) = @_;
    my $status = eval $self->{expression};
    if ($@) {
        Plagger->context->log(error => "Expression error: $@ with '$self->{expression}'");
    }
    $status;
}

1;
