package Plagger::Plugin::Namespace::ApplePhotocast;
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

    my $apple = $args->{orig_entry}->{entry}->{"http://www.apple.com/ilife/wallpapers"} || {};
    if ($apple->{image}) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new($apple->{image}) );
        $enclosure->auto_set_type;
        $args->{entry}->add_enclosure($enclosure);
    }
    if ($apple->{thumbnail}) {
        $args->{entry}->icon({ url => $apple->{thumbnail} });
    }
}


1;
__END__

=head1 NAME

Plagger::Plugin::Namespace::ApplePhotocast - Apple Photocast module

=head1 SYNOPSIS

  - module: Namespace::ApplePhotocast

=head1 DESCRIPTION

This plugin parses Apple photocast RSS feed extensions and store photo
images to entry enclosures. This plugin is loaded by default.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
