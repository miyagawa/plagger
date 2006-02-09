package Plagger::Plugin::Publish::JavaScript;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use Template::Plugin::JavaScript;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.add_feed' => \&add_feed,
    );
}

sub add_feed {
    my($self, $context, $args) = @_;

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    my $file = $self->gen_filename($args->{feed});
    my $path = File::Spec->catfile($dir, $file);
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
    my($self, $feed) = @_;

    my $file = $self->conf->{filename};
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
