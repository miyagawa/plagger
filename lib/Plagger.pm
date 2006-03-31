package Plagger;
use strict;
our $VERSION = '0.5.7';

use 5.8.1;
use Carp;
use Data::Dumper;
use File::Basename;
use File::Find::Rule;
use YAML;
use UNIVERSAL::require;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(conf update subscription plugins_path cache) );

use Plagger::Cache;
use Plagger::CacheProxy;
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
        plugins => [],
    }, $class;

    my $config;
    if (-e $opt{config} && -r _) {
        $config = YAML::LoadFile($opt{config});
        $self->load_include($config);
        $self->{conf} = $config->{global};
        $self->{conf}->{log}   ||= { level => 'debug' };
    } else {
        croak "Plagger->bootstrap: $opt{config}: $!";
    }

    local *Plagger::context = sub { $self };

    $self->load_recipes($config);
    $self->load_cache($opt{config});
    $self->load_plugins(@{ $config->{plugins} || [] });
    $self->run();
}

sub load_include {
    my($self, $config) = @_;

    return unless $config->{include};
    for (@{ $config->{include} }) {
        my $include = YAML::LoadFile($_);

        for my $key (keys %{ $include }) {
            my $add = $include->{$key};
            unless ($config->{$key}) {
                $config->{$key} = $add;
                next;
            }
            if (ref($config->{$key}) eq 'HASH') {
                next unless ref($add) eq 'HASH';
                for (keys %{ $include->{$key} }) {
                    $config->{$key}->{$_} = $include->{$key}->{$_};
                }
            } elsif (ref($include->{$key}) eq 'ARRAY') {
                $add = [ $add ] unless ref($add) eq 'ARRAY';
                push(@{ $config->{$key} }, @{ $include->{$key} });
            } elsif ($add) {
                $config->{$key} = $add;
            }
        }
    }
}

sub load_recipes {
    my($self, $config) = @_;

    for (@{ $config->{recipes} }) {
        $self->error("no such recipe to $_") unless $config->{define_recipes}->{$_};
        my $plugin = $config->{define_recipes}->{$_};
        $plugin = [ $plugin ] unless ref($plugin) eq 'ARRAY';
        push(@{ $config->{plugins} }, @{ $plugin });
    }
}

sub load_cache {
    my($self, $config) = @_;

    # use config filename as a base directory for cache
    my $base = ( basename($config) =~ /^(.*?)\.yaml$/ )[0];
    my $dir  = $base eq 'config' ? ".plagger" : ".plagger-$base";

    $self->{conf}->{cache} ||= {
        base => File::Spec->catfile($ENV{HOME}, $dir),
    };

    $self->cache( Plagger::Cache->new($self->{conf}->{cache}) );
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

sub is_loaded {
    my($self, $stuff) = @_;

    my $sub = ref $stuff && ref $stuff eq 'Regexp'
        ? sub { $_[0] =~ $stuff }
        : sub { $_[0] eq $stuff };

    for my $plugin (@{ $self->{plugins} }) {
        my $module = ref $plugin;
           $module =~ s/^Plagger::Plugin:://;
        return 1 if $sub->($module);
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
    $plugin->cache( Plagger::CacheProxy->new($plugin, $self->cache) );
    $plugin->register($self);

    push @{$self->{plugins}}, $plugin;
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
    my($self, $hook, $args, $once) = @_;
    for my $action (@{ $self->{hooks}->{$hook} }) {
        my $plugin = $action->{plugin};
        if ( $plugin->rule->dispatch($plugin, $hook, $args) ) {
            my $done = $action->{callback}->($plugin, $self, $args);
            return 1 if $once && $done;
        }
    }

    # if $once is set, here means not executed = fail
    return if $once;
}

sub run_hook_once {
    my($self, $hook, $args) = @_;
    $self->run_hook($hook, $args, 1);
}

sub run {
    my $self = shift;

    $self->run_hook('plugin.init');
    $self->run_hook('subscription.load');

    unless ( $self->is_loaded(qr/^Aggregator::/) ) {
        $self->load_plugin({ module => 'Aggregator::Simple' });
    }

    for my $feed ($self->subscription->feeds) {
        if (my $sub = $feed->aggregator) {
            $sub->($self, { feed => $feed });
        } else {
            my $ok = $self->run_hook_once('customfeed.handle', { feed => $feed });
            if (!$ok) {
                Plagger->context->log(error => $feed->url . " is not aggregated by any aggregator");
            }
        }
    }

    $self->run_hook('aggregator.finalize');

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('update.entry.fixup', { feed => $feed, entry => $entry });
        }
        $self->run_hook('update.feed.fixup', { feed => $feed });
    }

    $self->run_hook('update.fixup');

    $self->run_hook('smartfeed.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('smartfeed.entry', { feed => $feed, entry => $entry });
        }
    }
    $self->run_hook('smartfeed.finalize');

    $self->run_hook('publish.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry.fixup', { feed => $feed, entry => $entry });
        }

        $self->run_hook('publish.feed', { feed => $feed });

        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry', { feed => $feed, entry => $entry });
        }
    }

    $self->run_hook('publish.finalize');
}

sub log {
    my($self, $level, $msg, %opt) = @_;

    # hack to get the original caller as Plugin or Rule
    my $caller = $opt{caller};
    unless ($caller) {
        my $i = 0;
        while (my $c = caller($i++)) {
            last if $c !~ /Plugin|Rule/;
            $caller = $c;
        }
        $caller ||= caller(0);
    }

    chomp($msg);
    if ($self->should_log($level)) {
        warn "$caller [$level] $msg\n";
    }
}

my %levels = (
    debug => 0,
    warn  => 1,
    info  => 2,
    error => 3,
);

sub should_log {
    my($self, $level) = @_;
    $levels{$level} >= $levels{$self->conf->{log}->{level}};
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
    my $plugin = shift || (caller)[0];
    Plagger::Template->new($self, $plugin->class_id);
}

sub templatize {
    my($self, $plugin, $file, $vars) = @_;
    my $tt = $self->template($plugin);
    $tt->process($file, $vars, \my $out) or $self->error($tt->error);
    $out;
}


1;
__END__

=head1 NAME

Plagger - Pluggable RSS/Atom Aggregator

=head1 SYNOPSIS

  % plagger -c config.yaml

=head1 DESCRIPTION

Plagger is a pluggable RSS/Atom feed aggregator and remixer platform.

Everything is implemented as a small plugin just like qpsmtpd, blosxom
and perlbal. All you have to do is write a flow of aggregation,
filters, syndication, publishing and notification plugins in config
YAML file.

See L<http://plagger.org/> for cookbook examples, quickstart document,
development community (Mailing List and IRC), subversion repository
and bug tracking.

=head1 BUGS / DEVELOPMENT

If you find any bug, or you have an idea of nice plugin and want help
on it, drop us a line to our mailing list
L<http://groups.google.com/group/plagger-dev> or stop by the IRC
channel C<#plagger> at irc.freenode.net.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>

=cut
