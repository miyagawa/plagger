use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== oreilly
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Make
      link: http://www.makezine.com/
      entry:
        - title: Foo
          link: http://www.makezine.com/blog/archive/2006/08/usb_bbq.html?CMP=OTC-0D6B48984890
  - module: Filter::TruePermalink
--- expected
unlike $context->update->feeds->[0]->entries->[0]->permalink, qr/CMP=/;
