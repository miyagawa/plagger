#!/usr/bin/perl
use strict;
use warnings;
use YAML;

print YAML::Dump({
    title => "Foo Bar",
    link  => "http://example.com/",
    entry => [
        { title => "Entry 1",
          link  => "http://example.com/1",
          body  => "Foo bar" },
        { title => "Entry 2",
          link  => "http://example.com/2",
          body  => "Foo bar" },
    ],
});
