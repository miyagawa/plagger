package Plagger::Plugin::Aggregator::Null;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle'  => \&aggregate,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;
    $context->update->add($args->{feed});
    return 1;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Aggregator::Null - Aggregator that doesn't do anything

=head1 SYNOPSIS

  - module: Aggregator::Null

=head1 DESCRIPTION

This plugin implements Plagger Aggregator but it doesn't do anything
useful. It could be only useful when you want to just pass subscribed
feed to Publish/Notify plugins, or inside test scripts.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
