use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== link to mp3
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Foo
          link: http://www.perlcast.com/audio/Perlcast_015.mp3
  - module: Filter::TruePermalink
--- expected
is $context->update->feeds->[0]->entries->[0]->permalink, "http://www.perlcast.com/audio/Perlcast_015.mp3";

