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
    );
}

sub load {
    my ($self, $context) = @_;
    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });
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

        # enclosure
        for my $enclosure_conf ( @{ $entry_conf->{enclosure} } ){
            my $enclosure = Plagger::Enclosure->new;
            $enclosure->$_($enclosure_conf->{$_}) for keys %$enclosure_conf;
            $entry->add_enclosure($enclosure);
        }
    }

    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Debug - Feed in config.yaml

=head1 SYNOPSIS

  - module: CustomFeed::Debug
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
          enclosure:
            - url: http://localhost/debug.flv
              filename: debug.flv
              type: video/x-flv

=head1 DESCRIPTION

This plugin allows you to define your feed in C<config.yaml>, which
makes it easier creating a testing environment for your Plugin
development.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>

=cut

