package Plagger::UserAgent;
use strict;
use base qw( LWP::UserAgent );

use URI::Fetch;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->agent("Plagger/$Plagger::VERSION (http://plagger.bulknews.net/)");
    $self->timeout(15); # xxx to be config
    $self;
}

sub fetch {
    my($self, $url, $plugin) = @_;

    URI::Fetch->fetch($url,
        UserAgent => $self,
        $plugin ? (Cache => $plugin->cache) : (),
        ForceResponse => 1,
    );
}

# xxx
*URI::Fetch::Response::is_success = sub { $_[0]->http_response->is_success };

1;

