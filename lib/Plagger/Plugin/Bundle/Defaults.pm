package Plagger::Plugin::Bundle::Defaults;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    unless ( $context->is_loaded(qr/^Aggregator::/) ) {
        $context->load_plugin({ module => 'Aggregator::Simple' });
    }

    $context->autoload_plugin({ module => 'Summary::Auto' });
    $context->autoload_plugin({ module => 'Summary::Simple' });

    $context->autoload_plugin({ module => 'Namespace::HatenaFotolife' });
    $context->autoload_plugin({ module => 'Namespace::MediaRSS' });
    $context->autoload_plugin({ module => 'Namespace::ApplePhotocast' });
}

1;
__END__

=head1 NAME

Plagger::Plugin::Bundle::Defaults - Load default built-in plugins

=head1 SYNOPSIS

  # It's not actually needed since Plagger autoload this bundle as well
  - module: Bundle::Defaults

=head1 DESCRIPTION

This plugin is a bundle of default plugins, loaded by default. The
default plugins loaded by this plugin are:

=over 4

=item Aggregator::Simple

=item Summary::Auto

=item Summary::Simple

=item Namespace::MediaRSS

=item Namespace::HatenaFotolife

=item Namespace::ApplePhotocast

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
