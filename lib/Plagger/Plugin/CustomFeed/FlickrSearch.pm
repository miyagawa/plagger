package Plagger::Plugin::CustomFeed::FlickrSearch;
use strict;
use warnings;
use base qw( Plagger::Plugin );

use Flickr::API;
use XML::LibXML;
use DateTime::Format::Epoch;

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
    $feed->title("Flickr Search");
    $feed->id('flickr:search');

    my $flickr = Flickr::API->new({key => $self->conf->{api_key}});
    my $search = $flickr->execute_method('flickr.photos.search' => $self->conf);

    my $parser = XML::LibXML->new;

    $context->error("flickr.photos.search failed: $search->{error_text}")
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
    my $sizes = $flickr->execute_method('flickr.photos.getSizes', {
        photo_id => $search_photo->findvalue('@id'),
    });
    next unless $sizes->{success};
    
    my $sizes_doc = $parser->parse_string($sizes->{_content});
    my $size      = $self->conf->{size} || 'Square';
    my $image_src =
      $sizes_doc->findvalue(qq[/rsp/sizes/size[\@label='$size']/\@url]);

    my $info = $flickr->execute_method('flickr.photos.getInfo', {
        photo_id => $search_photo->findvalue('@id'),
    });
    next unless $info->{success};
    
    my $info_doc = $parser->parse_string($info->{_content});
    my $link     = $info_doc->findvalue(q[/rsp/photo/urls/url[@type='photopage']]);
    my $author   = $info_doc->findvalue(q[/rsp/photo/owner/@realname]);
       $author   = $info_doc->findvalue(q[/rsp/photo/owner/@username]) unless $author;
    my $title    = $info_doc->findvalue(q[/rsp/photo/title]);
    my $date     = $info_doc->findvalue(q[/rsp/photo/dates/@posted]);

    my $description = $context->templatize($self, 'entry-description.tt', {
        image_src => $image_src,
        title     => $title,
        link      => $link,
    });
    my $epoch = DateTime->from_epoch(epoch => 0, time_zone => '+0000');

    my $entry = Plagger::Entry->new;
    $entry->title($title);
    $entry->link($link);
    $entry->body($description);
    $entry->date(Plagger::Date->parse('Epoch::Unix', $date));

    return $entry;
}

1;
