package Plagger::Feed;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( title link url image description language author updated tags stash ));

sub new {
    my $class = shift;
    bless {
        stash => {},
        tags  => [],
        entries => [],
    }, $class;
}

sub add_entry {
    my($self, $entry) = @_;
    push @{ $self->{entries} }, $entry;
}

sub entries {
    my $self = shift;
    wantarray ? @{ $self->{entries} } : $self->{entries};
}

sub count {
    my $self = shift;
    scalar @{ $self->{entries} };
}

1;
