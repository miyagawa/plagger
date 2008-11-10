# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Plagger::Plugin::Filter::FetchEnclosure::Xango;
use strict;
use base qw(Plagger::Plugin::Filter::FetchEnclosure);
BEGIN {
    sub Xango::DEBUG{ 1 } ## no critic (ProhibitNestedSubs)
}
use Xango::Broker::Push;

sub register {
    my($self, $context) = @_;
    my %xango_args = (
        Alias => 'xgbroker',
        HandlerAlias => 'xghandler',
        HttpCompArgs => [ Agent => "Plagger/$Plagger::VERSION (http://plagger.org/)", Timeout => $self->conf->{timeout} || 10 ],
        %{$self->conf->{xango_args} || {}},
    );
    $self->{xango_alias} = $xango_args{Alias};
    Plagger::Plugin::Filter::FetchEnclosure::Xango::Crawler->spawn(
        Plugin => $self,
        BrokerAlias => $xango_args{Alias},
        UseCache => exists $self->conf->{use_cache} ?
            $self->conf->{use_cache} : 1,
        MaxRedirect => $self->conf->{max_redirect} || 3,
    );
    Xango::Broker::Push->spawn(%xango_args);

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&enqueue,
        'update.fixup'       => \&fetch,
    );

}

sub enqueue
{
    my($self, $context, $args) = @_;

    for my $enclosure ($args->{entry}->enclosures) {
        my $feed_dir = File::Spec->catfile($self->conf->{dir}, $args->{feed}->id_safe);
        unless (-e $feed_dir && -d _) {
            $context->log(info => "mkdir $feed_dir");
            mkdir $feed_dir, 0777;
        }

        my $path = File::Spec->catfile($feed_dir, $enclosure->filename);
        $context->log(info => "fetch " . $enclosure->url . " to " . $path);

        my %job_args;
        if ($self->conf->{fake_referer}) {
            $context->log(debug => "Sending Referer: " . $args->{entry}->permalink);
            $job_args{referer} = $args->{entry}->permalink;
        }
        my $job = Xango::Job->new(
            uri      => URI->new($enclosure->url), 
            redirect => 0,
            path     => $path,
            enclosure => $enclosure,
        );
    
        POE::Kernel->post($self->{xango_alias}, 'enqueue_job', $job);
    }
}

sub fetch { POE::Kernel->run }

package Plagger::Plugin::Filter::FetchEnclosure::Xango::Crawler;
use strict;
use POE;
use File::Path qw(mkpath);
use File::Basename qw(dirname);

sub apply_policy { 1 }
sub spawn  {
    my $class = shift;
    my %args  = @_;

    POE::Session->create(
        heap => {
            PLUGIN => $args{Plugin},
            USE_CACHE => $args{UseCache},
            BROKER_ALIAS => $args{BrokerAlias},
            MaxRedirect => $args{MaxRedirect},
        },
        package_states => [
            $class => [ qw(_start _stop apply_policy prep_request handle_response) ]
        ]
    );
}

sub _start { $_[KERNEL]->alias_set('xghandler') }
sub _stop  { }
sub prep_request {
    return unless $_[HEAP]->{USE_CACHE};

    my $job = $_[ARG0];
    my $req = $_[ARG1];
    my $plugin = $_[HEAP]->{PLUGIN};

    my $ref = $plugin->cache->get($job->uri);
    if ($ref) {
        $req->if_modified_since($ref->{LastModified})
            if $ref->{LastModified};
        $req->header('If-None-Match', $ref->{ETag})
            if $ref->{ETag};
    }

    $req->header(Referer => $job->notes('referer'))
        if $job->notes('referer');
}

sub handle_response {
    my $job = $_[ARG0];
    my $plugin = $_[HEAP]->{PLUGIN};

    my $redirect = $job->notes('redirect') + 1;
    return if $redirect > $_[HEAP]->{MaxRedirect};

    my $r = $job->notes('http_response');
    my $url    = $job->uri;
    if ($r->code =~ /^30[12]$/) {
        $url = $r->header('location');
        return unless $url =~ m!^https?://!i;
        my $new_job = Xango::Job->new(
            uri => URI->new($url),
            redirect => $redirect,
            path => $job->notes('path'), # TODO: rewrite path with the new URL? respect Content-Disposition?
            enclosure => $job->notes('enclosure'),
        );
        $_[KERNEL]->post($_[HEAP]->{BROKER_ALIAS}, 'enqueue_job', $new_job);
	return;
    } else {
        return unless $r->is_success;

        my $local_path = $job->notes('path');

        my $dir = dirname($local_path);
        if (!-d $dir) {
            if (! mkpath([$dir], 0, 0777) || !-d $dir || !-w _) {
                $plugin->log(warn => "failed to create directory $dir: $!");
                return;
            }
        }

        open(my $fh, ">", $local_path);
        if (! $fh) {
            $plugin->log(warn => "failed to open $local_path for writing: $!");
            return;
        }

        print $fh $r->content;
        close($fh);

        my $enclosure = $job->notes('enclosure');
        $enclosure->local_path($local_path);
        # Fix length if it's broken
        if ($r->header('Content-Length')) {
            $enclosure->length($r->header('Content-Length'));
        }
    }

    if ($_[HEAP]->{USE_CACHE}) {
        $plugin->cache->set(
            $job->uri,
            {ETag => $r->header('ETag'),
                LastModified => $r->header('Last-Modified')}
        );
    }
}

1;

1;
