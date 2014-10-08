package Plagger::Plugin::Filter::Rule;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'smartfeed.entry' => \&update,
        'smartfeed.feed'  => \&feed,
    );
}

sub update {
    my($self, $context, $args) = @_;
    $self->{entries}->{$args->{entry}} = 1;
}

sub feed {
    my($self, $context, $args) = @_;

    for my $entry ($args->{feed}->entries) {
        $args->{feed}->delete_entry($entry)
            unless $self->{entries}->{$entry};
    }

    if ($args->{feed}->count == 0) {
        $context->log(debug => "Deleting " . $args->{feed}->title . " since it has 0 entries");
        $context->update->delete_feed($args->{feed})
    }

}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Rule - Filter feed entries using Rule

=head1 SYNOPSIS

  - module: Filter::Rule
    rule:
      module: Fresh
      mtime:
        path: /tmp/foo.tmp
        autoupdate: 1

=head1 DESCRIPTION

This module strips entries and feeds using Rules. It's sort of like
SmartFeed, but while SmartFeed B<creates> new feed using Rule,
Filter::Rule strips entries and feeds that don't match with Rules.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::SmartFeed>

=cut


