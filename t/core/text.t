use t::TestPlagger;

test_requires('HTML::FormatText');
test_requires('HTML::TreeBuilder');

plan tests => 1 * blocks;
filters { input => 'chomp', expected => 'yaml' };

run {
    my $block = shift;
    my $text = Plagger::Text->new_from_text($block->input);
    my $test = { type => $text->type, plaintext => $text->plaintext, html => $text->html };
    is_deeply $test, $block->expected, $block->name;
}

__END__

=== Plain text
--- input
Hello World
--- expected
type: text
plaintext: Hello World
html: Hello World

=== &amp;
--- input
Hello &amp; World
--- expected
type: html
plaintext: Hello & World
html: Hello &amp; World

=== &
--- input
"The Big & Small"
--- expected
type: text
plaintext: '"The Big & Small"'
html: "&quot;The Big &amp; Small&quot;"

=== quot;
--- input
Foo &quot;baz&quot;
--- expected
type: html
plaintext: Foo "baz"
html: Foo &quot;baz&quot;

=== Tags
--- input
<p>Hello World</p>
--- expected
type: html
plaintext: Hello World
html: <p>Hello World</p>

=== XHTML
--- input
Hello <br /> World
--- expected
type: html
plaintext: "Hello\nWorld"
html: Hello <br /> World

=== <wbr>
--- input
Hello <wbr> World
--- expected
type: html
plaintext: Hello World
html: Hello <wbr> World

=== Unknown Tags
--- input
<foo>Hello</foo>
--- expected
type: text
plaintext: <foo>Hello</foo>
html: "&lt;foo&gt;Hello&lt;/foo&gt;"

=== Unknown Tags ... but lots of known tags
--- input
<p>Foo Bar <foo /></p>
--- expected
type: html
plaintext: Foo Bar
html: <p>Foo Bar <foo /></p>


