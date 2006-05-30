package Plagger::Plugin::Filter::FindEnclosures;
use strict;
use base qw( Plagger::Plugin );

use HTML::TokeParser;
use Plagger::Util qw( decode_content );
use List::Util qw(first);
use URI;
use DirHandle;
use Plagger::Enclosure;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;

    $context->autoload_plugin('Filter::ResolveRelativeLink');
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_plugins();

    $self->{ua} = Plagger::UserAgent->new;
}

sub load_plugins {
    my $self = shift;
    my $context = Plagger->context;

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or $context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[0] =~ /\.(?:pl|yaml)$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], sort $dh->read) {
        $self->load_plugin(@$file);
    }
}

sub load_plugin {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "loading $file");

    my $load_method = $file =~ /\.pl$/ ? 'load_plugin_perl' : 'load_plugin_yaml';
    push @{ $self->{plugins} }, $self->$load_method($file, $base);
}

sub load_plugin_perl {
    my($self, $file, $base) = @_;

    open my $fh, $file or Plagger->context->error("$file: $!");
    (my $pkg = $base) =~ s/\.pl$//;
    my $plugin_class = "Plagger::Plugin::Filter::FindEnclosures::Site::$pkg";

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::Filter::FindEnclosures::Site );",
              "sub site_name { '$pkg' }",
              $code,
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    return $plugin_class->new;
}

sub load_plugin_yaml { Plagger->context->error("NOT IMPLEMENTED YET") }

sub filter {
    my($self, $context, $args) = @_;

    # check $entry->link first, if it links directly to media files
    $self->add_enclosure($args->{entry}, [ 'a', { href => $args->{entry}->link } ], 'href' );

    my $parser = HTML::TokeParser->new(\$args->{entry}->body);
    while (my $tag = $parser->get_tag('a', 'embed', 'img', 'object')) {
        if ($tag->[0] eq 'a' ) {
            $self->add_enclosure($args->{entry}, $tag, 'href');
        } elsif ($tag->[0] eq 'embed') {
            $self->add_enclosure($args->{entry}, $tag, 'src', { type => $tag->[1]->{type} });
        } elsif ($tag->[0] eq 'img') {
            $self->add_enclosure($args->{entry}, $tag, 'src', { inline => 1 });
        } elsif ($tag->[0] eq 'object') {
            $self->add_enclosure_from_object($args->{entry}, $parser);
        }
    }
}

sub add_enclosure_from_object {
    my($self, $entry, $parser) = @_;

    # get param tags and find appropriate FLV movies
    my @params;
    while (my $tag = $parser->get_tag('param', '/object')) {
        last if $tag->[0] eq '/object';
        push @params, $tag;
    }

    # find URL inside flashvars parameter
    my $url;
    if (my $flashvars = first { lc($_->[1]->{name}) eq 'flashvars' } @params) {
        my %values = split /[=&]/, $flashvars->[1]->{value} || '';
        $url   = first { m!^https?://.*\flv! } values %values;
        $url ||= first { m!^https?://.*! } values %values;
    }

    # if URL isn't found in flash vars, then fallback to <param name="movie" />
    if (!$url) {
        my $movie = first { lc($_->[1]->{name}) eq 'movie' } @params;
        $url = $movie->[1]->{value} if $movie;
    }

    if ($url) {
        Plagger->context->log(info => "Found enclosure $url");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new($url) );
        $enclosure->auto_set_type;
        $entry->add_enclosure($enclosure); # XXX inline?
    }
}

sub add_enclosure {
    my($self, $entry, $tag, $attr, $opt) = @_;
    $opt ||= {};

    if ($self->is_enclosure($tag, $attr, $opt->{type})) {
        Plagger->context->log(info => "Found enclosure $tag->[1]{$attr}");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($tag->[1]{$attr});
        $enclosure->auto_set_type($opt->{type});
        $enclosure->is_inline(1) if $opt->{inline};
        $entry->add_enclosure($enclosure);
        return;
    }

    my $url = $tag->[1]{$attr};
    my $content;
    for my $plugin (@{$self->{plugins}}) {
        if ( $plugin->handle($url) ) {
            Plagger->context->log(debug => "Try $url with " . $plugin->site_name);
            $content ||= $self->fetch_content($url) or return;

            if (my $enclosure = $plugin->find($content)) {
                Plagger->context->log(info => "Found enclosure " . $enclosure->url ." with " . $plugin->site_name);
                $entry->add_enclosure($enclosure);
                return;
            }
        }
    }
}

sub fetch_content {
    my($self, $url) = @_;

    my $ua  = Plagger::UserAgent->new;
    my $res = $ua->fetch($url, $self, { NoNetwork => 3 * 60 * 60 });
    return if $res->status != URI::Fetch::URI_OK && $res->is_error;

    return decode_content($res);
}

sub is_enclosure {
    my($self, $tag, $attr, $type) = @_;

    return 1 if $tag->[1]{rel} && $tag->[1]{rel} eq 'enclosure';
    return 1 if $self->has_enclosure_mime_type($tag->[1]{$attr}, $type);

    return;
}

sub has_enclosure_mime_type {
    my($self, $url, $type) = @_;

    my $mime = $type ? MIME::Type->new(type => $type) : Plagger::Util::mime_type_of( URI->new($url) );
    $mime && $mime->mediaType =~ m!^(?:audio|video|image)$!;
}

package Plagger::Plugin::Filter::FindEnclosures::Site;
sub new { bless {}, shift }
sub handle { 0 }
sub find { }

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

