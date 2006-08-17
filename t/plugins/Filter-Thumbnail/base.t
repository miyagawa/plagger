use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Thumbnail
--- input config
plugins:
  - module: Filter::Thumbnail
--- expected
ok 1, $block->name;

=== Feed logo
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Filter::Thumbnail
--- expected
is $context->update->feeds->[0]->image->{url}, "http://img.simpleapi.net/small/http://subtech.g.hatena.ne.jp/miyagawa/";
ok !$context->update->feeds->[0]->entries->[0]->icon;

=== Per entry
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Filter::Thumbnail
    config:
      set_per_entry: 1
--- expected
is $context->update->feeds->[0]->image->{url}, "http://img.simpleapi.net/small/http://subtech.g.hatena.ne.jp/miyagawa/";
is $context->update->feeds->[0]->entries->[0]->icon->{url}, "http://img.simpleapi.net/small/http://subtech.g.hatena.ne.jp/miyagawa/20060710/1152534733";



