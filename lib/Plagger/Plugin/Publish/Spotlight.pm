package Plagger::Plugin::Publish::Spotlight;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use File::Spec;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    my $entry = $args->{entry};
    my $file = $entry->id_safe . '.webbookmark';
    my $path = File::Spec->catfile($dir, $file);
    $context->log(info => "writing output to $path");

    my $body = $self->templatize($context, $entry);
    
    open my $out, ">:utf8", $path or $context->error("$path: $!");
    print $out $body;
    close $out;

    # Add $entry->body as spotlight comment using AppleScript (OSX only)
    if ($self->{conf}->{add_comment}) {
	eval { require Mac::Glue };
	my $comment = $entry->body;
	utf8::decode($comment) unless utf8::is_utf8($comment);
	$comment =~ s/<[^>]*>//g;
	$comment =~ s/\n//g;
	$comment = encode("shift_jis", $comment); # xxx
	
	my $finder = Mac::Glue->new("Finder");
	my $file = $finder->obj(file => $path);
	$file->prop('comment')->set(to => $comment);
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
      add_comment: 1

=head1 DESCRIPTION

This plugin creates webbookmark files and make feed updates searchable
by Mac OSX Spotlight.

=head1 SCREENSHOT

L<http://subtech.g.hatena.ne.jp/youpy/20060223/p1>

=head1 AUTHOR

id:youpy

=head1 SEE ALSO

L<Plagger>

=cut
