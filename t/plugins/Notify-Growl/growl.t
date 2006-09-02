use strict;
use t::TestPlagger;

test_plugin_deps;

{
    no warnings qw/redefine prototype once/;
    
    my $growl_post = \&Mac::Growl::PostNotification;
    *Mac::Growl::PostNotification = sub {
        $growl_post->(@_);
        warn "Growl: " . join ':', @_, "\n";
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
my @count = $warnings =~ /^Growl: plagger:/gm;
is scalar @count, 4;

like $warnings, qr{^Growl: plagger:Liftoff News:Star City:How do Americans }m;
like $warnings, qr{^Growl: plagger:Liftoff News:The Engine That Does More:B}m;
