# author: yappo, typester
use Plagger::Util qw( decode_content );

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://(?:www.)?ustream.tv/recorded/.+!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    return unless my($cid) = $url =~ qr!http://(?:www.)?ustream.tv/recorded/(.+)!;
    my $request_body = _request_body($cid);

    my $req = HTTP::Request->new( POST => 'http://gw.ustream.tv/gateway.php' );
    $req->content( $request_body );
    $req->content_type('application/x-amf');
    $req->content_length( length $request_body );
 
    my $ua = Plagger::UserAgent->new;
    my $res = $ua->request($req);
    my $response_body = $res->content;

    my $null = pack('C', 0);
    return unless my($server_id) = $response_body =~ /server_id...([^$null]+)/;
    return unless my($video_name) = $response_body =~ /video_name...([^$null]+)/;

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url("http://flash$server_id.ustream.tv:18881/$video_name.flv");
    $enclosure->type('video/flv');
    $video_name =~ s!/!_!g;
    $enclosure->filename("$video_name.flv");
    return $enclosure;

}

sub _request_body {
    my $cid = shift;

    my $body = pack('C*', qw( 0 0 0 0 0 1 0 ));
    $body .= pack('C', 0x12) . 'client.watch_video';
    $body .= pack('C*', qw( 0 2 47 49 0 0 0 49 10 0 0 0 1 3 0 ));
    $body .= pack('C', 3) . 'cid' . pack('C*', 2, 0, length($cid)) . $cid;
    $body .= pack('C*', qw( 0 0 9 ));

    $body;
}
