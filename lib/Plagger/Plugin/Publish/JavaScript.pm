package Plagger::Plugin::Publish::JavaScript;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use Template::Plugin::JavaScript;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or Plagger->context->error("mkdir $dir: $!");
    }
}

sub feed {
    my($self, $context, $args) = @_;

    my $file = Plagger::Util::filename_for($args->{feed}, $self->conf->{filename} || '%i.js');
    my $path = File::Spec->catfile($self->conf->{dir}, $file);
    $context->log(info => "writing output to $path");

    my $body = $self->templatize('javascript.tt', { feed => $args->{feed} });

    open my $out, ">:utf8", $path or $context->error("$path: $!");
    print $out $body;
    close $out;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::JavaScript - publish links to entries as JavaScript

=head1 SYNOPSIS

  - module: Publish::JavaScript
    config:
      dir: /path/to/www/js
      filename: %t.js

=head1 DESCRIPTION

This plugin publishes links to feed entries as an HTML embedable
JavaScript file. The JS file contains document.write() calls, and can
be easily included in any HTML page using:

  <script src="/path/to/file.js"></script>

in any place, like Blog sidebar widgets.

The HTML emitted by the JavaScript code has exactly the same structure
with Movable Type's standard sidebar module, so you can easily style
using CSS.

=head1 CONFIG

=over 4

=item dir

Directory to save JS files in.

=item filename

Filename to be used to create JS files. It defaults to C<%i.js>, but
could be configured using the following formats like strftime:

=over 8

=item * %u url

=item * %l link

=item * %t title

=item * %i id

=back

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Publish::MTWidget>

=cut
