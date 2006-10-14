package Plagger::Plugin::Filter::GuessTimeZoneByDomain;
use strict;
use base qw( Plagger::Plugin );

use DateTime::TimeZone;
use List::Util qw( first );

sub register {
    my($self, $context) = @_;

    unless (DateTime::TimeZone->can('names_in_country')) {
        $context->log(error => 'DateTime::TimeZone >= 0.51 is required.');
        return;
    }

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
        'plugin.init'        => \&initialize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;

    unless (defined $self->conf->{use_ip_country} && !$self->conf->{use_ip_country}) {
        eval { require IP::Country::Fast };
        $self->{ip_country} = IP::Country::Fast->new unless $@;
    }

    my %valid_policy = map { $_ => 1 } qw( cc ip );
    unless ($self->conf->{conflict_policy} && $valid_policy{$self->conf->{conflict_policy}}) {
        $self->conf->{conflict_policy} = 'cc';
    }
}

sub update {
    my($self, $context, $args) = @_;

    return unless $args->{entry}->date && $args->{entry}->date->time_zone->is_floating;

    my $uri = URI->new($args->{entry}->link);
    $uri->can('host') or return;

    my $host  = $uri->host;
    my %result;

    my $cctld = ($host =~ /\.(\w{2})$/)[0];
    if ($cctld) {
        my @names = DateTime::TimeZone->names_in_country($cctld);
        $result{cc} = $names[0];
        $context->log(info => "guess by ccTLD ($cctld): " . $names[0] || '(undef)');
    }

    if ($self->{ip_country}) {
        my $ccip = $self->{ip_country}->inet_atocc($host);
        if ($ccip) {
            my @names = DateTime::TimeZone->names_in_country($ccip);
            $result{ip} = $names[0];
            $context->log(info => "guess by IP::Country ($ccip): " . $names[0] || '(undef)');
        }
    }

    my @cand = $self->conf->{conflict_policy} eq 'cc' ?
        @result{qw(cc ip)} : @result{qw(ip cc)};

    my $tz = first { defined } @cand;
    if ($tz) {
        $context->log(info => "Use timezone $tz");
        $args->{entry}->date->set_time_zone($tz);
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::GuessTimeZoneByDomain - Guess timezone by domains if datetime is floating

=head1 SYNOPSIS

  - module: Filter::GuessTimeZoneByDomain

=head1 DESCRIPTION

This plugin guesses feed date timezone by domains, if dates are
floating. It uses the mapping table from ISO 3166 country code to
timezones available in Olson database (hence requires
DateTime::TimeZone 0.51).

Optionally, if you have IP::Country module installed. This plugin also
checks the country name which the host address is assigned to, instead
of its domain name (ccTLD).

For example, if the datetime is floating in the feed of I<example.jp>,
it is resolved to I<Asia/Tokyo> since its ccTLD is I<jp>. In the case
of I<www.asahi.com>, ccTLD is null but the IP address is assigned to
Japan, hence it is resolved to I<Asia/Tokyo> as well.

=head1 CONFIG

=over 4

=item conflict_policy

  conflict_policy: cc
  conflict_policy: ip

I<conflict_policy> determines what to do if timezones guessed from 1)
ccTLD and 2) country code from IP::Country doesn't match. I<cc>
prioritizes ccTLD, and I<ip> prioritizes IP::Country.

For example, I<http://www.sixapart.jp/> has a ccTLD I<jp>, but its
host address is assigned to the United States (I<US>). In this case:

  conflict_policy    timezone
  -----------------------------------
  cc                 Asia/Tokyo
  ip                 America/New_York

(Note that US has multiple timezones but I<America/New_York> is used
since this one is listed first in the Olson database.)

Defaults to I<cc>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::FloatingDateTime>, L<DateTime::TimeZone>

=cut
