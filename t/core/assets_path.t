use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected_with_capture;

package Plagger::Plugin::Test::AssetsPath;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $self->log(error => "assets_path is " . $self->assets_dir);
    $context->register_hook($self, 'publish.feed' => \&template);
}

sub template {
    my($self, $context) = @_;
    $self->log(error => "template: " . $self->templatize("assets_path.tt"));
}

package main;

__END__

=== Test global:assets_path
--- input config
plugins:
  - module: Test::AssetsPath
--- expected
like $warning, qr!plugins/Test-AssetsPath!;

=== Test plugin:assets_path
--- input config
global:
  assets_path: /tmp/assets
plugins:
  - module: Test::AssetsPath
    config:
      assets_path: $t::TestPlagger::BaseDir/t/samples
--- expected
unlike $warning, qr!/tmp/assets!;
like $warning, qr!assets_path is .*t/samples$!m;

=== Test templatize
--- input config
global:
  assets_path: $t::TestPlagger::BaseDir/t/assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Test::AssetsPath
--- expected
like $warning, qr/template: foo/;

=== Test localized templatize
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Test::AssetsPath
    config:
      assets_path: $t::TestPlagger::BaseDir/t/samples
--- expected
like $warning, qr/template: bar/;
