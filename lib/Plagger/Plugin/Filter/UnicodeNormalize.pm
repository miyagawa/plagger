package Plagger::Plugin::Filter::UnicodeNormalize;
use strict;
use base qw( Plagger::Plugin );

use Unicode::Normalize 'normalize';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    my $form = $self->conf->{form} || 'KC';
    my $normalized_body = normalize($form, $entry->body);
    $entry->body($normalized_body); 
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::UnicodeNormalize - Unicode Normalization

=head1 SYNOPSIS

  - module: Filter::UnicodeNormalize
    config:
      form: NFKC

=head1 DESCRIPTION

This plugin normalize feed content using L<Unicode::Normalize>.

=head1 CONFIG

=over 4

=item form

The method of normalize form can be specified by I<form> set.
select forms from NFD, NFC, NFKD, NFKC, etc. Optional and defaults to NFKC.
see L<Unicode::Normalize>.

=back

=head1 AUTHOR

Masafumi Otsune

=head1 SEE ALSO

L<Plagger> L<Unicode::Normalize>

=cut
