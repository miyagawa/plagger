use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;

filters 'chomp';
filters { input => [ 'make_config', 'config', 'body', ] };
filters_delay;

my $tidy_config;

sub make_config {
    my $config = <<CONF;
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Blah
          body: $_[0]
  - module: Filter::HTMLTidy
    config:
CONF
    if ($tidy_config) {
        $tidy_config =~ s/^/      /gm; # indent
        $config .= $tidy_config . "\n";
    }

    $config;
}

sub body { $_[0]->update->feeds->[0]->entries->[0]->body->data }

plan tests => 1 * blocks;

for my $block (blocks) {
    $tidy_config = $block->config;
    $block->run_filters;
    is $block->input, $block->expected, $block->name;
};

__END__

=== Default
--- input
<p>Hello World</p>
--- expected
<p>Hello World</p>

=== Text
--- input
This is a text, not HTML.
--- expected
This is a text, not HTML.

=== Complex HTML
--- input
<p><div>fooo <br><font face="foo">foo</div></p><div><hr>foo<i>bar</i><p>aaa
--- expected
<div>fooo<br />
<font face="foo">foo</font></div>
<div>
<hr />
foo<i>bar</i>
<p>aaa</p>
</div>

=== html2xhtml
--- input
<p>foo<br>bar</p>
--- expected
<p>foo<br />
bar</p>

=== HTML chars
--- input
<p>You &amp; I</p>
--- expected
<p>You &amp; I</p>

=== HTML special chars
--- input
<p>You &nbsp; I</p>
--- expected
<p>You &nbsp; I</p>

=== HTML special chars
--- input
<p>You &aring; I</p>
--- expected
<p>You å I</p>

=== UTF-8
--- input
<p>日本語のテスト <img src="foo.jpg" alt="顔"></p>
--- expected
<p>日本語のテスト <img src="foo.jpg" alt="顔" /></p>

=== UTF-8 with HTML special chars
--- input
<p>日本語のテスト &aring;</p>
--- expected
<p>日本語のテスト å</p>


