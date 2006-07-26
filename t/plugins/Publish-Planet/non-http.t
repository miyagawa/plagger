use strict;
use FindBin;
use t::TestPlagger;

our $output = "$FindBin::Bin/index.html";

plan tests => 2;
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== generator testing
--- input config output_file
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/non-http-link.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
--- expected
my $content = $block->input;
like $content, qr!http://foo.example.com/!;
unlike $content, qr!bar.example.com!;


