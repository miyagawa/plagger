package Plagger::Plugin::Filter::DegradeYouTube;
use strict;
use base qw( Plagger::Plugin );

use WebService::YouTube;

my $regex = <<'...';
<object width="\d+" height="\d+".*?><param name="movie" value="(http://www.youtube.com/[^"]+)".*?><param name="wmode" value="transparent".*?>(.*?)</object>
...
chomp $regex;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $body  = $args->{entry}->body;
    $body =~ s{$regex}{
        my $url = $1;
        $context->log(info => "Found YouTube video $url");
        my $body;
        if (my $dev_id = $self->conf->{dev_id}) {
            my $thumb_url = $self->cache->get_callback(
                $url,
                sub { $self->_thumbnail_url($dev_id, $self->_video_id($url)) },
                60 * 60 * 24,
            );
            $context->log(info => "Thumbnail for $url => $thumb_url");
            qq{<a href="$url"><img src="$thumb_url" /></a>}
        } else {
            $context->log(warn => "No dev_id found. Just use the text replacement.");
            qq{<a href="$url">YouTube Movie</a>}
        }
    }ge;
    $args->{entry}->body($body);
}

sub _thumbnail_url {
    my ($self, $dev_id, $video_id) = @_;

    my $api = WebService::YouTube->new({dev_id => $dev_id});
    my $video = $api->videos->get_details($video_id);
    return $video->thumbnail_url;
}

sub _video_id {
    my ($self, $url) = @_;
    ($url =~ m[/v/([^/]+)$])[0];
}

1;
__END__

=for stopwords IMG

=head1 NAME

Plagger::Plugin::Filter::DegradeYouTube - Degrade YouTube object tags

=head1 SYNOPSIS

  - module: Filter::DegradeYouTube
    config:
      dev_id: YOUR-YOUTUBE-DEVID

=head1 DESCRIPTION

This plugin, when YouTube object tags are found in the entry body,
replaces the object tags into the degraded HTML, e.g. A link with IMG
to the thumbnail.

=head1 CONFIG

=over 4

=item dev_id

Your YouTube developer ID. If set, it tries to fetch the thumbnail
image using YouTube API. Optional.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plagger>

=cut
