package Plagger::Template;
use strict;
use base qw( Template );

use FindBin;
use File::Spec;

use Template::Provider::Encoding 0.04;
use Template::Stash::ForceUTF8;

sub new {
    my($class, $context, $plugin_class_id) = @_;

    my $path = $context->conf->{assets_path} || File::Spec->catfile($FindBin::Bin, "assets");
    my $paths = [ "$path/plugins/$plugin_class_id" ];

    return $class->SUPER::new({
        INCLUDE_PATH => $paths,
        LOAD_TEMPLATES => [
            Template::Provider::Encoding->new({ INCLUDE_PATH => $paths }),
        ],
        STASH => Template::Stash::ForceUTF8->new,
    });
}

1;

