package Plagger::Entry;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( title author tags date link id summary body rate  icon meta));

use Digest::MD5;
use DateTime::Format::Mail;
use Storable;
use Plagger::Util;

sub new {
    my $class = shift;
    bless {
        rate    => 0,
        widgets => [],
        tags    => [],
        meta    => {},
    }, $class;
}

sub add_rate {
    my($self, $rate) = @_;
    $self->rate( $self->rate + $rate );
}

sub text {
    my $self = shift;
    join "\n", $self->link, $self->title, $self->body;
}

sub add_widget {
    my($self, $widget) = @_;
    push @{ $self->{widgets} }, $widget;
}

sub widgets {
    my $self = shift;
    wantarray ? @{ $self->{widgets} } : $self->{widgets};
}

sub permalink {
    my $self = shift;
    $self->{permalink} = shift if @_;
    $self->{permalink} || $self->link;
}

sub id_safe {
    my $self = shift;
    my $id   = $self->id || $self->link;
    $id =~ m!^https?://! ? Digest::MD5::md5_hex($id) : $id;
}

sub title_text {
    my $self = shift;
    Plagger::Util::strip_html($self->title);
}

sub body_text {
    my $self = shift;
    Plagger::Util::strip_html($self->body);
}

1;

