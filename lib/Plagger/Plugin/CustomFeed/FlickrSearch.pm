package Plagger::Plugin::CustomFeed::FlickrSearch;
use strict;
use warnings;
use base qw( Plagger::Plugin );

use Flickr::API;
use XML::LibXML;
use DateTime::Format::Epoch;
use Plagger::Enclosure;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });
    $feed->id('flickr:search');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('flickr.search');
    $feed->title("Flickr Search"); # xxx
    $feed->id('flickr:search'); # xxx

    my $flickr = Flickr::API->new({key => $self->conf->{api_key}});
    my $method = $self->conf->{method} || 'flickr.photos.search';

    my $params = $self->conf->{params} || {};
    $params->{per_page} ||= 20;

    $context->log(info => "calling $method on Flickr API");
    my $search = $self->call_method(
        $flickr,
        $method,
        $params,
        60 * 60,
    );

    my $parser = XML::LibXML->new;

    $context->error("$method failed: $search->{error_text}")
      unless $search->{success};
    my $search_doc = $parser->parse_string($search->{_content});

    foreach my $search_photo ( $search_doc->findnodes('/rsp/photos/photo') ) {
        my $entry = $self->_create_entry($context, $flickr, $parser, $search_photo);
        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

sub _create_entry {
    my ($self, $context, $flickr, $parser, $search_photo) = @_;

    my $photo_id  = $search_photo->findvalue('@id');
    my $server_id = $search_photo->findvalue('@server');
    my $secret    = $search_photo->findvalue('@secret');

    my $size      = $self->conf->{size} || 'm';
    my $thumb_src = sprintf "http://static.flickr.com/%s/%s_%s_t.jpg",
        $server_id, $photo_id, $secret;

    $context->log(info => "calling flickr.photos.getInfo on $photo_id");
    my $info = $self->call_method(
        $flickr,
        'flickr.photos.getInfo',
        { photo_id => $photo_id },
        60 * 60,
    );
    next unless $info->{success};

    my $info_doc = $parser->parse_string($info->{_content});
    my $link     = $info_doc->findvalue(q[/rsp/photo/urls/url[@type='photopage']]);
    my $author   = $info_doc->findvalue(q[/rsp/photo/owner/@realname])
                || $info_doc->findvalue(q[/rsp/photo/owner/@username]);
    my $title    = $info_doc->findvalue(q[/rsp/photo/title]);
    my $date     = $info_doc->findvalue(q[/rsp/photo/dates/@posted]);
    my $format   = $info_doc->findvalue(q[/rsp/photo/@originalformat]) || 'jpg';
    my $desc     = $info_doc->findvalue(q[/rsp/photo/description]);
    my @tags     = map $_->textContent, $info_doc->findnodes('/rsp/photo/tags/tag');

    my $original = sprintf "http://static.flickr.com/%s/%s_%s_o.%s",
        $server_id, $photo_id, $secret, $format;
    my $epoch = DateTime->from_epoch(epoch => 0, time_zone => '+0000');

    my $entry = Plagger::Entry->new;
    $entry->title($title);
    $entry->link($link);
    $entry->author($author);
    $entry->body($desc);
    $entry->date(Plagger::Date->parse('Epoch::Unix', $date));
    $entry->add_tag($_) for @tags;
    $entry->icon({ url => $thumb_src });

    my $enclosure = Plagger::Enclosure->new;
    $enclosure->url($original);
    $enclosure->auto_set_type;
    $entry->add_enclosure($enclosure);

    return $entry;
}

sub call_method {
    my($self, $flickr, $method, $param, $cache) = @_;

    my $cache_key = "$method:" . join("|", map "$_=$param->{$_}", sort keys %$param);
    $self->cache->get_callback(
        $cache_key,
        sub { $flickr->execute_method($method, $param) },
        $cache,
    );
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::FlickrSearch - Flickr API as Custom Feed

=head1 SYNOPSIS

  - module: CustomFeed::FlickrSearch
    config:
     api_key: YOUR-FLICKR-APIKEY
     method: flickr.photos.search
     params:
       tags: plagger

=head1 AUTHOR

Casey West

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.flickr.com/>, L<Flickr::API>

=cut
