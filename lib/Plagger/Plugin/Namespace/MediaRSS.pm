package Plagger::Plugin::Namespace::MediaRSS;
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

    # Ick, I need to try the URL with and without the trailing slash
    for my $media_ns ("http://search.yahoo.com/mrss", "http://search.yahoo.com/mrss/") {
        my $media = $args->{orig_entry}->{entry}->{$media_ns}->{group} || $args->{orig_entry}->{entry};
        my $content = $media->{$media_ns}->{content} || [];
        $content = [ $content ] unless ref $content && ref $content eq 'ARRAY';

        for my $media_content (@{$content}) {
            next unless ref($media_content) eq 'HASH' && exists($media_content->{url}) && exists($media_content->{type});
            my $enclosure = Plagger::Enclosure->new;
            $enclosure->url( URI->new($media_content->{url}) );
            $enclosure->auto_set_type($media_content->{type});
            $args->{entry}->add_enclosure($enclosure);
        }

        my $thumbnail = $media->{$media_ns}->{thumbnail};
        $thumbnail = $thumbnail->[0] if (ref($thumbnail) eq "ARRAY");
        if ($thumbnail) {
            $args->{entry}->icon({
                url   => $thumbnail->{url},
                width => $thumbnail->{width},
                height => $thumbnail->{height},
            }) if ref($thumbnail) eq 'HASH';
        }
    }

    1;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Namespace::MediaRSS - Media RSS extension

=head1 SYNOPSIS

  - module: Namespace::MediaRSS

=head1 DESCRIPTION

This plugin parses Media RSS extension in the feeds and stores media
information to entry enclosures. This plugin is loaded by default.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://search.yahoo.com/mrss>

=cut
