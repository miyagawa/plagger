use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

test_plugin_deps;
test_requires_network;

my $rpc;

no warnings 'redefine', 'once';
local *XMLRPC::Lite::call = sub {
    my($self, $method, $name, $url) = @_;
    $rpc = {
        method => $method,
        name   => $name,
        url    => $url,
    };
};

sub rpc { $rpc }

plan tests => 3;
run_eval_expected;

__END__

=== Test 1
--- input config rpc
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.bulknews.net/mt/
  - module: Notify::UpdatePing
    config:
      url: http://localhost/ping
--- expected
my $rpc = $block->input;
is $rpc->{method}, 'weblogUpdates.ping';
is $rpc->{name}->value, 'blog.bulknews.net';
is $rpc->{url}, 'http://blog.bulknews.net/mt/';


