use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected_with_capture;

package Plagger::Plugin::Test::Log;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $self->log(error => "this is error");
    $self->log(info  => "this is info");
    $self->log(warn  => "this is warn");
    $self->log(debug => "this is debug");
}

package main;

__END__

=== default log level is debug
--- input config
plugins:
  - module: Test::Log
--- expected
like $warning, qr/error/;
like $warning, qr/info/;
like $warning, qr/warn/;
like $warning, qr/debug/;

=== info log level
--- input config
global:
  log:
    level: info
plugins:
  - module: Test::Log
--- expected
like $warning, qr/error/;
like $warning, qr/info/;
unlike $warning, qr/warn/;
unlike $warning, qr/debug/;
