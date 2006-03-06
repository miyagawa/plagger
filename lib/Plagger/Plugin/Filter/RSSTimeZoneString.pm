package Plagger::Plugin::Filter::RSSTimeZoneString;
use strict;
use base qw( Plagger::Plugin );

my %tz = qw(
  SET     +0100   CET     +0100   MEZ     +0100   MEWT    +0100
  MET     +0100   BST     +0100   FWT     +0100   ECT     +0100
  SWT     +0100   FST     +0200   MEST    +0200   UKR     +0200
  CEST    +0200   EET     +0200   SST     +0200   EEST    +0300
  BT      +0300   ZP4     +0400   ZP5     +0500   ZP6     +0600
  HKT     +0800   WST     +0800   WADT    +0800   CCT     +0800
  KST     +0900   JST     +0900   KDT     +1000   EAST    +1000
  GST     +1000   EADT    +1100   IDLE    +1200   NZST    +1200
  NZT     +1200   NZD     +1300   NZDT    +1300   WET     -0000
  WAT     -0100   AT      -0200   FNT     -0200   BRST    -0200
  BRT     -0300   ADT     -0300   EWT     -0400   MNT     -0400
  AST     -0400   ACT     -0500   YDT     -0800   YST     -0900
  HDT     -0900   HST     -1000   CAT     -1000   AHST    -1000
  NT      -1100   IDLW    -1200
);

my $tz_RE   = join '|', keys %tz;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.filter.feed' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    while ($args->{content} =~ s!($tz_RE)</(pubDate|lastBuildDate)>!$tz{$1}</$2>!) {
        $context->log(info => "Fixed bad timezone $1 to $tz{$1}");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::RSSTimeZoneString - Fix bad RFC822 timezone string in RSS 2.0

=head1 SYNOPSIS

  - module: Filter::RSSTimeZoneString

=head1 DESCRIPTION

This plugin fixes a bad timezone string in pubDate of RSS 2.0 (or
0.91) feeds to a correct one.

Namely, when you create RSS feeds with POSIX C<strftime> function for
example, it'll create a following pubDate format if you're on the box
under Japanese standard time:

  Fri, 03 Mar 2006 03:52:42 JST

which is invalid in RFC 822. (RFC 822 only allows timezone strings for
North America, like PST and CST).

This plugin fixes the string to:

  Fri, 03 Mar 2006 03:52:42 +0900

and the correct one is re-parsed and set to C<< $entry->date >>.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<DateTime::Format::Mail>, L<Time::Zone>

=cut
