package Plagger::Plugin::Publish::Feed;

use strict;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use XML::Feed;
use XML::Feed::Entry;
use XML::RSS::LibXML;
use File::Spec;

$XML::Feed::RSS::PREFERRED_PARSER = "XML::RSS::LibXML";

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&publish_feed,
    );
    $self->init_feed($context);
}

sub init_feed {
    my($self, $context) = @_;

    # check dir
    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    unless (exists $self->conf->{full_content}) {
        $self->conf->{full_content} = 1;
    }
}

sub publish_feed {
    my($self, $context, $args) = @_;

    my $conf = $self->conf;
    my $f = $args->{feed};
    my $feed_format = $conf->{format} || 'Atom';

    local $XML::Atom::DefaultVersion = "1.0";

    # generate feed
    my $feed = XML::Feed->new($feed_format);
    $feed->title($f->title);
    $feed->link($f->link);
    $feed->modified(Plagger::Date->now);
    $feed->generator("Plagger/$Plagger::VERSION");
    $feed->description($f->description);

    if ($feed_format eq 'Atom') {
        $feed->{atom}->id("tag:plagger.org,2006:" . $f->id);
    }

    # add entry
    for my $e ($f->entries) {
        my $entry = XML::Feed::Entry->new($feed_format);
        $entry->title($e->title);
        $entry->link($e->link);
        $entry->summary($e->body_text) if defined $e->body;

        # hack to bypass XML::Feed Atom 0.3 crufts (type="text/html")
        if ($self->conf->{full_content} && defined $e->body) {
            if ($feed_format eq 'RSS') {
                $entry->content($e->body);
            } else {
                $entry->{entry}->content($e->body);
            }
        }

        $entry->category(join(' ', @{$e->tags}));
        $entry->issued($e->date)   if $e->date;
        $entry->modified($e->date) if $e->date;

        if ($feed_format eq 'RSS') {
            $entry->author($e->author . ' <nobody@example.com>');
        } else {
            $entry->author($e->author);
        }

        $entry->id("tag:plagger.org,2006:" . $e->id);

        if ($e->has_enclosure) {
            for my $enclosure (grep { defined $_->url && !$_->is_inline } $e->enclosures) {
                $entry->add_enclosure({
                    url    => $enclosure->url,
                    length => $enclosure->length,
                    type   => $enclosure->type,
                });

                # RSS 2.0 by spec doesn't allow multiple enclosures
                last if $feed_format eq 'RSS';
            }
        }

        $feed->add_entry($entry);
    }

    # generate file path
    my $filepath = File::Spec->catfile($self->conf->{dir}, $self->gen_filename($f));

    $context->log(info => "save feed for " . $f->link . " to $filepath");

    my $xml = $feed->as_xml;
    utf8::decode($xml) unless utf8::is_utf8($xml);
    open my $output, ">:utf8", $filepath or $context->error("$filepath: $!");
    print $output $xml;
    close $output;
}

my %formats = (
    'u' => sub { my $s = $_[0]->url;  $s =~ s!^https?://!!; $s },
    'l' => sub { my $s = $_[0]->link; $s =~ s!^https?://!!; $s },
    't' => sub { $_[0]->title },
    'i' => sub { $_[0]->id },
);

my $format_re = qr/%(u|l|t|i)/;

sub gen_filename {
    my($self, $feed) = @_;

    my $file = $self->conf->{filename} ||
        '%i.' . ($self->conf->{format} eq 'RSS' ? 'rss' : 'atom');
    $file =~ s{$format_re}{
        $self->safe_filename($formats{$1}->($feed))
    }egx;
    $file;
}

sub safe_filename {
    my($self, $path) = @_;
    $path =~ s![^\w\s]+!_!g;
    $path =~ s!\s+!_!g;
    $path;
}

# XXX okay, this is a hack until XML::Feed is updated
*XML::Feed::Entry::Atom::add_enclosure = sub {
    my($entry, $enclosure) = @_;
    my $link = XML::Atom::Link->new;
    $link->rel('enclosure');
    $link->type($enclosure->{type});
    $link->href($enclosure->{url});
    $link->length($enclosure->{length});
    $entry->{entry}->add_link($link);
};

*XML::Feed::Entry::RSS::add_enclosure = sub {
    my($entry, $enclosure) = @_;
    $entry->{entry}->{enclosure} = {
        url    => $enclosure->{url},
        type   => $enclosure->{type},
        length => $enclosure->{length},
    };
};


1;

__END__

=head1

Plagger::Plugin::Publish::Feed - republish RSS/Atom feeds

=head1 SYNOPSYS

  - module: Publish::Feed
    config:
      format: RSS
      dir: /home/yoshiki/plagger/feed
      filename: my_%t.rss

=head1 CONFIG

=over 4

=item format

Specify the format of feed. C<Plagger::Plugin::Publish::Feed> supports
the following syndication feed formats:

=over 8

=item Atom (default)

=item RSS

=back

=item dir

Directory to save feed files in.

=item filename

Filename to be used to create feed files. It defaults to C<%i.rss> for
RSS and C<%i.atom> for Atom feed. It supports the following format
like printf():

=over 8

=item %u url

=item %l link

=item %t title

=item %i id

=back

=item full_content

Whether to publish full content feed. Defaults to 1.

=back

=head1 AUTHOR

Yoshiki KURIHARA

Tatsuhiko Miyagawa

Gosuke Miyashita

=head1 SEE ALSO

L<Plagger>, L<XML::Feed>

=cut
