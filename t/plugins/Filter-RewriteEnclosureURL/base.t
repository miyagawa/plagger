use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::RewriteEnclosureURL
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      link: 'http://www.example.org/'
      entry:
        # fetched enclosure
        - title: bar
          link: 'http://www.example.org/1'
          enclosure:
            - url: http://www.example.org/movie1.flv
              filename: movie1.flv
              type: video/x-flv
              local_path: /home/plagger/public_html/movie1.flv

        # not fetched enclosure
        - title: bar
          link: 'http://www.example.org/2'
          enclosure:
            - url: http://www.example.org/movie2.flv
              filename: movie2.flv
              type: video/x-flv
        
        # local_path does not match 
        - title: bar
          link: 'http://www.example.org/3'
          enclosure:
            - url: http://www.example.org/movie3.flv
              filename: movie3.flv
              type: video/x-flv
              local_path: /home/hogefuga/public_html/movie3.flv

  - module: Filter::RewriteEnclosureURL
    config:
      rewrite:
        - local: /home/plagger/public_html/
          url: http://localhost/~plagger/
      
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->enclosures->[0]->url, 'http://localhost/~plagger/movie1.flv', 'enclosure fetched';
is $context->update->feeds->[0]->entries->[1]->enclosures->[0]->url, 'http://www.example.org/movie2.flv', 'enclosure not fetched';
is $context->update->feeds->[0]->entries->[2]->enclosures->[0]->url, 'http://www.example.org/movie3.flv', 'local_path does not match';
