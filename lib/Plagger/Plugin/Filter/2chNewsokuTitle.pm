package Plagger::Plugin::Filter::2chNewsokuTitle;
use strict;
use base qw( Plagger::Plugin );

use encoding 'utf-8';
use Encode;
use Plagger::UserAgent;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $tags  = $args->{entry}->tags;
    my $title = $args->{entry}->title;
    $title = "\x{3010}$tags->[0]\x{3011} " . $title if $tags->[0];
    $title = $title . " \x{3010}$tags->[1]\x{3011}" if $tags->[1];

    $args->{entry}->title($title);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::2chNewsokuTitle - Newsokuize entry titles

=head1 SYNOPSIS

  - module: Filter::2chNewsokuTitle

=head1 DESCRIPTION

This plugin uses entry tags to be prepended and appended to title, ala
2ch.net Newsoku style. Best used with plugin Filter::BulkfeedsTerms.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::BulkfeedsTerms>

=cut
