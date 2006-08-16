use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';

run {
    my $block = shift;
    my $context = $block->input;
    no warnings 'redefine';
    local *Plagger::context = sub { $context }; # xxx
    my $entry = $context->update->feeds->[0]->entries->[0];
    is $entry->widgets->[0]->html($entry), $block->expected, $block->name;
}

__END__

=== static config
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      link: http://www.example.com/
      content: Hello World
--- expected chomp
<a href="http://www.example.com/">Hello World</a>

=== add query
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      link: http://www.example.com/add
      query:
        url: \$args->{entry}->link
        ver: 4
      content: Hello World
--- expected chomp
<a href="http://www.example.com/add?url=http%3A%2F%2Fsubtech.g.hatena.ne.jp%2Fmiyagawa%2F20060710%2F1152534733&amp;ver=4">Hello World</a>

=== dynamic content
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      link: http://www.example.com/
      content_dynamic: "Entry from [% entry.author | html %]"
--- expected chomp
<a href="http://www.example.com/">Entry from miyagawa</a>

