use strict;
use FindBin;
use t::TestPlagger;

test_requires_network 'www.zshare.net:80';

plan tests => 2;
run_eval_expected;

__END__

=== Test 1
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - title: Test 1
          link: http://buycheapviagraonlinenow.com/1
          body: |
            Here's a link to zShare. <a href="http://www.zshare.net/download/4385403840872c/">test</a>
        - title: Test 2
          link: http://buycheapviagraonlinenow.com/2
          body: |
            Here's a link to zShare. <a href="http://www.zshare.net/audio/4385403840872c/">test</a>

  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://upsilon.zshare.net/download/[0-9a-f]+/[0-9]+/4385403/test.txt!;
like $context->update->feeds->[0]->entries->[1]->enclosure->url, qr!http://upsilon.zshare.net/download/[0-9a-f]+/[0-9]+/4385403/test.txt!;
