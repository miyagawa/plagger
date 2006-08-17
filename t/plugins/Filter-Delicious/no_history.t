use t::TestPlagger;

test_plugin_deps;
test_requires_network 'del.icio.us:80';

use Digest::MD5 qw(md5_hex);

our $rand = md5_hex($$ . {} . time . rand(100000));

plan 'no_plan';
run_eval_expected;

__END__

=== Test no_history
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: no del.icio.us history
      entry:
        - title: no del.icio.us history
          link: http://del.icio.us/url?url=http%3A%2F%2Ftestplagger.example/$main::rand
  - module: Filter::Delicious
--- expected
is $context->update->feeds->[0]->entries->[0]->meta->{delicious_users}, 0;
is $context->update->feeds->[0]->entries->[0]->meta->{delicious_rate}, 100;
