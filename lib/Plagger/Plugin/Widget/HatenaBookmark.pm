package Plagger::Plugin::Widget::HatenaBookmark;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use HTML::Entities;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'filter.content' => \&add,
    );
}

sub add {
    my($self, $context, $args) = @_;
    $args->{entry}->add_widget($self);
}

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new('http://b.hatena.ne.jp/append');
    $uri->query($entry->permalink);

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url"><img src="http://b.hatena.ne.jp/images/append.gif" alt="Post to Hatena Bookmark" style="border:0;vertical-align:middle" /></a>);
}

1;
