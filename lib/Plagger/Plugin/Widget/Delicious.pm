package Plagger::Plugin::Widget::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use HTML::Entities;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry.fixup' => \&add,
    );
}

sub add {
    my($self, $context, $args) = @_;
    $args->{entry}->add_widget($self);
}

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new('http://del.icio.us/' . $self->conf->{username});
    $uri->query_form(
        v => 3,
        url => $entry->permalink,
        title => encode('utf-8', $entry->title),
    );

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url"><img src="http://del.icio.us/static/img/delicious.small.gif" alt="del.icio.us it!" style="border:0;vertical-align:middle" /></a>);
}

1;
