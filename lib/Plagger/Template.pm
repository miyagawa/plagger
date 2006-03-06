package Plagger::Template;
use strict;
use base qw( Template );

use FindBin;
use File::Spec::Functions qw(catfile);

use Template::Provider::Encoding 0.04;
use Template::Stash::ForceUTF8;

sub new {
    my($class, $context, $plugin_class_id) = @_;

    my $path = $context->conf->{assets_path} || catfile($FindBin::Bin, "assets");
    my $paths = [ catfile($path, "plugins", $plugin_class_id),
                  catfile($path, "common") ];

    return $class->SUPER::new({
        INCLUDE_PATH => $paths,
        LOAD_TEMPLATES => [
            Template::Provider::Encoding->new({ INCLUDE_PATH => $paths }),
        ],
        STASH => Template::Stash::ForceUTF8->new,
    });
}

1;

