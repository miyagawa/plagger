use strict;
use FindBin;
use t::TestPlagger;

test_requires_network 'www.zshare.net:80';

plan tests => 3;
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
            Here's a link to zShare. <a href="http://www.zshare.net/download/52199786e5e37595/">test</a>
        - title: Test 2
          link: http://buycheapviagraonlinenow.com/2
          body: |
            Here's a link to zShare. <a href="http://www.zshare.net/audio/52199786e5e37595/">test</a>
        - title: Test 3
          link: http://buycheapviagraonlinenow.com/3
          body: |
            Here's a link to ShareBee. <a href="http://sharebee.com/786015ba">test</a>

  - module: Filter::FindEnclosures
--- expected
like $context->update->feeds->[0]->entries->[0]->enclosure->url, qr!http://[\d\w]+\.zshare\.net/download/[0-9a-f]+/\d+/\d+/test.txt!;
like $context->update->feeds->[0]->entries->[1]->enclosure->url, qr!http://[\d\w]+\.zshare\.net/download/[0-9a-f]+/\d+/\d+/test.txt!;
like $context->update->feeds->[0]->entries->[2]->enclosure->url, qr!http://[\d\w]+\.zshare\.net/download/[0-9a-f]+/\d+/\d+/test.txt!;
