use strict;
use t::TestPlagger;
use XMLRPC::Lite;

my $server = 'localhost:8081';

test_plugin_deps;
test_requires_network($server);

# connect to network to make sure localhost:8081 is actually POPFile server.
eval {
  my $xmlrpc = XMLRPC::Lite->proxy("http://$server/RPC2") or die;

  my $sk = $xmlrpc->call('POPFile/API.get_session_key', 'admin', '')->result;
  die 'no session key' unless $sk;

  $xmlrpc->call('POPFile/API.release_session_key', $sk);
};
plan skip_all => "This test requires POPFile XMLRPC server at $server" if $@;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::POPFile
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
  - module: Filter::POPFile
    config:
      proxy: http://localhost:8081/RPC2
      training: 0
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0] ne 'spam';
