package Plagger::Rule::Deduped::Base;
use strict;

sub new {
    my($class, $rule) = @_;

    my $self = bless {
        compare_body => $rule->{compare_body} || 0,
    }, $class;
    $self->init($rule);

    $self;
}

sub init { }

sub id_for {
    my($self, $entry) = @_;

    if ($entry->date) {
        return join ":", $entry->permalink, $entry->date;
    } else {
        return $entry->permalink;
    }
}

sub is_new {
    my($self, $entry) = @_;

    my $exists = $self->find_entry( $self->id_for($entry) ) or return 1;

    if ($self->{compare_body}) {
        return $exists ne $entry->digest;
    } else {
        return 0;
    }
}

sub add {
    my($self, $entry) = @_;
    $self->create_entry( $self->id_for($entry), $entry->digest );
}

sub find_entry   { }
sub create_entry { }

1;
