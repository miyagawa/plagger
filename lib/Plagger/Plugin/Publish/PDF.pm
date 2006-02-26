package Plagger::Plugin::Publish::PDF;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use PDF::FromHTML;

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

    my $file = File::Spec->catfile($dir, $args->{feed}->id . ".pdf");
    my $body = $self->templatize($context, $args);
    utf8::encode($body);

    $context->log(info => "Writing PDF to $file");

    my $pdf = PDF::FromHTML->new;
    $pdf->load_file(\$body);
    $pdf->convert();
    $pdf->write_file($file);
}

sub templatize {
    my($self, $context, $args) = @_;

    # HACK: share the template with Gmail ... for now
    my $tt = $context->template();
    $tt->process('gmail_notify.tt', $args, \my $out)
        or $context->error($tt->error);

    $out;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::PDF - Publish feeds as PDF

=head1 SYNOPSIS

  - module: Publish::PDF
    config:
      dir: /var/web/pdfs

=head1 DESCRIPTION

This plugin creates PDF files which you can be view and print with
Adobe Reader.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<PDF::FromHTML>

=cut
