package Plagger;
use strict;
our $VERSION = '0.10';

use 5.8.1;
use Carp;
use Data::Dumper;
use YAML;
use UNIVERSAL::require;

use Plagger::Date;
use Plagger::Entry;
use Plagger::Feed;
use Plagger::Update;
use Template;

our $TT;

sub context { undef }

sub bootstrap {
    my($class, %opt) = @_;

    my $self = bless {
        conf  => {},
        stash => {},
        update => Plagger::Update->new,
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

sub conf   { $_[0]->{conf}  }
sub stash  { $_[0]->{stash} }
sub update { $_[0]->{update} }

sub load_plugins {
    my($self, @plugins) = @_;

    if ($self->conf->{plugin_path}) {
        unshift @INC, @{ $self->conf->{plugin_path} };
    }

    for my $plugin (@plugins) {
        $self->load_plugin($plugin);
    }
}

sub load_plugin {
    my($self, $config) = @_;

    my $module = delete $config->{module};
    $module =~ s/^Plagger::Plugin:://;
    $module = "Plagger::Plugin::$module";
    $module->require or warn $@;

    $self->log(info => "plugin $module loaded.");

    my $plugin = $module->new($config);
    $plugin->register($self);
}

sub register_hook {
    my($self, $plugin, @hooks) = @_;
    while (my($hook, $callback) = splice @hooks, 0, 2) {
        push @{ $self->{hooks}->{$hook} }, +{
            callback => $callback,
            plugin   => $plugin,
        };
    }
}

sub run_hook {
    my($self, $hook, @args) = @_;
    for my $action (@{ $self->{hooks}->{$hook} }) {
        $action->{callback}->($action->{plugin}, $self, @args);
    }
}

sub run {
    my $self = shift;

    $self->run_hook('subscription.load');
    $self->run_hook('subscription.aggregate');

    for my $feed ($self->update->feeds) {
        $self->run_hook('publish.notify', $feed);
    }

    $self->run_hook('publish.finalize');
}

sub log {
    my($self, $level, $msg) = @_;
    my $caller = caller(0);
    chomp($msg);
    warn "$caller: $msg\n";
}

sub dumper {
    my($self, $stuff) = @_;
    local $Data::Dumper::Indent = 1;
    $self->log(debug => Dumper($stuff));
}

sub template {
    my $self = shift;
    unless ($TT) {
        my $path = $self->conf->{template_path} || 'templates';
        $TT = Template->new({ INCLUDE_PATH => [ $path, "$path/plugins" ] });
    }
    $TT;
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
