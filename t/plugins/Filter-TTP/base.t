use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::TTP
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          body: ttp://www.example.net
  - module: Filter::TTP
--- expected
is $context->update->feeds->[0]->entries->[0]->body, "<a href=\"http://www.example.net\">ttp://www.example.net</a>"
