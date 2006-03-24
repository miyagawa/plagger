package Plagger::Plugin::Filter::Regexp;
use strict;
use base qw( Plagger::Plugin::Filter::Base );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    unless ($self->conf->{regexp}) {
        Plagger->context->error("regexp is missing");
        return;
    }
}

sub filter {
    my($self, $body) = @_;

    local $_ = $body;
    my $count = eval $self->conf->{regexp};

    if ($@) {
        Plagger->context->log(error => "Error: $@ in " . $self->conf->{regexp});
        return (0, $body);
    }

    return ($count, $_);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Regexp - Rewrite entry body using regular expression

=head1 SYNOPSIS

  - module: Filter::Regexp
    config:
      regexp: s/Plagger/$1, the pluggable Aggregator/g
      text_only: 1

=head1 DESCRIPTION

This plugin applies regular expression to each entry body by using
C<eval>.

=head1 CONFIG

=over 4

=item text_only

When set to 1, uses HTML::Parser so that the regexp substition should
be applied only to HTML text part. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
