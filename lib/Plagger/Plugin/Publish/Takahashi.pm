package Plagger::Plugin::Publish::Takahashi;
use strict;
use base qw( Plagger::Plugin );

use File::Copy;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    );

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }
}

sub feed {
    my($self, $context, $args) = @_;

    my $file  = $args->{feed}->id_safe . '.xul';
    my $path  = File::Spec->catfile($self->conf->{dir}, $file);
    $context->log(info => "writing output to $path");

    my $body = $self->templatize('takahashi.tt', $args);
    open my $out, ">:utf8", $path or $context->error("$path: $!");
    print $out $body;
    close $out;
}

sub finalize {
    my($self, $context, $args) = @_;

    for my $file (qw( takahashi.js takahashi.css )) {
        my $js_path = File::Spec->catfile($self->conf->{dir}, $file);
        copy( File::Spec->catfile($self->assets_dir, $file), $js_path );
    }
}

1;

=head1 NAME

Plagger::Plugin::Publish::Takahashi - produce takahashi output

=head1 SYNOPSIS

  - module: Publish::Takahashi
    config:
      dir: /home/miyagawa/takahashi

=head1 DESCRIPTION

This module creates a Takahashi style presentation in .xul for
each feed.

The one configuration option is the directory you want the
presentation to be created in.  A $feedid.xul file will be
created for each feed, and the two support takahashi
javascript and css support files will be copied into
the directory.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>,
L<http://www.bright-green.com/blog/2005_12_15/a_cute_mozilla_xul_app.html>

=cut

