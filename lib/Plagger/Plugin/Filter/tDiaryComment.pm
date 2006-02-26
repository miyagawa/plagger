package Plagger::Plugin::Filter::tDiaryComment;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

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
            $entry->add_rate($self->conf->{rate} || -1) if $entry->link =~ /#c\d+$/;
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::StripRSSAd - Rating comment of tDiary.

=head1 SYNOPSIS

    - module: Filter::tDiaryComment
      config:
            rate: -100

=head1 DESCRIPTION

This plugin rating comment of tDiary.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhiro at mobilefactory.jpE<gt>

=head1 SEE ALSO

L<Plagger>

=cut
