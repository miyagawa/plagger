use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';

sub feed {
    return <<CONF;
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Bar
          body: $_[0]
CONF
}

sub summary {
    my $context = shift;
    return $context->update->feeds->[0]->entries->[0]->summary->data;
}

filters { input => [ 'chomp', 'feed', 'config', 'summary' ], expected => 'chomp' };
run_is 'input' => 'expected';

__END__

=== Plain text
--- input
Foo Bar
--- expected
Foo Bar

=== Plain text with HTML
--- input
Foo &amp; Bar
--- expected
Foo &amp; Bar

=== Long plain text stripped with 255
--- input
Hello1 Hello2 Hello3 Hello4 Hello5 Hello6 Hello7 Hello8 Hello9 Hello10 Hello11 Hello12 Hello13 Hello14 Hello15 Hello16 Hello17 Hello18 Hello19 Hello20 Hello21 Hello22 Hello23 Hello24 Hello25 Hello26 Hello27 Hello28 Hello29 Hello30 Hello31 Hello32 Hello33 Hello34 Hello35 Hello36 Hello37 Hello38 Hello39 Hello40 Hello41 Hello42 Hello43 Hello44 Hello45 Hello46 Hello47 Hello48 Hello49 Hello50
--- expected
Hello1 Hello2 Hello3 Hello4 Hello5 Hello6 Hello7 Hello8 Hello9 Hello10 Hello11 Hello12 Hello13 Hello14 Hello15 Hello16 Hello17 Hello18 Hello19 Hello20 Hello21 Hello22 Hello23 Hello24 Hello25 Hello26 Hello27 Hello28 Hello29 Hello30 Hello31 Hello32 Hello33 ...

=== Grab first <p> tag
--- input
<p>Foo Bar</p><p>Bar Baz</p>
--- expected
<p>Foo Bar</p>

=== Grab first <blockquote> tag
--- input
<blockquote>Foo Bar</blockquote><p>Bar Baz</p>
--- expected
<blockquote>Foo Bar</blockquote>

=== Grab first <br>
--- input
Foo Bar Baz<br>\nBazz
--- expected
Foo Bar Baz

=== Grab first <br />
--- input
Foo Bar Baz<br />\nBazz
--- expected
Foo Bar Baz

=== Deal with <div>. nasty hack
--- input
<div class="foo"><p>First paragraph</p><p>Second paragraph</p></div>
--- expected
<p>First paragraph</p>

=== Deal with <div>. nasty hack
--- input
"<div class=\"foo\">\n<p>First paragraph</p><p>Second paragraph</p></div>"
--- expected
<p>First paragraph</p>
