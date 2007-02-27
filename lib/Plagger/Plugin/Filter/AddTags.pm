package Plagger::Plugin::Filter::AddTags;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook( $self, 'update.feed.fixup' => \&filter, );
}

sub filter {
    my ( $self, $c, $args ) = @_;

    foreach my $entry ( $args->{feed}->entries ) {
        foreach my $tag ( @{ $self->conf->{tags} } ) {
            $c->log( info => "add tag " . $tag );
            $entry->add_tag($tag) unless $entry->has_tag($tag);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::AddTAg - add tags to entry

=head1 SYNOPSIS

  - module: Filter::AddTags
    config:
			tags:
      - from_plagger
			- perl


=head1 AUTHOR

Franck Cuny

=head1 SEE ALSO

L<Plagger>

=cut
