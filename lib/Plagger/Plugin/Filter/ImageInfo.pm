package Plagger::Plugin::Filter::ImageInfo;
use strict;
use base qw( Plagger::Plugin );

use Image::Info;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&entry,
        'update.feed.fixup'  => \&feed,
    );
}

sub entry {
    my($self, $context, $args) = @_;
    $self->fixup($context, $args->{entry}->icon);
}

sub feed {
    my($self, $context, $args) = @_;
    $self->fixup($context, $args->{feed}->image);
}

sub fixup {
    my($self, $context, $image) = @_;

    # do nothing if there's no image, or image already has width/height
    return unless $image && $image->{url};
    return if $image->{width} && $image->{height};

    $context->log(info => "Trying to fetch image size of $image->{url}");

    my $info = $self->cache->get_callback(
        $image->{url},
        sub { $self->fetch_image_info($image->{url}) },
        "3 days",
    );

    if ($info) {
        $context->log(debug => "width=$info->{width}, height=$info->{height}");
        $image->{width}  = $info->{width};
        $image->{height} = $info->{height};
    }
}

sub fetch_image_info {
    my($self, $url) = @_;

    my $ua  = Plagger::UserAgent->new;
    my $res = $ua->fetch($url);

    if ($res->is_error) {
        Plagger->context->log(error => "Error fetching $url");
        return;
    }

    my $info = eval { Image::Info::image_info(\$res->content) };
    $info;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::ImageInfo - Fetch image info (width/height etc.) for feed and entry images

=head1 SYNOPSIS

  - module: Filter::ImageInfo

=head1 DESCRIPTION

This plugin tries to fetch feed image (logo) and entry image (buddy
icon) and extracts image info like width & height. The data is parsed
with L<Image::Info> module and cached for 3 days.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Image::Info>

=cut
