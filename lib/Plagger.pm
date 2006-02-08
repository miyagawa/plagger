package Plagger;
use strict;
our $VERSION = '0.10';

use 5.8.1;
use Carp;
use Data::Dumper;
use YAML;
use UNIVERSAL::require;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(conf stash update subscription) );

use Plagger::Date;
use Plagger::Entry;
use Plagger::Feed;
use Plagger::Subscription;
use Plagger::Template;
use Plagger::Update;

sub active_hooks {
    my $self = shift;
    my @hooks= keys %{$self->{hooks}};
    wantarray ? @hooks : \@hooks;
}

sub context { undef }

sub bootstrap {
    my($class, %opt) = @_;

    my $self = bless {
        conf  => {},
        stash => {},
        update => Plagger::Update->new,
        subscription => Plagger::Subscription->new,
    }, $class;

    my $config;
    if (-e $opt{config} && -r _) {
        $config = YAML::LoadFile($opt{config});
        $self->{conf} = $config->{global};
    } else {
        croak "Plagger->bootstrap: $opt{config}: $!";
    }

    local *Plagger::context = sub { $self };

    $self->load_plugins(@{ $config->{plugins} || [] });
    $self->run();
}

sub load_plugins {
    my($self, @plugins) = @_;

    if ($self->conf->{plugin_path}) {
        unshift @INC, @{ $self->conf->{plugin_path} };
    }

    for my $plugin (@plugins) {
        $self->load_plugin($plugin) unless $plugin->{disable};
    }
}

sub load_plugin {
    my($self, $config) = @_;

    my $module = delete $config->{module};
    $module =~ s/^Plagger::Plugin:://;
    $module = "Plagger::Plugin::$module";
    $module->require or die $@;

    $self->log(info => "plugin $module loaded.");

    my $plugin = $module->new($config);
    $plugin->register($self);
}

sub register_hook {
    my($self, $plugin, @hooks) = @_;
    while (my($hook, $callback) = splice @hooks, 0, 2) {
        push @{ $self->{hooks}->{$hook} }, +{
            callback  => $callback,
            plugin    => $plugin,
        };
    }
}

sub run_hook {
    my($self, $hook, $args) = @_;
    for my $action (@{ $self->{hooks}->{$hook} }) {
        my $plugin = $action->{plugin};
        if ( $plugin->rule->dispatch($hook, $args) ) {
            $action->{callback}->($plugin, $self, $args);
        }
    }
}

sub run {
    my $self = shift;

    $self->run_hook('subscription.load');

    for my $type ($self->subscription->types) {
        for my $feed ($self->subscription->feeds_by_type($type)) {
            $self->run_hook("aggregator.aggregate.$type", { feed => $feed });
        }
    }

    $self->run_hook('update.fixup');

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('filter.content', { entry => $entry, content => $entry->text });
        }
        $self->run_hook('publish.add_feed', { feed => $feed });
    }

    $self->run_hook('publish.finalize');
}

sub log {
    my($self, $level, $msg) = @_;
    my $caller = caller(0);
    chomp($msg);
    warn "$caller [$level] $msg\n";
}

sub error {
    my($self, $msg) = @_;
    my($caller, $filename, $line) = caller(0);
    chomp($msg);
    die "$caller [fatal] $msg at line $line\n";
}

sub dumper {
    my($self, $stuff) = @_;
    local $Data::Dumper::Indent = 1;
    $self->log(debug => Dumper($stuff));
}

sub template {
    my $self = shift;
    $self->{template} ||= Plagger::Template->new($self);
}

1;
__END__

=head1 NAME

Plagger - Pluggable RSS/Atom Aggregator

=head1 SYNOPSIS

  use Plagger;

=head1 DESCRIPTION

Plagger is a pluggable RSS/Atom feed aggregator.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.bulknews.net/>

=cut
