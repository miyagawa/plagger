package Plagger::Text;
use strict;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( type data ));

use overload 
    q("") => sub {  $_[0]->data },
    # XXX - if you evaluate Plagger::Text in boolean mode w/o defining a
    # bool override, you get some nasty problems, especially if it's
    # called from within the stringification method.
    # XXX - not sure if this below is the correct to way to make sure 
    # it's an object?
    bool     => sub { defined $_[0] && ref $_[0] },
    fallback => 1
;

use HTML::Tagset;
use Plagger::Util;

sub new {
    my($class, %param) = @_;
    bless {%param}, $class;
}

sub new_from_text {
    my($class, $text) = @_;

    return unless defined $text;
    utf8::decode($text) unless utf8::is_utf8($text);

    my @tags = $text =~ m!<(\w+)\s?/?>!g;
    my @unknown = grep !$HTML::Tagset::isKnown{$_}, @tags;
    my $type;
    if (@unknown > @tags / 2) {
        $type = 'text';
    } elsif (@tags || $text =~ m!&(?:amp|gt|lt|quot);!) {
        $type = 'html';
    } else {
        $type = 'text';
    }

    bless { type => $type, data => $text }, $class;
}

sub is_html {
    my $self = shift;
    $self->type eq 'html';
}

sub is_text {
    my $self = shift;
    $self->type eq 'text';
}

sub html {
    my $self = shift;
    if ($self->is_html) {
        return $self->data;
    } else {
        Plagger::Util::encode_xml($self->data);
    }
}

sub plaintext {
    my $self = shift;
    if ($self->is_html) {
        return Plagger::Util::strip_html($self->data);
    } else {
        return $self->data;
    }
}

sub unicode { $_[0]->data }
sub utf8    { Encode::encode_utf8($_[0]->data) }
sub encode  { Encode::encode($_[1], $_[0]->data) }

sub serialize {
    my $self = shift;
    $self->data;
}

1;
