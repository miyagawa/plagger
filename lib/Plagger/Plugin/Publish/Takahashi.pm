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

    my $file  = $args->{feed}->id . '.xul';
    my $path  = File::Spec->catfile($self->conf->{dir}, $file);
    $context->log(info => "writing output to $path");

    my $body = $context->templatize($self, 'takahashi.tt', $args);
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
