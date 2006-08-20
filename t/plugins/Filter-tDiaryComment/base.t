use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::tDiaryComment
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tdiary.rdf
  - module: Filter::tDiaryComment

--- expected
ok 1, $block->name;
is scalar(grep {$_->link =~ /\.html#c\d+$/} $context->update->feeds->[0]->entries), 0;


