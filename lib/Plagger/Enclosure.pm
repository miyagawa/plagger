package Plagger::Enclosure;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( length type local_path ));

use URI;

sub url {
    my $self = shift;
    if (@_) {
        $self->{url} = URI->new($_[0]);
    }
    $self->{url};
}

sub auto_set_type {
    my($self, $type) = @_;

    if (defined $type) {
        return $self->type($type);
    }

    require MIME::Types;

    # no type is set in XML ... set via URL extension
    my $ext  = ( $self->url->path =~ /\.(\w+)/ )[0];
    my $mime = MIME::Types->new->mimeTypeOf($ext) or return;

    $self->type($mime->type);
}

sub media_type {
    my $self = shift;
    ( split '/', $self->type )[0] || 'unknown';
}

sub sub_type {
    my $self = shift;
    ( split '/', $self->type )[1] || 'unknown';
}

sub filename {
    my $self = shift;
    if (@_) {
        $self->{filename} = shift;
    }
    $self->{filename} || (split '/', $self->url->path)[-1];
}

1;

