package Plagger::Plugin::CustomFeed::Script;
use strict;
use base qw( Plagger::Plugin::Aggregator::Simple );

use URI;
use URI::Escape;
use YAML::Syck;

use Plagger::Plugin::Aggregator::Simple;
use Plagger::Plugin::CustomFeed::Debug;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    if (URI->new($args->{feed}->url)->scheme eq 'script') {
        $self->aggregate($context, $args);
        return 1;
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $script = URI->new($args->{feed}->url)->opaque;
       $script =~ s!^//!!;
    $script = URI::Escape::uri_unescape($script); # to support script://python.exe foo.py

    $context->log(debug => "Executing '$script'");
    my $output = qx($script);
    if ($?) {
        $context->log(error => "Error happend while executing '$script': $?");
        return;
    }

    # TODO: check BOM?
    if ($output =~ /^<\?xml/) {
        $context->log(debug => "Looks like output is RSS/Atom");
        $self->SUPER::handle_feed($args->{feed}->url, \$output, $args->{feed});
    } else {
        eval {
            local $YAML::Syck::ImplicitUnicode = 1;
            my $feed = YAML::Syck::Load($output);
            $context->log(debug => "Looks like output is YAML");
            local $self->{conf} = $feed;
            $self->Plagger::Plugin::CustomFeed::Debug::aggregate($context, $args);
        };
        if ($@) {
            $context->log(error => "Failed to parse as YAML. Can't determine output format of $script");
            return;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Script - Script support for Plagger

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - script:/path/to/script.rb
        - script:/path/to/scrape.py
  - module: CustomFeed::Script

=head1 DESCRIPTION

This plugin executes arbitrary script specified in subscription with
I<script:> URI protocol, then parse the STDOUT from the script to
create a feed.

The output from the script can either be Atom/RSS feed, or YAML format
which is compatible to the one used in CustomFeed::Debug. This means
you can reuse your I<something2rss> script used for NetNewsWire or
similar tools, and you can even write your scraper code in other
languages like Python/Ruby.

This plugin auto-detects if the output is XML or YAML.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
