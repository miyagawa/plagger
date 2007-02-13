use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';

__END__

=== test file
--- input config 
plugins:
	- module: Notify::Colloquy
  	config:
    	channels: 
				- #tirnanog
				- #plagger
  		charset: iso-8859-1