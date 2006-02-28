package Plagger::Plugin::Publish::Feed;

use strict;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use XML::Feed;
use XML::Feed::Entry;
use File::Spec;

# Now XML::RSS::LibXML(0.15) has a bug when it process for RSS 2.0.
# So this module uses XML::RSS temporarily.
$XML::Feed::RSS::PREFERRED_PARSER = "XML::RSS";

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
}

sub publish_feed {
    my($self, $context, $args) = @_;

    my $conf = $self->conf;
    my $f = $args->{feed};
    my $feed_format = $conf->{format} || 'Atom';

    # generate feed
    $context->log(info => "generate feed: " . $f->type);
    my $feed = XML::Feed->new($feed_format);
    $feed->title($f->title_text);
    $feed->link($f->link);
    $feed->modified(Plagger::Date->now(timezone => $context->conf->{timezone}));
    $feed->generator("Plagger-$Plagger::VERSION");

    # add entry
    for my $e ($f->entries) {
        my $entry = XML::Feed::Entry->new($feed_format);
        $entry->title($e->title_text);
        $entry->link($e->link);
        $entry->summary($e->body_text);
        $entry->category(join(' ', @{$e->tags}));
        $entry->issued($e->date);
        $entry->author($e->author);
        $feed->add_entry($entry);
    }

    # generate file path
    my $filepath = File::Spec->catfile($self->conf->{dir}, $self->gen_filename($f));


    # output feed
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

1;

__END__

=head1

Plagger::Plugin::Publish::Feed

=head1 SYNOPSYS

    - module: Publish::Feed
      config:
        format: RSS
        dir: /home/yoshiki/plagger/feed
        filename: my_%t.rss

=head1 CONFIG

=head2 format

Specify the format of feed. C<Plagger::Plugin::Publish::Feed> supports the following syndication feed formats:

=over 4

=item * Atom (default)

=item * RSS

=back

=head2 dir

Directory for saving feed files.

=head2 filename

File name for feed files. A default file name is used, if you do not specify it. It supports the following format like printf():

=over 4

=item * %u url

=item * %l link

=item * %t title

=item * %i id

=back

=head1 AUTHOR

Yoshiki KURIHARA

=head1 SEE ALSO

C<Plagger>, C<XML::Feed>

=cut
