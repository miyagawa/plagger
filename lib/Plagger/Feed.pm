package Plagger::Feed;
use strict;

use base qw( Plagger::Thing );
__PACKAGE__->mk_accessors(qw( link url image description language author updated tags meta type source_xml ));

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

sub title_text {
    my $self = shift;
    Plagger::Util::strip_html($self->title);
}

1;
