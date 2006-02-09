package Plagger::Plugin::SmartFeed::Tag;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Tag;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.fixup' => \&fixup,
    );
}

sub fixup {
    my($self, $context) = @_;

    my @tags = Plagger::Tag->parse($self->conf->{tag});
    my $op   = $self->conf->{op} || 'AND';

    my $feed = Plagger::Feed->new;
    $feed->type('smartfeed:tag');
    $feed->id( $self->conf->{id} || ('smartfeed:tag:' . join('+', @tags)) );
    $feed->title( $self->conf->{title} || $self->gen_title($op, @tags) );

    for my $f ($context->update->feeds) {
        for my $entry ($f->entries) {
            if ($self->match_tags($op, $entry, \@tags)) {
                $feed->add_entry($entry->clone);
            }
        }
    }

    if (my $count = $feed->count) {
        $context->log(info => "$op search for tag @tags: found $count entries");
        $context->update->add($feed);
    }
}

sub gen_title {
    my($self, $op, @tags) = @_;
    return "Entries tagged with " .
        join(" $op ", map { qq('$_') } @tags);
}

sub match_tags {
    my($self, $op, $entry, $want_tags) = @_;

    my @bool;
    for my $want (@$want_tags) {
        push @bool, $entry->has_tag($want);
    }

    Plagger::Operator->call($op, @bool);
}

1;
