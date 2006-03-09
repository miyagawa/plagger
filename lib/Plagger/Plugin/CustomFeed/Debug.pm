package Plagger::Plugin::CustomFeed::Debug;
use strict;
use warnings;
use base qw (Plagger::Plugin);

our $VERSION = 0.01;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.debug' => \&aggregate,
    );
}

sub load {
    my ($self, $context) = @_;
    my $feed = Plagger::Feed->new;
    $feed->type('debug');
    $context->subscription->add($feed);
}

sub aggregate {
    my ($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('debug');
    for (keys %{$self->conf}) {
        next if $_ eq 'entry';
        $feed->$_($self->conf->{$_});
    }

    for my $entry_conf (@{$self->conf->{entry}}) {
        my $entry = Plagger::Entry->new;
        $entry->$_($entry_conf->{$_}) for keys %$entry_conf;
        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Deubg - Feed in config.yaml

=head1 SYNOPSIS

  - module: CustomFeed::Deubg
    config:
      title: 'My Feed'
      link: 'http://localhost/'
      entry:
        - title: 'First Entry'
          link: 'http://localhost/1'
          body: 'Hello World! :)'
        - title: 'Second Entry'
          link: 'http://localhost/2'
          body: 'Good Bye! :P'

=head1 DESCRIPTION

This plugin allows you to define your feed in C<config.yaml>, which
makes it easier creating a testing environment for your Plugin
development.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>

=cut

