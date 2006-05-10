package Plagger::Server;
use strict;

use Carp;

use base qw( Plagger Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(config protocol) );

use Plagger::Server::Protocol;

sub bootstrap {
    my($class, %opt) = @_;

    my $self = bless {
        conf  => {},
        update => Plagger::Update->new,
        subscription => Plagger::Subscription->new,
        plugins_path => {},
        plugins => [],
        rewrite_tasks => []
    }, $class;

    my $config;
    if (-e $opt{config} && -r _) {
        $config = YAML::LoadFile($opt{config});
        $self->load_include($config);
        $self->{conf} = $config->{global};
        $self->{conf}->{log} ||= { level => 'debug' };
        $self->{config_path} = $opt{config};
    } else {
        croak "Plagger->bootstrap: $opt{config}: $!";
    }
    $self->config($config);

    local *Plagger::context = sub { $self };

    $self->protocol(Plagger::Server::Protocol->new);
    $self->load_recipes($config);
    $self->load_cache($opt{config});
    $self->load_plugins(@{ $config->{plugins} || [] });
    $self->rewrite_config if @{ $self->{rewrite_tasks} };
    $self->server_run();
}

sub clear_session {
    my $self = shift;

    $self->update(Plagger::Update->new);
    $self->subscription(Plagger::Subscription->new);
}

sub server_run {
    my $self = shift;

    $self->run_hook('protocol.load');

    $self->run_hook('engine.load');

    $self->run_hook('pull.init');

    $self->run_hook('engine.run');
}

sub engine_run {
    my $self = shift;
    my $req = shift;

    $self->log(debug => "engine_run.");

    $self->run_hook('plugin.init');
    $self->run_hook('subscription.load');

    unless ( $self->is_loaded(qr/^Aggregator::/) ) {
        $self->load_plugin({ module => 'Aggregator::Simple' });
    }

    for my $feed ($self->subscription->feeds) {
        if (my $sub = $feed->aggregator) {
            $sub->($self, { feed => $feed, req => $req });
        } else {
            my $ok = $self->run_hook_once('customfeed.handle', { feed => $feed, req => $req });
            if (!$ok) {
                Plagger->context->log(error => $feed->url . " is not aggregated by any aggregator");
                Plagger->context->subscription->delete_feed($feed);
            }
        }
    }

    $self->run_hook('aggregator.finalize');

    for my $feed ($self->update->feeds) {
        $self->run_hook('pull.handle', { feed => $feed, req => $req });
    }

    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('update.entry.fixup', { feed => $feed, entry => $entry, req => $req });
        }
        $self->run_hook('update.feed.fixup', { feed => $feed, req => $req });
    }

    $self->run_hook('update.fixup');

    $self->run_hook('smartfeed.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('smartfeed.entry', { feed => $feed, entry => $entry, req => $req });
        }
        $self->run_hook('smartfeed.feed', { feed => $feed, req => $req });
    }
    $self->run_hook('smartfeed.finalize');

    $self->run_hook('publish.init');
    for my $feed ($self->update->feeds) {
        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry.fixup', { feed => $feed, entry => $entry, req => $req });
        }

        $self->run_hook('publish.feed', { feed => $feed, req => $req });

        for my $entry ($feed->entries) {
            $self->run_hook('publish.entry', { feed => $feed, entry => $entry,  req => $req });
        }
    }
    for my $feed ($self->update->feeds) {
        $self->run_hook('pull.publish', { feed => $feed, req => $req });
    }

    $self->run_hook('publish.finalize');

    $self->run_hook('pull.finalize', { req => $req });

    $self->clear_session;
}

1;

