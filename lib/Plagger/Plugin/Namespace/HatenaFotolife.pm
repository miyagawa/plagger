package Plagger::Plugin::Namespace::HatenaFotolife;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.entry.fixup' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    # Hatena Image extensions
    my $hatena = $args->{orig_entry}->{entry}->{"http://www.hatena.ne.jp/info/xmlns#"} || {};
    if ($hatena->{imageurl}) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($hatena->{imageurl});
        $enclosure->auto_set_type;
        $args->{entry}->add_enclosure($enclosure);
    }

    if ($hatena->{imageurlsmall}) {
        $args->{entry}->icon({ url   => $hatena->{imageurlsmall} });
    }

    1;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Namespace::HatenaFotolife - Parses Hatena Fotolife module

=head1 SYNOPSIS

  - module: Namespace::HatenaFotolife

=head1 DESCRIPTION

This plugin parses Hatena Fotolife namespace extension and set images
URL to entry enclosures. This plugin is loaded by default.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.hatena.ne.jp/info/xmlns#>

=cut
