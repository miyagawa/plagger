package Plagger::Plugin::Filter::FeedBurner;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    for my $feed ($context->update->feeds) {
        for my $entry ($feed->entries) {
            $self->feedburner_filter($context, $entry);
        }
    }
}

sub feedburner_filter {
    my($self, $context, $entry) = @_;

    if ($entry->link =~ m!^http://feeds\.feedburner\.com/!) {
        $entry->permalink( $entry->id );
    }
}

1;
