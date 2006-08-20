use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires 'Data::Dumper';

{
    no warnings qw/redefine prototype once/;
    *Mac::Growl::PostNotification = sub {
        warn Data::Dumper::Dumper join ':', @_;   
    }; 
}

plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Call Growl test
--- input config
global:
  log:
    level: debug
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Notify::Growl
--- expected
my @count = $warning =~ /^\$VAR1 = 'plagger:/gm;
is scalar @count, 4;

like $warning, qr{\$VAR1 = 'plagger:Liftoff News:Star City:How do Americans }m;
like $warning, qr{\$VAR1 = 'plagger:Liftoff News:The Engine That Does More:B}m;
