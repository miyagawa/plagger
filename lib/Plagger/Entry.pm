package Plagger::Entry;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( title author tags date link id summary body rate ));

use DateTime::Format::Mail;

sub new {
    my $class = shift;
    bless {
        rate   => 0,
        widgets => [],
    }, $class;
}

sub add_rate {
    my($self, $rate) = @_;
    $self->rate( $self->rate + $rate );
}

sub text {
    my $self = shift;
    join "\n", $self->link, $self->title, $self->body;
}

sub add_widget {
    my($self, $widget) = @_;
    push @{ $self->{widgets} }, $widget;
}

sub widgets {
    my $self = shift;
    wantarray ? @{ $self->{widgets} } : $self->{widgets};
}

1;

