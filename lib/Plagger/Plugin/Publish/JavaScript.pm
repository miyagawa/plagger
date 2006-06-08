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

    my $file = $self->gen_filename($args->{feed}, $self->conf->{filename} || '%i.js');
    my $path = File::Spec->catfile($self->conf->{dir}, $file);
    $context->log(info => "writing output to $path");

    my $body = $self->templatize($context, $args->{feed});

    open my $out, ">:utf8", $path or $context->error("$path: $!");
    print $out $body;
    close $out;
}

my %formats = (
    'u' => sub { my $s = $_[0]->url;  $s =~ s!^https?://!!; $s },
    'l' => sub { my $s = $_[0]->link; $s =~ s!^https?://!!; $s },
    't' => sub { $_[0]->title },
    'i' => sub { $_[0]->id },
);

my $format_re = qr/%(u|l|t|i)/;

sub gen_filename {
    my($self, $feed, $file) = @_;

    $file =~ s{$format_re}{
        $self->safe_filename($formats{$1}->($feed))
    }egx;

    $file;
}

sub safe_filename {
    my($self, $path) = @_;
    $path =~ s![^\w\s]+!_!g;
    $path =~ s!\s+!_!g;
    $path;
}

sub templatize {
    my($self, $context, $feed) = @_;
    my $tt = $context->template();
    $tt->process('javascript.tt', {
        feed => $feed,
    }, \my $out) or $context->error($tt->error);
    $out;
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
