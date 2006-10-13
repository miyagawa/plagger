use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::Auto
--- input config
plugins:
  - module: Summary::Auto
--- expected
ok 1, $block->name;

=== RSS feed with <description>
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Summary::Auto
--- expected
for my $entry ($context->update->feeds->[0]->entries) {
    ok $entry->summary;
    isnt $entry->summary->data, $entry->body->data;
}

=== Atom feed without <summary>
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/vox.xml
  - module: Summary::Auto
--- expected
for my $entry ($context->update->feeds->[0]->entries) {
    ok $entry->summary;
    isnt $entry->summary->data, $entry->body->data unless $entry->body =~ /ECW/;
}

=== Summary auto is now core
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/vox.xml
--- expected
for my $entry ($context->update->feeds->[0]->entries) {
    ok $entry->summary;
    isnt $entry->summary->data, $entry->body->data unless $entry->body =~ /ECW/;
}
