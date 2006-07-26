package Plagger::Plugin::Publish::FOAFRoll;
use strict;
use base qw( Plagger::Plugin );

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

    my $out = $self->templatize('foafroll.tt', {
        feeds => [ $context->subscription->feeds ],
        conf  => $self->conf,
    });

    my $path = $self->conf->{filename};
    $context->log(info => "Writing FOAFRoll to $path");

    open my $fh, ">:utf8", $path or $context->error("$path: $!");
    print $fh $out;
    close $fh;
}

1;

__END__

=head1

Plagger::Plugin::Publish::FOAFRoll - Publish foafroll RDF file using subscriptions

=head1 SYNOPSYS

  - module: Publish::FOAFRoll
    config:
      filename: /path/to/foafroll.rdf
      link: http://example.org/

=head1 DESCRIPTION

This plugin publishes foaf based blogroll (foafroll) using feeds found
in the subscription.

=head1 CONFIG

=over 4

=item filename

File name to save foafroll files in. Recommended to name it
I<foafroll.rdf> or I<foafroll.xml>. Required.

=item link

URL to use in I<foaf:homepage> element. Optional.

=item url

URL to self reference the foafroll file. Optional.

=item title

Title of the foafroll. Optional and defaults to I<Plagger foafroll>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://usefulinc.com/edd/notes/RDFBlogRoll>

=cut
