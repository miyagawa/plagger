package Plagger::Plugin::Publish::iPhoto;

use strict;
use warnings;

use base qw( Plagger::Plugin );

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'plugin.init'  => \&initialize,
        'publish.feed' => \&publish_feed,
    );
}

sub initialize {
    my ( $self, $c ) = @_;

    unless ( exists $self->conf->{album} ) {
        $c->error("'album' config is missing");
    }

    $self->{has_macglue} = eval {
        require Mac::Glue;
        $self->{iphoto} = new Mac::Glue 'iPhoto';
        $self->{iphoto_album}
            = $self->{iphoto}->obj( album => $self->conf->{album} );
        1;
    };
}

sub publish_feed {
    my ( $self, $c, $args ) = @_;

    my $feed = $args->{feed};
    for my $entry ( $feed->entries ) {
        for my $enclosure ( $entry->enclosures ) {
            if ( $self->{has_macglue} ) {
                $c->log( info => "add via Mac::Glue" );

                # check if the album exists
                my $exists = $self->{iphoto}->exists( $self->{iphoto_album} );

                if ( $exists == 0 ) {
                    $c->log(
                        info => "Creating album " . $self->conf->{album} );
                    $self->{iphoto}
                        ->new_album( name => $self->conf->{album} );
                }

                # we import the file
                $c->log( info => "import " . $enclosure->filename );
                $self->{iphoto}->open( $enclosure->local_path );

                # we get the last added image
                my $last_roll = $self->{iphoto}->prop("last_rolls_album");
                my $select    = $self->{iphoto}->select($last_roll);

								# are we importing ?
                my $imp = $self->{iphoto}->prop("importing");
                sleep(2) if $imp;

                # we count
                my $count = $select->prop("photos")->count();
                for ( my $index = $count; $index > 0; $index-- ) {
                    my $photo = $select->obj( photo => 1 );
                    my $name = $photo->prop("image_filename")->get;
                    $c->log( info => "add $name to " . $self->conf->{album} );
                    $self->{iphoto}
                        ->add( $photo, to => $self->{iphoto_album} );
                }
            }
            else {
                $c->log( info => "add via applescript" );
                system( 'osascript', 'bin/import_to_iphoto.scpt',
                    $enclosure->local_path, $self->conf->{album} ) == 0
                    or $c->error(
                    error => 'Could not add ' . $enclosure->filename );
            }

        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::iPhoto - Store images in iPhoto

=head1 SYNOPSIS

  - module: Publish::iPhoto
		config:
	  	album: plagger

=head1 DESCRIPTION

store photos from enclosure to iPhoto. You need to create a glue for iphoto:

	gluemac /Application/iPhoto.app/

=head1 AUTHOR

Franck Cuny

=head1 SEE ALSO

L<Plagger>

=cut

