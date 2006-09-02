use t::TestPlagger;

test_requires_network 'commonground.mines.edu';
test_plugin_deps('Filter-EntryFullText', 1);
plan 'no_plan';
run_eval_expected;

__END__

=== Test printenv
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: printenv
      entry:
        - title: printenv
          link: http://commonground.mines.edu/printenv.cgi
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr!ACCEPT_LANGUAGE!;

=== Test printenv with Accept-Language: ja
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: printenv
      entry:
        - title: printenv
          link: http://commonground.mines.edu/printenv.cgi
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
  - module: UserAgent::RequestHeader
    config:
      Accept-Language: ja
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!<TD>HTTP_ACCEPT_LANGUAGE</TD><TD>ja</TD>!;

=== Test printenv with Accept-Language: ja and rule
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: printenv
      entry:
        - title: printenv
          link: http://commonground.mines.edu/printenv.cgi
  - module: Filter::EntryFullText
    config:
      store_html_on_failure: 1
  - module: UserAgent::RequestHeader
    config:
      Accept-Language: ja
    rule:
      expression: \$args->{url}->host eq 'commonground.mines.edu'
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr!<TD>HTTP_ACCEPT_LANGUAGE</TD><TD>ja</TD>!
