use strict;
use t::TestPlagger;
use Plagger::Feed;

plan 'no_plan';

# hack Plagger::Date parse
no warnings 'redefine';
*Plagger::context = sub { bless { conf => {} }, 'Plagger::Context' };
sub Plagger::Context::conf { $_[0]->{conf} }

run {
    my $block = shift;

    my $smart_feed = Plagger::Feed->new;

    for my $data (@{ $block->input }) {
        my $feed = Plagger::Feed->new;
        $feed->link($data->{feed}->{link});
        my $entry = Plagger::Entry->new;
        $entry->link($data->{entry}->{link});
        $entry->date($data->{entry}->{date}) if $data->{entry}->{date};
        $entry->body($data->{entry}->{body}) if $data->{entry}->{body};
        $entry->source($feed);
        $smart_feed->add_entry($entry);
    }

    $smart_feed->dedupe_entries;
    is $smart_feed->entries->[0]->source->link, $block->expected, $block->comment;
}

__END__

=== Domain based check
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
- feed:
    link: http://example.org/
  entry:
    link: http://example.org/1.html

--- expected chomp
http://example.org/

=== Date based check
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
    date: 2006/08/07 00:00:00
- feed:
    link: http://example.com/search?q=bar
  entry:
    link: http://example.org/1.html
    date: 2006/07/07 00:00:00
--- expected chomp
http://example.com/search?q=bar

=== Date vs. without date
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
- feed:
    link: http://example.com/search?q=bar
  entry:
    link: http://example.org/1.html
    date: 2006/07/07 00:00:00
--- expected chomp
http://example.com/search?q=bar

=== Full content
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
- feed:
    link: http://example.com/search?q=bar
  entry:
    link: http://example.org/1.html
    body: foo bar
--- expected chomp
http://example.com/search?q=bar

=== Date > full content
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
    date: 2006/07/09 00:00:00
- feed:
    link: http://example.com/search?q=bar
  entry:
    link: http://example.org/1.html
    content: foo bar
    date: 2006/07/08 00:00:00
- feed:
    link: http://example.com/search?q=xxx
  entry:
    link: http://example.org/1.html
    date: 2006/07/05 00:00:00
--- expected chomp
http://example.com/search?q=xxx

=== Domain match is always the 1st priority
--- input yaml
- feed:
    link: http://example.com/search?q=foo
  entry:
    link: http://example.org/1.html
    date: 2006/08/07 00:00:00
- feed:
    link: http://example.com/search?q=bar
  entry:
    link: http://example.org/1.html
    date: 2006/07/07 00:00:00
- feed:
    link: http://example.org/
  entry:
    link: http://example.org/1.html
    date: 2006/07/09 00:00:00
--- expected chomp
http://example.org/

