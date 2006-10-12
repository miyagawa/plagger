package Plagger::Plugin::Filter::FetchEnclosure::Curl;
use strict;
use base qw(Plagger::Plugin::Filter::FetchEnclosure);

use POE;
use POE::Session;
use POE::Wheel::Run;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&enqueue,
        'update.fixup'       => \&fetch,
    );
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
            next;
        }

        $context->log(info => "fetch " . $enclosure->url . " to " . $path);

        my $referer;
        if ($self->conf->{fake_referer}) {
            $context->log(debug => "Sending Referer: " . $args->{entry}->permalink);
            $referer = $args->{entry}->permalink;
        }

        my $cookies;
        my $conf = $context->conf->{user_agent} || {};
        if ($conf->{cookies}) {
            my $cookie_jar = Plagger::Cookies->create($conf->{cookies});
            if ($cookie_jar->isa('HTTP::Cookies::Mozilla')) {
                $cookies = $cookie_jar->{file};
                $context->log(debug => "Using cookie file $cookies");
            }
        }

        # TODO: max connections per domain to respect RFC
        POE::Session->create(
            inline_states => {
                _start => sub {
                    $_[HEAP]->{wheel} = POE::Wheel::Run->new(
                        Program => [
                            'curl',
                            $enclosure->url,
                            '--output', $path,
                            # xxx resume
                            '--retry', 5,
                            '--location',
                            ($referer ? ('--referer', $referer) : ()),
                            ($cookies ? ('--cookie', $cookies) : ())
                        ],
                        StderrEvent => 'stderr',
                        ErrorEvent => 'wheel_close',
                        CloseEvent => 'wheel_close',
                    );
                },
                stderr => sub {
                    if ($_[ARG0] =~ /^100\s+(\d+)/m) { # xxx it doesn't work
                        my $length = -s $path;
                        $enclosure->local_path($path);
                        $enclosure->length($length);
                        $context->log(info => "Download to $path is done [$length]");
                    }

                    $context->log(debug => $_[ARG0]);
                },
                wheel_close => sub {
                    delete $_[HEAP]->{wheel};
                },
            },
        );
    }
}

sub fetch {
    Plagger->context->log(info => "Start downloading files using curl.");
    POE::Kernel->run;
    Plagger->context->log(info => "w00t! Downloading finished.");
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FetchEnclosure::Curl - Fetch enclosures using curl

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure::Curl
    config:
      dir: /path/to/download
      concurrency: 5
      max_requests_per_host: 2

=head1 DESCRIPTION

This plugin uses curl command to download enclosure files.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
