# author: mizzy
use Plagger::Util qw( decode_content );

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://(?:(?:au|br|ca|fr|de|us|hk|ie|it|jp|mx|nl|nz|pl|es|tw|gb|www)\.)?youtube\.com/(?:watch(?:\.php)?)?\?v=.+!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    my $ua = Plagger::UserAgent->new;

    my $res = $ua->fetch($url);
    return if $res->is_error;

        if ((my $verify_url = $res->http_response->request->uri) =~ /\/verify_age\?/) {
            $res = $ua->post($verify_url, { action_confirm => 'Confirm' });
            return if $res->is_error;

            $res = $ua->fetch($url);
            return if $res->is_error;

            $args->{content} = decode_content($res);
        }

    if ($args->{content} =~ /video_id=([^&]+)&l=\d+&t=([^&]+)/gms){
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://youtube.com/get_video?video_id=$1&t=$2");
        $enclosure->type('video/flv');
        $enclosure->filename("$1.flv");
        return $enclosure;
    }

    return;
}
