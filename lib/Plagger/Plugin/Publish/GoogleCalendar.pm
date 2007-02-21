package Plagger::Plugin::Publish::GoogleCalendar;

use strict;
use base qw( Plagger::Plugin );
use Net::Google::Calendar;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'plugin.init'  => \&initialize,
        'publish.feed' => \&publish_feed,
    );
}

sub initialize {
    my ( $self, $c ) = @_;
    $self->{cal} = Net::Google::Calendar->new( url => $self->conf->{url} );
    $self->{cal}->login( $self->conf->{user}, $self->conf->{password} );
}

sub publish_feed {
    my ( $self, $c, $args ) = @_;

    my $feed = $args->{feed};
    for my $entry ( $feed->entries ) {
        my $gc_entry = Net::Google::Calendar::Entry->new();
        $gc_entry->title( $entry->permalink
            ? "["
                . $feed->title
                . "] <a href=\""
                . $entry->permalink . "\">"
                . $entry->title . "</a>"
            : "[" . $feed->title . "] " . $entry->title );
        $gc_entry->content( $entry->summary ? $entry->summary->plaintext : '',
        );
        $gc_entry->when( $entry->date,
            $entry->date + DateTime::Duration->new( minutes => 5 ) );
        my $tmp = $self->{cal}->add_entry($gc_entry);
        $c->log( warn => "Failed to add entry to google calendar" )
            if !defined $tmp;
        sleep(1);
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::GoogleCalendar - Publish feeds to google calendar

=head1 SYNOPSIS

  - module: Publish::GoogleCalendar
    config:
      url: 
	  user:
	  pass:

=head1 DESCRIPTION


=head1 CONFIG

=over 4

=item url

	URL for publishing on you calendar.

	See 

	    http://code.google.com/apis/gdata/calendar.html#find_feed_url

=back

=head1 AUTHOR

Franck Cuny

=head1 SEE ALSO

L<Plagger>

=cut
