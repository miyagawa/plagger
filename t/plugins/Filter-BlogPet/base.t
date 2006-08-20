use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::BlogPet
--- input config
plugins:
  - module: Filter::BlogPet
--- expected
ok 1, $block->name;

=== Filtering entry by BlogPet
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Title
      link: http://example.com/
      entry:
        - title: BlogPetによるエントリのタイトルは(BlogPet)で終わります
          link: htp://example.com/1
        - title: test
          link: http://example.com/2
        - title: 投稿のテスト(BlogPet)
          link: http://example.com/3
  - module: Filter::BlogPet
--- expected
ok !grep { $_->{title} =~ /BlogPet$/ } $context->update->feeds->[0]->entries;
is 2, scalar @{ $context->update->feeds->[0]->entries };
