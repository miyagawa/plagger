package Plagger::Plugin::Filter::2chRSSContent;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    return unless $args->{entry}->link =~ m!\.2ch\.net/test/read\.cgi|rss\.s2ch\.net/test(\.cgi)?/\-/!;

    my $body = $args->{entry}->body;
    if ($body && $body =~ s!^([^:]*):(\d{4}/\d\d/\d\d)\(.*?\) (\d\d:\d\d:\d\d)(?:\.\d\d)? (ID:\S+)?  ?!!) {
        my($from, $day, $time, $id) = ($1, $2, $3, $4);
        my $date = Plagger::Date->strptime('%Y/%m/%d %H:%M:%S', "$day $time");
        $date->set_time_zone('Asia/Tokyo');

        $context->log(info => "Normalize 2ch rss body $id on $date");

        $args->{entry}->date($date);
        $args->{entry}->author( $from ? "$from $id" : $id );
        $args->{entry}->body($body);
    } elsif ($args->{entry}->title =~ /^\d+\-$/
             || ($body && $body =~ m!http://www\.2ch\.net/ad\.html *powerd by Big-Server\.!)) {
        $context->log(info => "Strip 2ch bogus entry " . $args->{entry}->title);
        $args->{feed}->delete_entry($args->{entry});
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::2chRSSContent - Normalize 2ch RSS content body

=head1 SYNOPSIS

  - module: Filter::2chRSSContent

=head1 DESCRIPTION

This plugin fixes 2ch RSS content body to correctly handle date per
item, set ID: to author and strips bogus links.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::StripRSSAd>

=cut
