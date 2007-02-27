package Plagger::Rule::RecentN;
use strict;
use warnings;
use base qw( Plagger::Rule );

sub init {
    my $self = shift;

    my $number = $self->{count}
        or Plagger->context->erorr("count is not defined.");
}

sub id {
    my $self = shift;
    return "RecentN:$self->{count}";
}

sub dispatch {
    my($self, $args) = @_;

    my $entry = $args->{entry} or Plagger->context->error('No entry object in this plugin phase');
    $self->{__entries}->{$args->{feed}->id_safe}++ < $self->{count};
}

1;

__END__

=head1 NAME

Plagger::Rule::RecentN - rule to match recent N entries in the feed

  - module: Filter::Rule
    rule:
      - module: RecentN
        count:  20

=head1 DESCRIPTION

This module is a Rule module that matches recent N entries in the
feed.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
