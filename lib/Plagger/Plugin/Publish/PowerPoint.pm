package Plagger::Plugin::Publish::PowerPoint;

use strict;
use base qw( Plagger::Plugin );

use Win32::PowerPoint;
use Encode;
use File::Path;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&publish_presentation,
        'publish.init'  => \&connect_powerpoint,
    );
}

sub publish_presentation {
    my ($self, $context, $args) = @_;

    my $feed = $args->{feed};

    $self->{powerpoint}->new_presentation;

    foreach my $entry ($feed->entries) {

        my $title_text = $entry->title_text;
        my $body_text  = $entry->body_text;

        $title_text =~ s/^\s+//mg;
        $body_text  =~ s/^\s+//mg;

        $self->{powerpoint}->new_slide;
        $self->{powerpoint}->add_text(
            encode('shift_jis',$title_text),
            { size => 30, bold => 1, height => 50, link => $entry->permalink },
        );
        $self->{powerpoint}->add_text(
            encode('shift_jis',$body_text),
            { size => 20 },
        );
    }

    # generate file path;
    my $file = File::Spec->catfile(
        $self->conf->{dir}, Plagger::Util::filename_for($feed, $self->conf->{filename} || '%i.pps'),
    );

    $context->log(info => "save feed for " . $feed->link . " to $file");

    $self->{powerpoint}->save_presentation($file);
    $self->{powerpoint}->close_presentation;
}

sub connect_powerpoint {
    my ($self, $context, $args) = @_;

    my $dir = $self->conf->{dir} || '.';
    unless (-e $dir && -d _) {
        $context->log(debug => "make dir");
        mkpath($dir, 0755) or $context->error("mkdir $dir: $!");
    }

    $context->log(debug => "hello, PowerPoint");
    $self->{powerpoint} = Win32::PowerPoint->new;
}

1;

__END__

=head1

Plagger::Plugin::Publish::PowerPoint - publish as PowerPoint slide

=head1 SYNOPSIS

  - module: Publish::PowerPoint
    config:
      dir: /home/foobar/plagger
      filename: %l.pps

=head1 CONFIG

Accepts C<dir> and C<filename>. See ::Publish::Feed for details.

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

C<Plagger>, C<Plagger::Plugin::Publish::Feed>, C<Win32::PowerPoint>

=cut
