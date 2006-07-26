package Plagger::Plugin::Publish::OPML;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Date;
use File::Spec;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my $output = $self->conf->{filename}
        or Plagger->context->error("filename is missing");
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.finalize' => \&finalize,
    );
}

sub finalize {
    my($self, $context, $args) = @_;

    my $out = $self->templatize('opml.tt', {
        feeds => [ $context->subscription->feeds ],
        now   => Plagger::Date->now,
        conf  => $self->conf,
    });

    my $path = $self->conf->{filename};
    $context->log(info => "Writing OPML to $path");

    open my $fh, ">:utf8", $path or $context->error("$path: $!");
    print $fh $out;
    close $fh;
}

1;

__END__

=head1

Plagger::Plugin::Publish::OPML - Publish OPML files based on your subcscription

=head1 SYNOPSYS

  - module: Publish::OPML
    config:
      filename: /path/to/subscription.opml

=head1 DESCRIPTION

This plugin publishes OPML file using feeds fonnd in the subscription.

=head1 CONFIG

=over 4

=item filename

Filename to save the OPML file. Required.

=item title

Title to be used as OPML head. Optional and defaults to I<Plagger Subscriptions>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
