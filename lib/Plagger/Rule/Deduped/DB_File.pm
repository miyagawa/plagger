package Plagger::Rule::Deduped::DB_File;
use strict;
use base qw( Plagger::Rule::Deduped::Base );

use DB_File;

sub init {
    my($self, $rule) = @_;
    $self->{path} = $rule->{path} || Plagger->context->cache->path_to('Deduped.db');
    $self->{db} = tie my %cache, 'DB_File', $self->{path}, O_RDWR|O_CREAT, 0666, $DB_HASH
        or Plagger->context->error("Can't open DB_File $self->{path}: $!");
}

sub find_entry {
    my($self, $url) = @_;

    my $status = $self->{db}->get($url, my $value);
    return if $status == 1; # not found

    return $value;
}

sub create_entry {
    my($self, $url, $digest) = @_;
    $self->{db}->put($url, $digest);
}

1;
