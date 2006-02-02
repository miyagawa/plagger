package Plagger::Feed;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( title link image description language webmaster tags stash ));

sub new {
    my($class, $feed) = @_;
    bless {
        title => $feed->{title},
        link  => $feed->{link},
        image => $feed->{image},
        description => $feed->{description},
        language  => $feed->{language},
        webmaster => $feed->{webmaster},
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

1;
