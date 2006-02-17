package Plagger;
use strict;
our $VERSION = '0.10';

use 5.8.1;
use Carp;
use Data::Dumper;
use File::Find::Rule;
use YAML;
use UNIVERSAL::require;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(conf update subscription plugins_path) );

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
        update => Plagger::Update->new,
        subscription => Plagger::Subscription->new,
        plugins_path => {},
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
        for my $path (@{ $self->conf->{plugin_path} }) {
            my $rule = File::Find::Rule->new;
               $rule->file;
               $rule->name( qr/^\w[\w\.]*$/ );
            my @files = $rule->in($path);

            for my $file (@files) {
                next if $file =~ /\W(?:\.svn|CVS)\b/;
                my $pkg = $self->extract_package($file)
                    or die "Can't find package from $file";

                (my $base = $file) =~ s!^$path/!!;
                $self->plugins_path->{$pkg} = $file;
            }
        }
    }

    for my $plugin (@plugins) {
        $self->load_plugin($plugin) unless $plugin->{disable};
    }
}

sub extract_package {
    my($self, $file) = @_;

    open my $fh, $file or die "$file: $!";
    while (<$fh>) {
        /^package (Plagger::Plugin::.*?);/ and return $1;
    }

    return;
}

sub load_plugin {
    my($self, $config) = @_;

    my $module = delete $config->{module};
    $module =~ s/^Plagger::Plugin:://;
    $module = "Plagger::Plugin::$module";

    if (my $path = $self->plugins_path->{$module}) {
        eval { require $path } or die $@;
    } else {
        $module->require or die $@;
    }

    $self->log(info => "plugin $module loaded.");

    my $plugin = $module->new($config);
    $plugin->register($self);
}

sub register_hook {
    my($self, $plugin, @hooks) = @_;
    while (my($hook, $callback) = splice @hooks, 0, 2) {
        # set default rule_hook $hook to $plugin
        $plugin->rule_hook($hook) unless $plugin->rule_hook;

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
        if ( $plugin->rule->dispatch($plugin, $hook, $args) ) {
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

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('update.entry.fixup', { feed => $feed, entry => $entry });
        }
        $self->run_hook('update.feed.fixup', { feed => $feed });
    }

    $self->run_hook('update.fixup');

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry.fixup', { feed => $feed, entry => $entry });
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
