package Plagger::Plugin::Filter::TracWikiTitle;
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

    my $entry = $args->{entry};
    if ($entry->link =~ m!/wiki/! && $entry->title =~ /.* edited by .*/) {
        my $title = $entry->title . ': ' . $entry->body;
        $title =~ s/[\r\n]//g;
        $entry->title( $title );
    }
}

1;

