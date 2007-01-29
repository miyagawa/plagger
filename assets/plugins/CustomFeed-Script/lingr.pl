#!/usr/bin/perl
use strict;
use warnings;
use WebService::Lingr;
use YAML;

my($api_key, $room) = @ARGV;

my $output = {
    title => "Lingr: $room",
    entry => [],
};

my $lingr = WebService::Lingr->new(api_key => $api_key);
$lingr->call('room.enter', { id => $room });
$lingr->call('room.getMessages', {
    ticket => $lingr->response->{ticket},
    counter => 0,
});

for my $msg (@{$lingr->response->{messages} || []}) {
    push @{$output->{entry}}, {
        title  => $msg->{text},
        date   => $msg->{timestamp},
        author => $msg->{nickname},
        url    => "http://www.lingr.com/room/$room#$msg->{id}", # fake URL
    };
}

print Dump $output;



