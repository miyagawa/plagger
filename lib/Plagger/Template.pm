package Plagger::Template;
use strict;
use base qw( Template );

use FindBin;
use File::Spec::Functions qw(catfile);

use Template::Provider::Encoding 0.04;
use Template::Stash::ForceUTF8;

sub new {
    my($class, $context, $plugin) = @_;

    my $path = $context->conf->{assets_path} || catfile($FindBin::Bin, "assets");
    my $paths = [ catfile($path, "plugins", $plugin->class_id),
                  catfile($path, "common") ];

    if ($plugin->conf->{assets_path}) {
        unshift @$paths, $plugin->conf->{assets_path};
    }

    return $class->SUPER::new({
        INCLUDE_PATH => $paths,
        LOAD_TEMPLATES => [
            Template::Provider::Encoding->new({ INCLUDE_PATH => $paths }),
        ],
        STASH => Template::Stash::ForceUTF8->new,
        PLUGIN_BASE => [ 'Plagger::TT' ],
    });
}

1;

__END__


=head1 NAME

Plagger::Template - Template Toolkit subclass for Plagger

=head1 SYNOPSIS

  From within a plagger plugin
  $self->templatize($file, $vars);

=head1 DESCRIPTION

A subclass of Template Toolkit that's used by the Plagger plugins.
As a plugin author, you really don't have to worry about this.  See the
documentation for Plagger::Pluggin's templatize method instead.

The plugin calls the custom new routine like so:

  Plagger::Template->new($plagger_context, $self);

Essentially this subclass uses this to know where the templates are
from the assests path.

It also does the right thing with encodings and utf8.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>, L<Template>, L<http://tt2.org/>

=cut
