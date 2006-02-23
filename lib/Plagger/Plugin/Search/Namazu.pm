package Plagger::Plugin::Search::Namazu;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&mknmz,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    for my $entry ($args->{feed}->entries) {
	my $file = $entry->id_safe . '.html';
	my $path = File::Spec->catfile($dir, $file);
	$context->log(info => "writing output to $path");

	my $body = $self->templatize($context, { entry => $entry, feed => $args->{feed} });

        # save output as EUC-JP so Namazu can easily handle
	open my $out, ">:encoding(euc-jp)", $path or $context->error("$path: $!");
	print $out $body;
	close $out;

        # "touch" with the entry date if set. otherwise use now
        my $now  = time;
        my $time = eval { $entry->date->epoch };
        $time = $now if !$time or $time >= $now;
        utime $time, $time, $path;
    }
}

sub templatize {
    my($self, $context, $vars) = @_;

    my $tt = $context->template();
    $tt->process('namazu.tt', $vars, \my $out)
        or $context->error($tt->error);

    $out;
}

sub mknmz {
    my($self, $context) = @_;

    my $opt = $self->conf->{mknmz_opt} || '';
    my $dir = $self->conf->{dir};
    my $idx = $self->conf->{index}
        or $context->error("config: index is missing");

    unless (-e $idx && -d _) {
        mkdir $idx, 0755 or $context->error("mkdir $idx: $!");
    }

    my $code = $self->replace_code;
    system("mknmz --replace='$code' --output-dir=$idx --indexing-lang=ja --media-type='text/html' $opt $dir");
}

sub replace_code {
    my $foo = <<'CODE'; $foo =~ s/\n\s+/ /g; return $foo;
    open my $fh, $_
        or return util::vprint("$_: $!");
    while (defined(my $foo = <$fh>)) {
        $foo =~ m!<link rel="self" type="text/html" href="(.*?)" />!
            and $_ = $1;
    }
CODE
}

1;

__END__

=head1 NAME

Plagger::Plugin::Search::Namazu - Search Feed updates by Namazu

=head1 SYNOPSIS

  - module: Search::Namazu
    config:
      dir: /home/miyagawa/plagger-namazu
      index: /var/namazu/index

=head1 DESCRIPTION

This plugin creates HTML files which can be indexed via Namazu.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.namzu.org/>

=cut
