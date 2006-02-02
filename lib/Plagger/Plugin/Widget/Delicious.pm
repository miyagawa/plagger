package Plagger::Plugin::Widget::Delicious;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'filter.content' => \&add,
    );
}

sub add {
    my($self, $context, $entry, $content) = @_;
    my $widget = Plagger::Widget::Delicious->new(
        username => $self->conf->{username},
        entry => $entry,
    );
    $entry->add_widget($widget);
}

package Plagger::Widget::Delicious;

use Encode;
use HTML::Entities;
use URI;

sub new {
    my($class, %opt) = @_;
    bless \%opt, $class;
}

sub html {
    my $self = shift;
    my $uri = URI->new('http://del.icio.us/' . $self->{username});
    $uri->query_form(
        v => 3,
        url => $self->{entry}->link,
        title => encode('utf-8', $self->{entry}->title),
    );

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url">Post to del.icio.us</a>);
}

1;
