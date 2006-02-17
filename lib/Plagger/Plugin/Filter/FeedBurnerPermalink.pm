package Plagger::Plugin::Filter::FeedBurnerPermalink;
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
    if ($entry->link =~ m!^http://feeds\.feedburner\.(com|jp)/!) {
        $entry->permalink( $entry->id . "" ); # stringify guid
    }
}

1;
