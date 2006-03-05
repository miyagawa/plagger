package Plagger::Plugin::CustomFeed::Flickr::Search;
use strict;
use warnings;
use base qw( Plagger::Plugin );

use Flickr::API;
use XML::LibXML;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.flickr.search' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('flickr.search');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('flickr.search');
    $feed->title("Flickr Search");

    my $flickr = Flickr::API->new({key => $self->conf->{api_key}});
    my $search = $flickr->execute_method('flickr.photos.search' => $self->conf);

    $context->error("flickr.photos.search failed: $search->{error_text}")
      unless $search->{success};

    my $parser = XML::LibXML->new;
    my $search_doc = $parser->parse_string($search->{_content});

    foreach my $search_photo ( $search_doc->findnodes('/rsp/photos/photo') ) {
        my $sizes = $flickr->execute_method('flickr.photos.getSizes', {
            photo_id => $search_photo->findvalue('@id'),
        });
        next unless $sizes->{success};
        
        my $sizes_doc = $parser->parse_string($sizes->{_content});
        my $image_src =
          $sizes_doc->findvalue(q[/rsp/sizes/size[@label='Square']/@url]);

        my $entry = Plagger::Entry->new;
        
        # get url of photo page
        # get related details such as title, date, author(?)
    }

    $context->update->add($feed);
}

1;
