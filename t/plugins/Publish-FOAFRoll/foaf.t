use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

test_requires('XML::FOAF');
test_requires_network;

our $output = "$FindBin::Bin/foafroll.rdf";

plan 'no_plan';
run_eval_expected;

END {
    unlink $output if defined $output && -e $output;
}

__END__

=== FOAF roll
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.bulknews.net/mt/index.rdf
        - http://subtech.g.hatena.ne.jp/miyagawa/rss
  - module: Publish::FOAFRoll
    config:
      filename: $main::output
      url: http://example.org/foo.rdf
      link: http://example.org/
--- expected
my $content = slurp_file($main::output);
my $foaf = XML::FOAF->new(\$content, "http://example.com/",);
is $foaf->person->name, 'miyagawa';
is $foaf->person->weblog, 'http://blog.bulknews.net/mt/';

like $content, qr!<foaf:homepage>http://example.org/</foaf:homepage>!;
like $content, qr!<rdfs:seeAlso rdf:resource="http://example.org/foo.rdf" />!;

