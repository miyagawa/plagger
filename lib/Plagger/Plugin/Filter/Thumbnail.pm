package Plagger::Plugin::Filter::Thumbnail;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup'  => \&feed,
    );

    if ($self->conf->{set_per_entry}) {
        $context->register_hook(
            $self,
            'update.entry.fixup' => \&entry,
        );
    }
}

sub feed {
    my($self, $context, $args) = @_;

    # do nothing if there's already feed logo
    return if $args->{feed}->image;

    $context->log(info => "Add thumbnail as image to " . $args->{feed}->link);
    $args->{feed}->image( $self->build_image($args->{feed}->title, $args->{feed}->link) );
}

sub entry {
    my($self, $context, $args) = @_;

    # do nothing if there's already entry icon
    return if $args->{entry}->icon;

    $context->log(info => "Add thumbnail as image to " . $args->{entry}->permalink);
    $args->{entry}->icon( $self->build_image($args->{entry}->title, $args->{entry}->permalink) );
}

sub build_image {
    my($self, $title, $link) = @_;

    # TODO: use other serivces here
    return {
        url    => "http://img.simpleapi.net/small/" . $link,
        title  => $title,
        link   => $link,
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

=head1 CONFIG

=over 4

=item set_per_entry

With I<set_per_entry> set, it adds each entry thumbnail as entry's
icon, in addition to the feed logo. Optional and defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
