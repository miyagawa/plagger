use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

our $output = "$FindBin::Bin/index.html";

test_plugin_deps;
run_like 'input', 'expected';

END {
    unlink $output if -e $output;
}

__END__

=== generator testing
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
--- expected chomp regexp
<meta name="generator" content="Plagger [\d\.]+"

=== Testing styles
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
      template:
        style_url: /foo.css

--- expected chomp regexp
<link rel="stylesheet" type="text/css" href="/foo.css" />

=== Testing skin (backward compatiblity)
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      skin: sixapart-std
      template:
        style_url: /foo.css

--- expected chomp regexp
<link rel="stylesheet" type="text/css" href="/foo.css" />

=== Testing styles (backward compatibility)
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
      template:
        style_url: /foo.css

--- expected chomp regexp
<link rel="stylesheet" type="text/css" href="/foo.css" />

=== Testing styles with 2 CSSes
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
      template:
        style_url:
          - /foo.css
          - /bar.css

--- expected chomp regexp
<link rel="stylesheet" type="text/css" href="/foo.css" />\s*<link rel="stylesheet" type="text/css" href="/bar.css" />

=== Testing styles with base URLs
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
      template:
        url:
          base: http://example.org/planet/
        style_url:
          - foo.css
          - /bar.css
          - http://ext.example.com/bar.css
--- expected chomp regexp
<link rel="stylesheet" type="text/css" href="http://example.org/planet/foo.css" />\s*<link rel="stylesheet" type="text/css" href="http://example.org/bar.css" />\s*<link rel="stylesheet" type="text/css" href="http://ext.example.com/bar.css" />

=== Testing widgets
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/delicious.xml
  - module: Widget::Delicious
    config:
      username: miyagawa
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std

--- expected chomp regexp
del\.icio\.us/static/img
