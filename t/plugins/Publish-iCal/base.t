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
is $ical->entries->[0]->property('dtstart')->[0]->value, "20060710T123213Z";
is $ical->entries->[0]->property('dtend')->[0]->value, "20060710T123213Z";

=== Full day event
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

=== Timezone UTC
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar Calendar
      entry:
        - date: 2006/10/20 12:34:56 UTC
          title: Shibuya.pm Tech Talks
  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is $ical->entries->[0]->property('dtstart')->[0]->value, "20061020T123456Z";

=== floating TZ
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar Calendar
      entry:
        - date: 2006/10/20 12:34:56
          title: Shibuya.pm Tech Talks
  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is $ical->entries->[0]->property('dtstart')->[0]->value, "20061020T123456";
is_deeply $ical->entries->[0]->property('dtstart')->[0]->parameters, {};

=== TZ without names (JST is converted +0900 on its way)
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar Calendar
      entry:
        - date: 2006/10/20 12:34:56 JST
          title: Shibuya.pm Tech Talks
  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is $ical->entries->[0]->property('dtstart')->[0]->value, "20061020T033456Z";
is_deeply $ical->entries->[0]->property('dtstart')->[0]->parameters, {};

=== Fixed TimeZone
--- input config
global:
  timezone: Asia/Tokyo
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar Calendar
      entry:
        - date: 2006/10/20 12:34:56
          title: Shibuya.pm Tech Talks
  - module: Filter::FloatingDateTime
  - module: Publish::iCal
    config:
      dir: $FindBin::Bin
      filename: $::filename
--- expected
ok -e $::output;
my $ical = Data::ICal->new(filename => $::output);
is $ical->entries->[0]->property('dtstart')->[0]->value, "20061020T123456";
is_deeply $ical->entries->[0]->property('dtstart')->[0]->parameters, { TZID => 'Asia/Tokyo' };
