package Plagger::Feed;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( link url image description language author updated tags stash ));

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

sub title {
    my $self = shift;
    if (@_) {
        my $title = shift;
        utf8::decode($title) unless utf8::is_utf8($title);
        $self->{title} = $title;
    }
    $self->{title};
}

1;
