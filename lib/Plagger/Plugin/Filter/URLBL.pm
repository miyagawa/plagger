package Plagger::Plugin::Filter::URLBL;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

use Net::DNS::Resolver;
use URI::Find;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'filter.content' => \&content,
    );
}

sub content {
    my($self, $context, $entry, $content) = @_;

    my @urls;
    my $finder = URI::Find->new(
        sub {
            my($uri, $orig_uri) = @_;
            push @urls, $uri;
            return $orig_uri;
        },
    );
    $finder->find(\$content);

    my $res = Net::DNS::Resolver->new;
    my $dnsbl = $self->conf->{dnsbl};
       $dnsbl = [ $dnsbl ] unless ref $dnsbl;

    for my $url (@urls) {
        my $uri = URI->new($url);
        my $domain = $uri->host;
        $domain =~ s/^www\.//;

        for my $dns (@$dnsbl) {
            $context->log(debug => "looking up $domain.$dns");
            my $q = $res->search("$domain.$dns");
            if ($q && $q->answer) {
                my $rate = $self->conf->{rate} || -1;
                $context->log(warn => "$domain.$dns found. Add rate $rate");
                $entry->add_rate($rate);
            }
        }
    }
}

1;
