package Plagger::Plugin::Filter::FindEnclosures;
use strict;
use base qw( Plagger::Plugin );

use HTML::TokeParser;
use Plagger::Util;
use URI;

sub register {
    my($self, $context) = @_;

    $context->autoload_plugin('Filter::ResolveRelativeLink');
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    # check $entry->link first, if it links directly to media files
    $self->add_enclosure($args->{entry}, [ 'a', { href => $args->{entry}->link } ], 'href' );

    my $parser = HTML::TokeParser->new(\$args->{entry}->body);
    while (my $tag = $parser->get_tag('a', 'embed', 'img')) {
        if ($tag->[0] eq 'a' ) {
            $self->add_enclosure($args->{entry}, $tag, 'href');
        } elsif ($tag->[0] eq 'embed') {
            $self->add_enclosure($args->{entry}, $tag, 'src');
        } elsif ($tag->[0] eq 'img') {
            $self->add_enclosure($args->{entry}, $tag, 'src', 1);
        }
    }
}

sub add_enclosure {
    my($self, $entry, $tag, $attr, $inline) = @_;

    if ($self->is_enclosure($tag, $attr)) {
        Plagger->context->log(info => "Found enclosure $tag->[1]{$attr}");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($tag->[1]{$attr});
        $enclosure->auto_set_type;
        $enclosure->is_inline($inline);
        $entry->add_enclosure($enclosure);
    }
}

sub is_enclosure {
    my($self, $tag, $attr) = @_;

    return 1 if $tag->[1]{rel} && $tag->[1]{rel} eq 'enclosure';
    return 1 if $self->has_enclosure_mime_type($tag->[1]{$attr});

    return;
}

sub has_enclosure_mime_type {
    my($self, $url) = @_;

    my $mime = Plagger::Util::mime_type_of( URI->new($url) );
    $mime && $mime->mediaType =~ m!^(?:audio|video|image)$!;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FindEnclosures - Auto-find enclosures from entry content using B<< <a> >> / B<< <embed> >> tags

=head1 SYNOPSIS

  - module: Filter::FindEnclosures

=head1 DESCRIPTION

This plugin finds enclosures from C<< $entry->body >> by finding 1)
B<< <a> >> links with I<rel="enclosure"> attribute, 2) B<< <a> >>
links to any URL which filename extensions match with known
audio/video formats and 3) I<src> attributes in B<< <img> >> and B<< <embed> >> tags.

For example:

  Listen to the <a href="http://example.com/foobar.mp3">Podcast</a> now, or <a rel="enclosure"
  href="http://example.com/foobar.m4a">download AAC version</a>. <img src="/img/logo.gif" />

Those 3 links (I<foobar.mp3>, I<foobar.m4a> and I<logo.gif>) are
extracted as enclosures, while I<logo.gif> is marked as "inline", so
that they won't appear as enclosures in Publish::Feed.

You might want to also use Filter::HEADEnclosureMetadata plugin to
know the actual length (bytes-length) of enclosures by sending HEAD
requests.

=head1 AUTHOR

Tatsuhiko Miyagawa

Masahiro Nagano

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HEADEnclosureMetadata>, L<http://www.msgilligan.com/rss-enclosure-bp.html>, L<http://forums.feedburner.com/viewtopic.php?t=20>

=cut

