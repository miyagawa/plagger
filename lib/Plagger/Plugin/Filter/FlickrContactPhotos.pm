package Plagger::Plugin::Filter::FlickrContactPhotos;
use strict;

use base qw( Plagger::Plugin );
use Flickr::API;
use XML::LibXML;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init' => \&init_flickr,
        'update.entry.fixup' => \&update,
    );
}

sub init_flickr {
    my ($self, $context, $args) = @_;

    $self->{flickr} = Flickr::API->new({
        key => $self->conf->{api_key}
    });
}

sub update {
    my($self, $context, $args) = @_;
    my $entry = $args->{entry};

    if ($entry->link !~ m{^http://www\.flickr\.com/photos/(.+?)/(\d+)/}) {
        return;
    }
    my $user_id = $1;
    my $photo_id = $2;

    my $icon = $self->cache->get_callback(
        "flickr-buddyicon-$user_id",
        sub {
            $self->_buddy_icon_of($photo_id);
        },
        '3 days'
    );
    $entry->icon($icon);
}

sub _buddy_icon_of {
    my($self, $photo_id) = @_;

    my $nsid = $self->_call_flickr(
        'flickr.photos.getInfo',
        { photo_id => $photo_id }
    )->findvalue('/rsp/photo/owner/@nsid');

    my $person = $self->_call_flickr(
        'flickr.people.getInfo',
        { user_id => $nsid }
    );

    my $title = $person->findvalue('/rsp/person/realname');
    $title ||= $person->findvalue('/rsp/person/username');

    return {
        url => sprintf(
            'http://farm%s.static.flickr.com/%s/buddyicons/%s.jpg',
            $person->findvalue('/rsp/person/@iconfarm'),
            $person->findvalue('/rsp/person/@iconserver'),
            $nsid,
        ),
        link => $person->findvalue('/rsp/person/profileurl'),
        title => $title,
    };
}

sub _call_flickr {
    my($self, $method, $args) = @_;

    my $resp = $self->{flickr}->execute_method($method, $args);

    my $doc = XML::LibXML->new->parse_string($resp->decoded_content);
    return $doc;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::FlickrContactPhotos;

=head1 SYNOPSIS

  - module: Filter::FlickrContactPhotos
    config:
     api_key: YOUR-FLICKR-APIKEY

=head1 DESCRIPTION

This plugin adds user's buddy icon to Flickr's photos.

=head1 AUTHOR

Kazuyoshi Kato

=head1 SEE ALSO

L<Plagger>, L<http://www.flickr.com/>, L<Flickr::API>

=cut
