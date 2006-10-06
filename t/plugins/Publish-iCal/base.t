use strict;
use t::TestPlagger;

our $filename = "foo.ics";
our $output = File::Spec->catfile($FindBin::Bin, $filename);

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== 
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml

  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is @{$ical->entries}, 5;
is $ical->entries->[0]->property('dtstart')->[0]->value, "20060710T213213";
is $ical->entries->[0]->property('dtend')->[0]->value, "20060710T223213";

=== Full day event
--- ONLY
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar Calendar
      entry:
        - date: 2006/10/20
          title: Shibuya.pm Tech Talks
        - date: 2006/10/22
          title: Shibuya.pm Tech Talks
  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is @{$ical->entries}, 2;
is $ical->entries->[0]->property('dtstart')->[0]->value, "20061020";
is_deeply $ical->entries->[0]->property('dtstart')->[0]->parameters, { VALUE => 'DATE' };

