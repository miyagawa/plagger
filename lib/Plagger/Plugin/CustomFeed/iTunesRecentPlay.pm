package Plagger::Plugin::CustomFeed::iTunesRecentPlay;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use File::Spec;
use Encode;
use DateTime::Format::W3CDTF;
use HTML::Entities;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.itunesrecentplay' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('itunesrecentplay');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $file = $self->conf->{library_path};
    unless ($file) {
        if ($^O eq 'MSWin32') {
            require File::HomeDir::Windows;
            my $mymusic = File::HomeDir::Windows->my_win32_folder('My Music');
            $file = File::Spec->catfile($mymusic, 'iTunes', 'iTunes Music Library.xml');
        } elsif ($^O eq 'darwin') {
            $file = File::Spec->catfile($ENV{HOME}, 'Music', 'iTunes', 'iTunes Music Library.xml');
        } else {
            $context->log(error => "I can't guess library.xml path using your OS name $^O.");
            return;
        }
    }

    open my $fh, "<:encoding(utf-8)", $file
        or return $context->log(error => "$file: $!");

    my $feed = Plagger::Feed->new;
    $feed->type('itunesrecentplay');
    $feed->title("iTunes Recent Play");

    my $data;
    while (<$fh>) {
        m!<key>Name</key><string>(.*?)</string>!
            and $data->{track} = HTML::Entities::decode($1);
        m!<key>Artist</key><string>(.*?)</string>!
            and $data->{artist} = HTML::Entities::decode($1);
        m!<key>Album</key><string>(.*?)</string>!
            and $data->{album} = HTML::Entities::decode($1);
        m!<key>Total Time</key><integer>(.*?)</integer>!
            and $data->{duration} = HTML::Entities::decode($1);
        m!<key>Play Date UTC</key><date>(.*?)</date>!
            and $data->{date} = HTML::Entities::decode($1);
        m!</dict>!
            and do {
                my $entry = Plagger::Entry->new;

                if( $data->{date} and $data->{artist} ){
                    my $dt = DateTime::Format::W3CDTF->parse_datetime($data->{date});
                    unless ($dt) {
                        $context->log( warn => "Can't parse $data->{date}");
                        next;
                    }
                    if( !defined $self->conf->{duration} or $dt->epoch > time - $self->conf->{duration} * 60 ){
                        for my $key (keys %$data){
                            $entry->meta->{$key} = $data->{$key};
                        }
                        $entry->date(Plagger::Date->from_epoch($dt->epoch));
                        $context->log( debug => $data->{artist} . ' ' . $data->{track});
                        $feed->add_entry($entry);
                    }
                }
                $data = {};
            };
    }

    $context->update->add($feed);
}

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::iTunesRecentPlay - iTunes Recent Play custom feed

=head1 SYNOPSIS

  # entries updated within 120 minutes
  - module: CustomFeed::iTunesRecentPlay
    config:
      library_path: /path/to/iTunes Music Library.xml
      duration: 120

=head1 DESCRIPTION

This plugin fetches the data of musics you played with iTunes or iPod recently.

=head1 CONFIG

=over 4

=item library_path

A path name of iTunes Music Libary.xml.If you omit this parameter,
this plugin try to find it automatically.

=item duration

This plugin find a music played recently if last played time is within
this parameter.It's good to define this parameter same as execution
period of plagger with cron to reduce memory usage.

=back

=head1 AUTHOR

Gosuke Miyashita, E<lt>gosukenator@gmail.comE<gt>

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
