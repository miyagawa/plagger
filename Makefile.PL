use strict;
use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name('Plagger');
all_from('lib/Plagger.pm');

requires('Class::Accessor::Fast');
requires('File::Find::Rule');
requires('UNIVERSAL::require' => 0.10);
requires('Template', 2.13);
requires('Template::Provider::Encoding' => 0.04);
requires('YAML' => 0.39);
requires('Text::Tags');
requires('DateTime' => 0.35);
requires('DateTime::TimeZone' => 0.56);
requires('DateTime::Locale' => 0.32);
requires('DateTime::Format::Mail');
requires('DateTime::Format::W3CDTF');
requires('DateTime::Format::Strptime');
requires('Digest::MD5');
requires('LWP');
requires('HTML::Parser' => 3.51);
requires('URI::Fetch' => 0.071);
requires('Cache::Cache' => 1.04);
requires('Module::Pluggable' => 3.6);
requires('HTML::ResolveLink');
requires('Date::Parse');
requires('MIME::Types', 1.16);
requires('Net::DNS');

requires('XML::Feed', 0.41);
requires('XML::LibXML');
requires('XML::Atom', 0.23);
requires('XML::RSS::LibXML', 0.3002);
requires('Encode', 2.10);
requires('Term::Encoding');
requires('File::HomeDir');

build_requires('YAML');
build_requires('YAML::Loader');
include_deps('YAML');

build_requires('Test::More', 0.42);
build_requires('Test::Base', 0.52);

features(
    'Better Encoding detection' => [
        -default => 0,
        recommends_hack('Encode::Detect', 1.0),
    ],
    'POD Testing' => [
        -default => 0,
        recommends_hack('Test::Pod'),
        recommends_hack('Test::Pod::Coverage'),
    ],
    'Cookie sharing with Firefox' => [
        -default => 0,
        recommends_hack('HTTP::Cookies::Mozilla'),
    ],
    'Liberal XML parsing' => [
        -default => 1,
        recommends_hack('XML::Liberal', 0.14),
        recommends_hack('XML::RSS::Liberal'),
    ],
    'XPath support in Subscription and Feed Upgrader' => [
        -default => 1,
        recommends_hack('HTML::TreeBuilder::XPath'),
    ],
    'Better html to text formatter' => [
        -default => 1,
        recommends_hack('HTML::TreeBuilder'),
        recommends_hack('HTML::FormatText'),
    ],
    'Parse Japanese datetime format' => [
        -default => 0,
        recommends_hack('DateTime::Format::Japanese'),
    ],
);

require YAML;
require DirHandle;
require File::Spec;

my $dh = DirHandle->new("deps");
my @plugins;
while (my $f = $dh->read) {
    next unless $f =~ /\.yaml$/;
    my $meta = eval { YAML::LoadFile( File::Spec->catfile("deps", $f) ) };
    if ($@) {
        warn "Loading deps/$f failed: $@";
        next;
    }
    push @plugins, $meta if !$meta->{platform} || $meta->{platform} eq $^O;
}

for my $meta (sort { $b->{default} <=> $a->{default} || $a->{name} cmp $b->{name} } @plugins) {
    features(
        $meta->{name}, [
            -default => $meta->{default},
            map recommends_hack($_ => $meta->{depends}->{$_}), keys %{$meta->{depends} || {}},
        ],
    );
}

tests 't/*.t t/*/*.t t/*/*/*.t';

use_test_base;

auto_include;
auto_install;

install_script('plagger');
install_script('bin/plagger-ircbot');
WriteAll;
