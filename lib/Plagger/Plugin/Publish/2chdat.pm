package Plagger::Plugin::Publish::2chdat;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use File::Spec;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or Plagger->context->error("$dir: $!");
        mkdir File::Spec->catfile($dir, 'dat'), 0755 or Plagger->context->error("$dir/dat: $!");
    }
}

sub feed {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed};
    my $out  = File::Spec->catfile($self->conf->{dir}, 'dat', $self->safe_id($feed->id) . ".dat");
    $context->log(info => "Writing dat output to $out");

    my $anonymous = decode("utf-8", $self->conf->{default_anonymous} || "名無しさん");

    open my $fh, ">:encoding(shift_jis)", $out or $context->error("$out: $!");
    printf $fh "%s<><>%s ID:%s<> %s<>%s\n",
        ($feed->author || $feed->entries->[0]->author || $anonymous),
        $self->format_date( Plagger::Date->from_epoch(0) ), # Fix created date to handle bytes-range request
        substr($self->safe_id($feed->id), 0, 8),
        $self->format_body($feed->description) . "<BR>" . $feed->link,
        $feed->title;

    for my $entry (reverse $feed->entries) {
        printf $fh "%s<><>%s ID:%s<> %s\n",
            ($entry->author || $anonymous),
            $self->format_date( $entry->date || Plagger::Date->now ),
            substr($entry->id_safe, 0, 8),
            $self->format_body($entry->body) . "<P>" . $entry->link . "</P>";
    }

    close $fh;

    # update mtime of file with the latest entry
    if (my $mtime = $feed->entries->[0]->date) {
        utime $mtime->epoch, $mtime->epoch, $out;
    }
}

sub finalize {
    my($self, $context, $args) = @_;

    my $out = File::Spec->catfile($self->conf->{dir}, 'subject.txt');
    open my $fh, ">:encoding(shift_jis)", $out or $context->erorr("$out: $!");
    for my $feed ($context->update->feeds) {
        printf $fh "%s.dat<>%s (%d)\n", $self->safe_id($feed->id), $feed->title, $feed->count;
    }
}

sub safe_id {
    my($self, $id) = @_;
    $id =~ s![^\w\s]+!_!g;
    $id =~ s!\s+!_!g;
    $id;
}

sub format_date {
    my($self, $date) = @_;
    my $clone = $date->clone;
    $clone->set_locale("ja_JP");
    return $clone->strftime("%Y/%m/%d(%a) %H:%M:%S");
}

sub format_body {
    my($self, $body) = @_;

    # replace images
    $body =~ s!<img .*?src="(.*?)".*?>!$1!ig;

    # ad-hoc replacement of A links
    $body =~ s{<a .*?href="(.*?)".*?>(.*?)</a>}
              {my($url, $label) = ($1, $2);
               $label =~ m!^https?://! ? $url : "$label ($url)"}ieg;

    # respect newline in <pre> tags
    $body =~ s{(<pre>)(.*?)(</pre>)}{$1 . nl2br($2) . $3}seig;

    # other than that, nuke newlines
    $body =~ tr/\r\n//d;

    $body;
}

sub nl2br {
    my $str = shift;
    $str =~ s/\r?\n/<BR>/g;
    $str;
}

1;

__END__

=head1

Plagger::Plugin::Publish::2chdat - Publish 2ch data files for 2ch browsers

=head1 SYNOPSYS

  - module: Publish::2chdat
    config:
      dir: /home/miyagawa/public_html/2chdat

=head1 DESCRIPTION

This plugin publishes feed updates as 2ch browser compatible data
files e.g. C<subject.txt> and C<*.dat> files.

Note that this plugin might not work very well with Subscription
plugins that manages unread management, e.g. Bloglines and Livedoor
Reader.

=head1 CONFIG

=head2 dir

Directory to save data files in.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://age.s22.xrea.com/talk2ch/>

=cut
