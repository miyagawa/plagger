use strict;
use t::TestPlagger;

our $url    = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
our $output = $FindBin::Bin . "/" . Digest::MD5::md5_hex($url) . ".yaml";

test_requires('YAML::Syck');
test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== Save with YAML
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::Serializer
    config:
      dir: $FindBin::Bin
      serializer: YAML
      filename: %i.yaml
--- expected
use YAML::Syck;
my $data = YAML::Syck::LoadFile($main::output);
ok $data;
is $data->{title}, 'Bulknews::Subtech';
