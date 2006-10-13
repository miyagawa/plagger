package Plagger::Feed;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( link url image language tags meta type source_xml aggregator ));
__PACKAGE__->mk_text_accessors(qw( description author title ));
__PACKAGE__->mk_date_accessors(qw( updated ));

use Digest::MD5 qw(md5_hex);
use URI;
use Plagger::Util;
use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    bless {
        meta  => {},
        tags  => [],
        entries => [],
        type  => 'feed',
    }, $class;
}

sub add_entry {
    my($self, $entry) = @_;
    push @{ $self->{entries} }, $entry;
}

sub delete_entry {
    my($self, $entry) = @_;
    my @entries = grep { $_ ne $entry } $self->entries;
    $self->{entries} = \@entries;
}

sub entries {
    my $self = shift;
    wantarray ? @{ $self->{entries} } : $self->{entries};
}

sub count {
    my $self = shift;
    scalar @{ $self->{entries} };
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    $self->{id} || $self->url || $self->link;
}

sub id_safe {
    my $self = shift;
    Plagger::Util::safe_id($self->id);
}

sub title_text {
    my $self = shift;
    $self->title ? $self->title->plaintext : undef;
}

sub sort_entries {
    my $self = shift;

    # xxx reverse chron only, using Schwartzian transform
    my @entries = map { $_->[1] }
        sort { $b->[0] <=> $a->[0] }
        map { [ $_->date || DateTime->from_epoch(epoch => 0), $_ ] } $self->entries;

    $self->{entries} = \@entries;
}

sub clear_entries {
    my $self = shift;
    $self->{entries} = [];
}

sub dedupe_entries {
    my $self = shift;

    # this logic breaks ordering of entries, to be sorted using sort_entries

    my(%seen, @entries);
    for my $entry ($self->entries) {
        push @{ $seen{$entry->permalink} }, $entry;
    }

    for my $permalink (keys %seen) {
        my @sorted = _sort_prioritize($permalink, @{ $seen{$permalink} });
        push @entries, $sorted[0];
    }

    $self->{entries} = \@entries;
}

sub _sort_prioritize {
    my($permalink, @entries) = @_;

    # use domain match, date and full-content-ness to prioritize source entry
    # TODO: Date vs Full-content check should be user configurable

    my $now = time;
    return
        map { $_->[0] }
        sort { $b->[1] <=> $a->[1] || $b->[2] <=> $a->[2] || $b->[3] <=> $a->[3] || $b->[4] <=> $a->[4] }
        map { [
            $_,                                              # Plagger::Entry for Schwartzian
            _is_same_domain($permalink, $_->source->url),    # permalink and $feed->url is the same domain
            _is_same_domain($permalink, $_->source->link),   # permalink and $feed->link is the same domain
            ($_->date ? ($now - $_->date->epoch) : 0),       # Older entry date is prioritized
            length($_->body || ''),                          # Prioritize full content feed
        ] } @entries;
}

sub _is_same_domain {
    my $u1 = URI->new($_[0]);
    my $u2 = URI->new($_[1]);

    return 0 unless $u1->can('host') && $u2->can('host');
    return lc($u1->host) eq lc($u2->host);
}

sub primary_author {
    my $self = shift;
    $self->author || do {
        # if all entries are authored by the same person, use him/her as primary
        my %authors = map { defined $_->author ? ($_->author => 1) : () } $self->entries;
        my @authors = keys %authors;
        @authors == 1 ? $authors[0] : undef;
    };
}

1;
