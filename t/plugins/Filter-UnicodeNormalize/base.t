use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::UnicodeNormalize
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Normalize
      entry:
        - title: TEL
          body: ℡
        - title: (d)
          body: ⒟
        - title: GHz
          body: ㎓
        - title: TM
          body: ™
        - title: VII
          body: Ⅶ
        - title: (2)
          body: ⑵
        - title: 1
          body: ①
  - module: Filter::UnicodeNormalize
    config:
      form: NFKC
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->body, 'TEL';
is $context->update->feeds->[0]->entries->[1]->body, '(d)';
is $context->update->feeds->[0]->entries->[2]->body, 'GHz';
is $context->update->feeds->[0]->entries->[3]->body, 'TM';
is $context->update->feeds->[0]->entries->[4]->body, 'VII';
is $context->update->feeds->[0]->entries->[5]->body, '(2)';
is $context->update->feeds->[0]->entries->[6]->body, '1';	
