package Plagger::Plugin::Subscription::Bookmarks::Mozilla;
use strict;
use base qw( Plagger::Plugin::Subscription::XPath );

use URI::file;

sub load {
    my($self, $context) = @_;

    $self->conf->{url} = URI::file->new($self->conf->{path});
    $self->SUPER::load($context);
}
    
1;
