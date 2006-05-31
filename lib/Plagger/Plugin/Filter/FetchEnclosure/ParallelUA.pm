package Plagger::Plugin::Filter::FetchEnclosure::ParallelUA;
use strict;
use base qw(Plagger::Plugin::Filter::FetchEnclosure);

use LWP::Parallel::UserAgent;
use HTTP::Request;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&enqueue,
        'update.fixup'       => \&fetch,
        'plugin.init'        => \&plugin_init,
    );
}

sub plugin_init {
    my $self = shift;
    $self->{ua} = LWP::Parallel::UserAgent->new;
    $self->{ua}->max_hosts( $self->conf->{concurrency} || 10 );
    $self->{ua}->max_req( $self->conf->{max_requests_per_host} || 2 );
}

sub enqueue {
    my($self, $context, $args) = @_;

    for my $enclosure ($args->{entry}->enclosures) {
        # TODO: do all of this in the base class ::Command
        my $feed_dir = File::Spec->catfile($self->conf->{dir}, $args->{feed}->id_safe);
        unless (-e $feed_dir && -d _) {
            $context->log(info => "mkdir $feed_dir");
            mkdir $feed_dir, 0777;
        }

        my $path = File::Spec->catfile($feed_dir, $enclosure->filename);

        if ($enclosure->length && -e $path && -s _ == $enclosure->length) {
            # TODO: if-none-match
            $context->log(debug => $enclosure->url . "is already stored in $path");
#            next;
        }

        $context->log(info => "fetch " . $enclosure->url . " to " . $path);

        my $req = HTTP::Request->new(GET => $enclosure->url);

        if ($self->conf->{fake_referer}) {
            $context->log(debug => "Sending Referer: " . $args->{entry}->permalink);
            $req->header('Referer' => $args->{entry}->permalink);
        }

        $self->{ua}->register($req, $path);
        $self->{callback}->{$enclosure->url} = sub {
            my $response = shift;

            if ($response->code =~ /^[23]/) {
                if (my $length = $response->header('Content-Length')) {
                    $enclosure->length($length);
                    $enclosure->local_path($path);
                }
            } else {
                # xxx
            }
        };
    }
}

sub fetch {
    my($self, $context) = @_;

    $context->log(debug => "wait for responses from Parallel UA ...");
    my $entries = $self->{ua}->wait;

    for my $entry (values %$entries) {
        my $response = $entry->response;

        if (my $cb = $self->{callback}->{$response->request->url}) {
            $cb->($response);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FetchEnclosure::ParallelUA - Fetch enclosures using Parallel UA

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure::ParallelUA
    config:
      dir: /path/to/download
      concurrency: 5
      max_requests_per_host: 2

=head1 DESCRIPTION

This pluguins uses LWP::Parallel UA to download enclosures from multiple hosts in parallel.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<LWP::Parallel::UserAgent>

=cut
