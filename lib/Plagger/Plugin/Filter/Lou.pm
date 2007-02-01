package Plagger::Plugin::Filter::Lou;
use strict;
use base qw( Plagger::Plugin );

use Acme::Lou;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'        => \&init_lou,
        'update.entry.fixup' => \&filter,
    );
}

sub init_lou {
    my ($self, $context, $args) = @_;
    
    $context->log(debug => "initializing Acme::Lou");
    $self->{lou} = Acme::Lou->new( $self->conf );
}

sub filter {
    my ($self, $context, $args) = @_;
    my $entry = $args->{entry};
    
    $entry->body( $self->{lou}->translate($entry->body) );
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::Lou - Filer text to Lou Style

=head1 SYNOPSIS

  - module: Filter::Lou
    config:
      lou_rate: 95
      html_fx_rate: 40

=head1 DESCRIPTION

This plugin filters entry body to Lou Ohshiba Style.

=head1 CONFIG

Same as L<Acme::Lou>.

=over 4

=item lou_rate 

Set percentage of translating. 100 means full translating, 
0 means do nothing. Default is 100.

=item html_fx_rate

Set percentage of HTML style decoration. Default is 0. 

=item format

This feature is of Acme::Lou v0.03. Default is C<%s>.

  - module: Filter::Lou
    config:
      format: "<ruby><rb>%s</rb><rp>(</rp><rt>%s</rt><rp>)</rp></ruby>"

See more information at L<Acme::Lou>.

=back

=head1 AUTHOR

Naoki Tomita

=head1 SEE ALSO

L<Plagger>, L<Acme::Lou>

=cut
