package Plagger::Entry;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( title author tags date link feed_link id summary body rate icon meta source ));

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
        enclosures => [],
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
    my $id   = $self->id || $self->permalink;

    # entry without id or permalink. Try entry's date or title
    unless ($id) {
        $id  = $self->feed_link;
        $id .= $self->date ? $self->date->epoch : $self->title;
    }

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

sub add_enclosure {
    my($self, $enclosure) = @_;

    # don't add enclosure with the same URL again and again
    unless ($enclosure->url && grep { $_->url && $_->url eq $enclosure->url } $self->enclosures) {
        push @{ $self->{enclosures} }, $enclosure;
    }
}

sub enclosure {
    my $self = shift;
    wantarray ? @{$self->{enclosures}} : $self->{enclosures}->[0];
}

sub enclosures {
    my $self = shift;
    wantarray ? @{$self->{enclosures}} : $self->{enclosures};
}

sub has_enclosure {
    my $self = shift;
    scalar @{$self->{enclosures}} > 0;
}

sub digest {
    my $self = shift;
    Digest::MD5::md5_hex($self->title . ($self->body || ''));
}

1;

