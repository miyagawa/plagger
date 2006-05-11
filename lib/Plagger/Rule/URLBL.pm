package Plagger::Rule::URLBL;
use strict;
use base qw( Plagger::Rule );

use Net::DNS::Resolver;
use URI;

sub init {
    my $self = shift;

    Plagger->context->error("No dnsbl configuration")
        unless $self->{dnsbl};
}

sub dispatch {
    my($self, $args) = @_;

    my $url;
    if ($args->{entry}) {
        $url = $args->{entry}->permalink;
    } elsif ($args->{feed}) {
        $url = $args->{feed}->url;
    } else {
        Plagger->context->error("No feed nor entry object in this plugin phase");
    }

    return unless $url;

    my $res = Net::DNS::Resolver->new;
    my $dnsbl = $self->{dnsbl};
       $dnsbl = [ $dnsbl ] unless ref $dnsbl;

    my $uri = URI->new($url);
    my $domain = $uri->host;
    $domain =~ s/^www\.//;

    for my $dns (@$dnsbl) {
        Plagger->context->log(debug => "looking up $domain.$dns");
        my $q = $res->search("$domain.$dns");
        if ($q && $q->answer) {
            Plagger->context->log(info => "$domain.$dns found.");
            return 0;
        }
    }
    return 1;
}

1;

__END__

=head1 NAME

Plagger::Rule::URLBL - Rule to URLBL for feed url

=head1 SYNOPSIS

  - module: Aggregator::Xango
    rule:
      - module: URLBL
        dnsbl: rbl.bulkfeeds.jp

=head1 DESCRIPTION

The rule is decided by URLBL. 

=head1 CONFIG

=over 4

=item C<dnsbl>

  duration: dnsbl domain

=back

=head1 AUTHOR

Kazuhiro Osawa

inspired by L<Plagger::Plugin::Filter::URLBL>

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::URLBL>

=cut
