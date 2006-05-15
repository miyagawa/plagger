package Plagger::Enclosure;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( length type local_path is_inline ));

use Plagger::Util;
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

    # set MIME type via URL extension
    my $mime = Plagger::Util::mime_type_of($self->url);
    $self->type($mime->type) if $mime;
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

