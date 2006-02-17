package Plagger::Entry;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( title author tags date link id summary body rate  meta));

use DateTime::Format::Mail;
use Storable;

sub new {
    my $class = shift;
    bless {
        rate    => 0,
        widgets => [],
        tags    => [],
        meta    => {},
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

sub has_tag {
    my($self, $want_tag) = @_;
    for my $tag (@{$self->tags}) {
        return 1 if $tag eq $want_tag;
    }
    return 0;
}

sub permalink {
    my $self = shift;
    $self->{permalink} = shift if @_;
    $self->{permalink} || $self->link;
}

sub clone {
    my $self = shift;
    my $clone = Storable::dclone($self);
    $clone;
}

1;

