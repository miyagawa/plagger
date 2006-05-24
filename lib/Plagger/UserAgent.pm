package Plagger::UserAgent;
use strict;
use base qw( LWP::UserAgent );

use Plagger::Cookies;
use URI::Fetch 0.06;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->agent("Plagger/$Plagger::VERSION (http://plagger.bulknews.net/)");
    $self->timeout(15); # xxx to be config

    my $conf = Plagger->context->conf->{user_agent};
    if ($conf->{cookies}) {
        $self->cookie_jar( Plagger::Cookies->create($conf->{cookies}) );
    }

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

1;

