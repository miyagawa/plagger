package Plagger::UserAgent;
use strict;
use base qw( LWP::UserAgent );

use Carp;
use Plagger::Cookies;
use Plagger::FeedParser;
use URI::Fetch 0.06;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $conf = Plagger->context ? Plagger->context->conf->{user_agent} : {};
    if ($conf->{cookies}) {
        $self->cookie_jar( Plagger::Cookies->create($conf->{cookies}) );
    }

    $self->agent( $conf->{agent} || "Plagger/$Plagger::VERSION (http://plagger.org/)" );
    $self->timeout( $conf->{timeout} || 15 );
    $self->env_proxy();

    if (Plagger->context) {
        Plagger->context->run_hook('useragent.init', { ua => $self });
    }

    $self;
}

sub fetch {
    my($self, $url, $plugin, $opt) = @_;

    my $res = URI::Fetch->fetch($url,
        UserAgent => $self,
        $plugin ? (Cache => $plugin->cache) : (),
        ForceResponse => 1,
        ($opt ? %$opt : ()),
    );

    if ($res && $url =~ m!^file://!) {
        $res->content_type( Plagger::Util::mime_type_of(URI->new($url)) );
    }

    $res;
}

sub request {
    my $self = shift;
    my($req) = @_;
    if (Plagger->context) {
        Plagger->context->run_hook('useragent.request', { ua => $self, url => $req->uri, req => $req });
    }
    $self->SUPER::request(@_);
}

sub mirror {
    my($self, $request, $file) = @_;

    unless (ref($request)) {
        return $self->SUPER::mirror($request, $file);
    }

    # below is copied from LWP::UserAgent
    if (-e $file) {
        my($mtime) = (stat($file))[9];
        if($mtime) {
            $request->header('If-Modified-Since' =>
                             HTTP::Date::time2str($mtime));
        }
    }
    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    if ($response->is_success) {

        my $file_length = (stat($tmpfile))[7];
        my($content_length) = $response->header('Content-length');

        if (defined $content_length and $file_length < $content_length) {
            unlink($tmpfile);
            die "Transfer truncated: " .
                "only $file_length out of $content_length bytes received\n";
        }
        elsif (defined $content_length and $file_length > $content_length) {
            unlink($tmpfile);
            die "Content-length mismatch: " .
                "expected $content_length bytes, got $file_length\n";
        }
        else {
            # OK
            if (-e $file) {
                # Some dosish systems fail to rename if the target exists
                chmod 0777, $file;
                unlink $file;
            }
            rename($tmpfile, $file) or
                die "Cannot rename '$tmpfile' to '$file': $!\n";

            if (my $lm = $response->last_modified) {
                # make sure the file has the same last modification time
                utime $lm, $lm, $file;
            }
        }
    }
    else {
        unlink($tmpfile);
    }
    return $response;
}

sub find_parse {
    my($self, $url) = @_;
    $url = URI->new($url) unless ref $url;

    $self->parse_head(0);
    my $response = $self->fetch($url);
    if ($response->is_error) {
        Carp::croak("Error fetching $url: ", $response->http_status);
    }

    my $feed_url = Plagger::FeedParser->discover($response);
    if ($url eq $feed_url) {
        return Plagger::FeedParser->parse(\$response->content);
    } elsif ($feed_url) {
        return $self->fetch_parse($feed_url);
    } else {
        Carp::croak("Can't find feed from $url");
    }
}

sub fetch_parse {
    my($self, $url) = @_;
    $url = URI->new($url) unless ref $url;

    $self->parse_head(0);

    my $response = $self->fetch($url);
    if ($response->is_error) {
        Carp::croak("Error fetching $url: ", $response->http_status);
    }

    Plagger::FeedParser->parse(\$response->content);
}

1;

