#!/usr/bin/perl -w
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use Encode;
use LWP::Simple ();
use YAML;

my @url = ("http://www.wowow.co.jp/hivision/list_hv.html",
	   "http://www.wowow.co.jp/hivision/list_51.html");

my %seen;
my @programs = grep { !$seen{"$_->{channel}|$_->{date}"}++ }
    sort { $a->{date} cmp $b->{date} }
    map fetch_program($_), @url;

binmode STDOUT, ":utf8";
print YAML::Dump +{
    title => 'WOWOW HV / 5.1ch programs',
    link  => "http://www.wowow.co.jp/hivision/indexh.html",
    entry => [
        map {
            my @tags = ($_->{channel});
            push @tags, 'HV'    if $_->{hivision};
            push @tags, '5.1ch' if $_->{51};
            +{ title => $_->{title},
               date  => $_->{date},
               tags  => \@tags,
               link  => $_->{link} }
        } @programs,
    ],
};

sub fetch_program {
    my $url = shift;
    my $html = LWP::Simple::get($url);
    $html = decode("shift_jis", $html);
    $html =~ tr/\r//d;
    my $re = <<'RE';
<tr bgcolor="#(?:CCCCCC|FFFFCC)"> 
  <td width="385"><span class="t12"><a href="(http://www\.wowow\.co\.jp/schedule/ghtml/.*?\.html)" target="_blank">(.*?)</a></span></td>
  <td width="45" nowrap><span class="t12">(\d+ch)</span></td>
  <td width="65" nowrap>(<img src="http://www\.wowow\.co\.jp/hivision/img/n?mark_15\.gif">)?(<img src="http://www\.wowow\.co\.jp/hivision/img/mark_51\.gif">)?</td>
  <td width="150" nowrap><span class="t12">(.*?)</span></td>
</tr>
RE
    ;
    my @program;
    while ($html =~ /$re/g) {
	my %data;
	@data{qw(link title channel hivision 51 date)} = ($1, $2, $3, $4, $5, $6);
	$data{hivision} = $data{hivision} !~ /nmark/;
        $data{date} = munge_datetime($data{date});
        push @program, \%data;
    }
    return @program;
}

sub munge_datetime {
    my $date = shift;

    # date: 2006年10月28日午後0:00~ JST
    $date =~ /^(\d{4})年(\d{1,2})月(\d{1,2})日(午前|午後|深夜)(\d{1,2}):(\d{2})/
        or die "No match: $date";
    my($year, $month, $day, $am_pm_midnight, $hour, $minute) = ($1, $2, $3, $4, $5, $6);
    $hour += 12 if $am_pm_midnight eq '午後';

    my $dt = DateTime->new(
        year  => $year,
        month => $month,
        day   => $day,
        hour  => $hour,
        minute => $minute,
        time_zone => 'Asia/Tokyo',
    );
    $dt->add( days => 1 ) if $am_pm_midnight eq '深夜';

    return DateTime::Format::W3CDTF->format_datetime($dt);
}
