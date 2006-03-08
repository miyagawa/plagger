package Plagger::Plugin::Filter::BlogPet;
use strict;
use warnings;
use base qw (Plagger::Plugin);

our $VERSION = '0.01';

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&filter,
    );
}

sub filter {
    my ($self, $context, $args) = @_;
    for my $entry ($args->{feed}->entries) {
        if ($entry->title =~ /\(BlogPet\)$/) {
            $context->log(info => "Delete BlogPet's entry " . $entry->link);
            $args->{feed}->delete_entry($entry);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::BlogPet - Filtering BlogPet

=head1 SYNOPSIS

    - module: Filter::BlogPet

=head1 DESCRIPTION

BlogPet (L<http://www.blogpet.net/>) is a bot program which can publish a
poem like entry to the blog automatically. But those automated texts are
sometimes no worth reading I think.

This plugin allows you to strip those BlogPet's entries from the feeds.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>

=cut
