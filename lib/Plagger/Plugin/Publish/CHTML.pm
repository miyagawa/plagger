package Plagger::Plugin::Publish::CHTML;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Digest::MD5 qw(md5_hex);
use File::Path;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    );
    $self->chtml_init($context);
}

sub chtml_init {
    my ($self, $context) = @_;
    $self->{context} = $context;
    $self->conf->{encoding} ||= 'cp932';
    $self->{id} = time;
    @{$self->{feeds}} = ();
    unless ($self->conf->{work}) {
	$context->error("Can't parse value in work");
    }
    $self->conf->{title} ||= __PACKAGE__;
}

sub id { shift->{id} }
sub context { shift->{context} }
sub work { shift->conf->{work} }

sub add {
    my($self, $feed) = @_;
    push @{ $self->{feeds} }, $feed;
}

sub feeds {
    my $self = shift;
    wantarray ? @{ $self->{feeds} } : $self->{feeds};
}

sub feed {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed} or return;
    my $feed_path = $self->work . '/feeds/' . $feed->id_safe;
    my $publish_path = "$feed_path/" . $self->id;

    mkpath($publish_path);
    foreach my $entry ($feed->entries) {
	my $entry_id = md5_hex($entry->permalink);
	$self->write("$publish_path/$entry_id.html",
		     $self->templatize('chtml_entry.tt', {
                         conf => $self->conf,
                         feed => $feed,
                         entry => $entry,
                         strip_html => sub {
                             my $html = shift;
                             $html =~ s|\s{2,}||og;
                             $html =~ s|<[bh]r.*?>|\n|ogi;
                             $html =~ s|<.*?>||og;
                             $html;
                         },
                     }));

	$entry->{feed2entry_link} = $self->id . "/$entry_id.html";
    }

    $self->write("$publish_path.html",
		 $self->templatize('chtml_feed.tt', {
                     conf => $self->conf,
                     feed => $feed,
                     earlier => $self->earlier($feed_path),
                     modified => (Plagger::Date->now),
                 }),
		 "$feed_path/index.html");

    $self->add(+{
	feed_link => './feeds/' . $feed->id_safe . '/' . $self->id . '.html',
	title  => $feed->title || '(no-title)',
	lastdate => $feed->entries->[-1]->date,
	count => scalar(@{$feed->entries}),
    });
}

sub finalize {
    my($self, $context) = @_;

    return unless @{$self->feeds};
    $self->write($self->work . '/' . $self->id . '.html', 
		 $self->templatize('chtml_index.tt', {
                     conf => $self->conf,
                     feeds => [ $self->feeds ],
                     earlier => $self->earlier($self->work),
                     modified => (Plagger::Date->now),
                 }),
		 $self->work . '/index.html');
}

sub write {
    my ($self, $file, $chtml, $symlink) = @_;
    open my $out, ">:encoding($self->{conf}->{encoding})", $file or $self->context->error("$file: $!");
    local $PerlIO::encoding::fallback = Encode::FB_HTMLCREF;
    print $out $chtml;
    close $out;
    $self->symlink($file, $symlink) if $symlink;
}

sub symlink {
    my ($self, $old, $new) = @_;
    unlink $new if -e $new;
    symlink $old, $new;
}

sub earlier {
    my ($self, $path) = @_;
    my $earlier;
    my $file = "$path/earlier";
    if (open my $in, '<', $file) {
	$earlier = <$in>;
	close $in;
    }
    open my $out, ">", $file or $self->context->error("$file: $!");
    print $out $self->id;
    close $out;
    $earlier;
}
1;
