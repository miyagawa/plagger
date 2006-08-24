use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== redirect
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      link: http://localhost/
      entry:
        - title: bar
          link: http://gimite.ddo.jp/rotd/click.rb?hid=tbcl&id=tag:hatena.ne.jp,2005-2006:bookmark-miyagawa-2605184&url=http://subtech.g.hatena.ne.jp/miyagawa/20060823/1156317748
        - title: baz
          link: http://xrl.us/q54v
  - module: Filter::TruePermalink
--- expected
unlike $context->update->feeds->[0]->entries->[0]->permalink, qr/click\.rb/;
like $context->update->feeds->[0]->entries->[0]->permalink, qr/subtech/;
unlike $context->update->feeds->[0]->entries->[0]->permalink, qr/xrl\.us/;
like $context->update->feeds->[0]->entries->[0]->permalink, qr/subtech/;
