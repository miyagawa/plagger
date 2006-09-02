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

=== log level is debug
--- input config
global:
  log:
    level: debug
plugins:
  - module: Test::Log
--- expected
like $warnings, qr/error/;
like $warnings, qr/info/;
like $warnings, qr/warn/;
like $warnings, qr/debug/;

=== info log level
--- input config
global:
  log:
    level: info
plugins:
  - module: Test::Log
--- expected
like $warnings, qr/error/;
like $warnings, qr/info/;
unlike $warnings, qr/warn/;
unlike $warnings, qr/debug/;
