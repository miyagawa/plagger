package Plagger::Feed;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( link url image description language author updated tags meta type source_xml aggregator ));

use Digest::MD5 qw(md5_hex);
use Plagger::Util;

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

sub title {
    my $self = shift;
    if (@_) {
        my $title = shift;
        utf8::decode($title) unless utf8::is_utf8($title);
        $self->{title} = $title;
    }
    $self->{title};
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    $self->{id} || Digest::MD5::md5_hex($self->url || $self->link);
}

sub id_safe {
    my $self = shift;
    my $id = $self->id;
    $id =~ s![^\w\s]+!_!g;
    $id =~ s!\s+!_!g;
    $id;
}

sub title_text {
    my $self = shift;
    Plagger::Util::strip_html($self->title);
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
    my %seen;
    my @entries;
    for my $entry ($self->entries) {
        push @entries, $entry if !$seen{$entry->permalink}++;
    }
    $self->{entries} = \@entries;
}

1;
