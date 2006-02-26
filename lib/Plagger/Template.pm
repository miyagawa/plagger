package Plagger::Template;
use strict;
use base qw( Template );

use FindBin;
use File::Spec;

use Template::Provider::Encoding 0.04;
use Template::Stash::ForceUTF8;

sub new {
    my($class, $context) = @_;

    my $path = $context->conf->{template_path} || File::Spec->catfile($FindBin::Bin, "templates");
    my $paths = [ $path, "$path/plugins" ];

    return $class->SUPER::new({
        INCLUDE_PATH => $paths,
        LOAD_TEMPLATES => [
            Template::Provider::Encoding->new({ INCLUDE_PATH => $paths }),
        ],
        STASH => Template::Stash::ForceUTF8->new,
    });
}

1;

