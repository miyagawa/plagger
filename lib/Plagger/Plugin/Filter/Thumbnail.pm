package Plagger::Plugin::Filter::Thumbnail;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup'  => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    # do nothing if there's already feed logo
    return if $args->{feed}->image;

    $context->log(info => "Add thumbnail as image to " . $args->{feed}->link);
    $args->{feed}->image( $self->build_image($args->{feed}) );
}

sub build_image {
    my($self, $feed) = @_;

    # TODO: use other serivces here
    return {
        url    => "http://img.simpleapi.net/small/" . $feed->link,
        title  => $feed->title,
        link   => $feed->link,
        width  => 128,
        height => 128,
    };
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Thumbnail - use Website thumbnail tool(s) to create alternative image for feeds

=head1 SYNOPSIS

  - module: Filter::Thumbnail

=head1 DESCRIPTION

This plugin puts image link to website thumbnail tool when a feed
doesn't have proper image set in feed itself (ala rss:image or atom:logo).

For now, it uses L<http://img.simpleapi.net/> as a default (and only)
URL to use with, but it should be configured when there's similar
(free) serviced out there.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
