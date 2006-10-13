use utf8;
use t::TestPlagger;
use Plagger::Util;

test_requires('HTML::FormatText');
test_requires('HTML::TreeBuilder');
plan 'no_plan';

filters { input => 'chomp', expected => [ 'chomp', 'regexp' ] };

run {
    my $block = shift;
    like Plagger::Util::strip_html($block->input), $block->expected, $block->name;
}

__END__

=== Text
--- input
Hello World
--- expected
Hello World

=== amps
--- input
Hello &amp; World
--- expected
Hello & World

=== <p>
--- input
<p>Hello &amp; World</p>
--- expected
Hello & World

=== <br />
--- input
Hello<br />World
--- expected
Hello
World

=== Japanese
--- input
プラガー
--- expected
プラガー

=== Tags
--- input
Foo <b>bar</b> Baz
--- expected
Foo bar Baz

=== P Tags
--- input
<p>Foo</p><p>Bar</p>
--- expected
Foo\n*Bar

=== blockquote
--- input
<blockquote>Foo</blockquote><p>foo</p>
--- expected
\s+Foo\n*foo

=== IMG alt
--- input
This is <img src="/foo.gif" alt="image" />.
--- expected
This is image\.
