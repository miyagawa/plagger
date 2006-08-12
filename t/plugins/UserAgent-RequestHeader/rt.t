use t::TestPlagger;
use utf8;

test_plugin_deps('Filter-EntryFullText', 1);
plan 'no_plan';
run_eval_expected;

__END__

=== Test rt.cpan.org
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: RT CPAN
      entry:
        - title: rt.cpan.org
          link: http://rt.cpan.org/
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!<span class="left">Login</span>!;

=== Test rt.cpan.org with Accept-Language: ja
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: RT CPAN
      entry:
        - title: rt.cpan.org
          link: http://rt.cpan.org/
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
  - module: UserAgent::RequestHeader
    config:
      Accept-Language: ja
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!<span class="left">ログイン</span>!;

=== Test rt.cpan.org with Accept-Language: ja and rule
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: RT CPAN
      entry:
        - title: rt.cpan.org
          link: http://rt.cpan.org/
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
  - module: UserAgent::RequestHeader
    config:
      Accept-Language: ja
    rule:
      expression: \$args->{url}->host eq 'rt.cpan.org'
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!<span class="left">ログイン</span>!;
