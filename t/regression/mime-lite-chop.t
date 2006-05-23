use strict;
use FindBin;
use File::Spec;
use Test::More tests => 2;

use Plagger;
use MIME::Lite;
use MIME::Parser;

no warnings 'redefine';
local *MIME::Lite::send = sub {
    my($mime, @args) = @_;
    like $mime->as_string, qr/Content-Transfer-Encoding: quoted-printable/;

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    my $entity = $parser->parse_data( $mime->as_string );

    my $body = Encode::decode("utf-8", $entity->parts(0)->bodyhandle->as_string);
    like $body, qr/\x{5bae}{500}/;
};

Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../assets
plugins:
  - module: CustomFeed::LongBody
  - module: Publish::Gmail
    config:
      mailto: foobar\@localhost
CONFIG

package Plagger::Plugin::CustomFeed::LongBody;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });

    $context->subscription->add($feed);
}

sub aggregate {
    my ($self, $context, $args) = @_;

    my $feed  = Plagger::Feed->new;
    $feed->title("Foo Bar");
    $feed->link("http://localhost/");

    my $entry = Plagger::Entry->new;
    $entry->title("Long body");
    $entry->body( "\x{5bae}" x 500 );

    $feed->add_entry($entry);
    $context->update->add($feed);
}
