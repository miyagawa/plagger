package Plagger::Plugin::Publish::Spotlight;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    for my $entry ($args->{feed}->entries) {
	my $file = $self->gen_filename($entry);
	my $path = File::Spec->catfile($dir, $file);
	$context->log(info => "writing output to $path");

	my $body = $self->templatize($context, $entry);

	open my $out, ">:utf8", $path or $context->error("$path: $!");
	print $out $body;
	close $out;
    }
}

my %formats = (
    'l' => sub { my $s = $_[0]->link; $s =~ s!^https?://!!; $s },
    't' => sub { $_[0]->title },
    'i' => sub { $_[0]->id },
);

my $format_re = qr/%(l|t|i)/;

sub gen_filename {
    my($self, $entry) = @_;

    my $file = $self->conf->{filename};
    $file =~ s{$format_re}{
        $self->safe_filename($formats{$1}->($entry))
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
    my($self, $context, $entry) = @_;
    my $tt = $context->template();
    $tt->process('spotlight.tt', {
        entry => $entry,
    }, \my $out) or $context->error($tt->error);
    $out;
}

1;
