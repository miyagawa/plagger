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

=== Use del.icio.us asset
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      widget: delicious
--- expected chomp
<a href="http://del.icio.us/post?title=+%E3%82%BF%E3%82%A4%E3%83%97%E6%95%B0%E3%82%AB%E3%82%A6%E3%83%B3%E3%82%BF%E3%83%BC%E3%82%92%E3%83%93%E3%82%B8%E3%83%A5%E3%82%A2%E3%83%AB%E8%A1%A8%E7%A4%BA&amp;url=http%3A%2F%2Fsubtech.g.hatena.ne.jp%2Fmiyagawa%2F20060710%2F1152534733"><img src="http://del.icio.us/static/img/delicious.small.gif" alt="del.icio.us it!" style="border:0;vertical-align:middle" /></a>

=== Use Hatena Bookmark asset
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      widget: hatena_bookmark
--- expected chomp
<a href="http://b.hatena.ne.jp/append?http://subtech.g.hatena.ne.jp/miyagawa/20060710/1152534733"><img src="http://b.hatena.ne.jp/images/append.gif" alt="Post to Hatena Bookmark" style="border:0;vertical-align:middle" /></a>

=== Use Hatena Bookmark count asset
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
  - module: Widget::Simple
    config:
      widget: hatena_bookmark_users
--- expected chomp
<a href="http://b.hatena.ne.jp/entry/http://subtech.g.hatena.ne.jp/miyagawa/20060710/1152534733"><img src="http://b.hatena.ne.jp/entry/image/normal/http://subtech.g.hatena.ne.jp/miyagawa/20060710/1152534733" style="border:0;vertical-align:middle" /></a>
