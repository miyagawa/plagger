package Plagger::Plugin::Filter::TagsToTitle;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.01_01';

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&filter,
    );
}

sub filter {
    my ($self, $context, $args) = @_;

    my $add_to = $self->conf->{add_to} || 'left';

    foreach my $entry ($args->{feed}->entries) {
        my @tags  = $entry->tags ? map { "[$_]" } @{ $entry->tags } : ();
        my $title = $entry->title;

        # XXX: should I see (or erase) original tags? optional?
        # my @orig = $title =~ /\[[^]]+\]\s*/g;
        # $title =~ s/\[[^]]+\]\s*//g;

        push    @tags, $title if $add_to eq 'left';
        unshift @tags, $title if $add_to eq 'right';

        $entry->title( join(' ', @tags) );
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::TagsToTitle - add tags to entry title

=head1 SYNOPSIS

  - module: Filter::TagsToTitle
    config:
      add_to: left

=head1 CONFIG

=over 4

=item add_to

Specify 'left' or 'right' of the title. Defaults to 'left'.

=back

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>

=cut
