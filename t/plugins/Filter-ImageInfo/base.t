use strict;
use t::TestPlagger;

test_requires_network 'plagger.org:80';
test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::ImageInfo
--- input config
plugins:
  - module: Filter::ImageInfo
--- expected
ok 1, $block->name;

=== Feed logo
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      image: 
        url: http://plagger.org/plagger_header.png
      entry:
        - title: test entry
          link: http://www.example.com
          body: this entry is test.
  - module: Filter::ImageInfo
--- expected
is $context->update->feeds->[0]->image->{width}, "236";
is $context->update->feeds->[0]->image->{height}, "73";

=== Entry icon
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: test entry
          link: http://www.example.com
          body: this entry is test.
          icon: 
            url: http://plagger.org/plagger_header.png
  - module: Filter::ImageInfo
--- expected
is $context->update->feeds->[0]->entries->[0]->icon->{width}, "236";
is $context->update->feeds->[0]->entries->[0]->icon->{height}, "73";
