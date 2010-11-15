package Plagger::Plugin::Filter::RSSLiberalDateTime;
use strict;
use base qw( Plagger::Plugin );

use Date::Parse ();
use DateTime::TimeZone::OffsetOnly;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.filter.feed' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    $args->{content} =~ s{<(pubDate|lastBuildDate)>([^<]+)</\1>}
                         {"<$1>" . $self->fixup_datetime($2) . "</$1>"}eg;
}

sub fixup_datetime {
    my($self, $date) = @_;

    my $valid = eval {  DateTime::Format::Mail->parse_datetime($date) };
    return $date if $valid;

    my @time = Date::Parse::strptime($date) or return $date;

    my $dt   = DateTime->new(
        second => $time[0] || 0,
        minute => $time[1] || 0,
        hour   => $time[2] || 0,
        day    => $time[3],
        month  => $time[4] + 1,
        year   => $time[5] + 1900,
    );

    if ($time[6]) {
        use integer;
        my $tz = sprintf "%s%02d%02d", ($time[6] > 0 ? "+" : "-"), abs($time[6] / 3600), $time[6] % 3600;
        $dt->set_time_zone($tz);
    }

    my $rfc822 = DateTime::Format::Mail->format_datetime($dt);
    Plagger->context->log(info => "Fix $date to $rfc822");
    $rfc822;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::RSSLiberalDateTime - Liberal datetime parsing on RSS 2.0 pubDate

=head1 SYNOPSIS

  - module: Filter::RSSLiberalDateTime

=head1 DESCRIPTION

This plugin fixes a bad datetime format in RSS 2.0 pubDate and lastBuildDate.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<DateTime::Format::Mail>, L<Date::Parse>

=cut
