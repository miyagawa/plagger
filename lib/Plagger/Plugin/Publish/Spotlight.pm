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
	my $file = $entry->id . '.webbookmark';
	my $path = File::Spec->catfile($dir, $file);
	$context->log(info => "writing output to $path");

	my $body = $self->templatize($context, $entry);

	open my $out, ">:utf8", $path or $context->error("$path: $!");
	print $out $body;
	close $out;
    }
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

__END__

=head1 NAME

Plagger::Plugin::Publish::Spotlight - Publish Webbookmark files for Spotlight

=head1 SYNOPSIS

  - module: Publish::Spotlight
    config:
      dir: /Users/youpy/Library/Caches/Metadata/Plagger/

=head1 DESCRIPTION

This plugin creates webbookmark files and make feed updates searchable
by Mac ODX Spotlight.

=head1 SCREENSHOT

L<http://subtech.g.hatena.ne.jp/youpy/20060223/p1>

=head1 AUTHOR

id:youpy

=head1 SEE ALSO

L<Plagger>

=cut
