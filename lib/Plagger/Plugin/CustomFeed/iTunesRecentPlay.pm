package Plagger::Plugin::CustomFeed::iTunesRecentPlay;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use File::Spec;
use Encode;
use DateTime::Format::W3CDTF;
use HTML::Entities;
use Plagger::UserAgent;
use Net::Amazon;
use Net::Amazon::Request::Keyword;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });
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

    my $uri = URI->new($file);
    if ($uri->scheme) {
        $file = $self->cache->path_to('iTunes Music Library.xml');

        my $ua = Plagger::UserAgent->new;
        my $response = $ua->mirror($uri => $file);
        if ($response->is_error) {
            $context->log(error => "GET $uri failed: " . $response->status_line);
            return;
        }

        $context->log(info => "Downloaded $uri to $file");
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
                if( $data->{date} and $data->{artist} ){
                    my $dt = DateTime::Format::W3CDTF->parse_datetime($data->{date});
                    unless ($dt) {
                        $context->log( warn => "Can't parse $data->{date}");
                        next;
                    }
                    if( !defined $self->conf->{duration} or $dt->epoch > time - $self->conf->{duration} * 60 ){
                        my $entry = Plagger::Entry->new;
                        $entry->date(Plagger::Date->from_epoch($dt->epoch));

                        # author
                        $entry->author($data->{artist});

                        # title
                        my $title = $self->conf->{title_format};
                        $title = '%track - %artist' unless $title;
                        $title =~ s/%artist/$data->{artist}/;
                        $title =~ s/%album/$data->{album}/;
                        $title =~ s/%track/$data->{track}/;
                        $entry->title($title);

                        # search aws
                        if($self->conf->{aws_developer_token}){
                            my $item = $self->search_aws($context, $data->{artist}, $data->{album});
                            if($item){
                                $entry->link($item->url);
                                $entry->icon({ url => $item->ImageUrlSmall });
                                $entry->body($item->ProductDescription);
                                $entry->summary($item->ProductDescription);
                            }
                        }

                        for my $key (keys %$data){
                            $entry->meta->{$key} = $data->{$key};
                        }

                        $context->log( debug => $data->{artist} . ' ' . $data->{track});

                        $feed->add_entry($entry);
                    }
                }
                $data = {};
            };
    }

    $context->update->add($feed);
}

sub search_aws {
    my($self, $context, $artist, $album) = @_;
    $context->log( info => "Searching $artist - $album on Amazon...");
    my $attr;
    $attr->{token}  = $self->conf->{aws_developer_token};
    $attr->{locale} = $self->conf->{aws_locale};
    $attr->{affiliate_id} = $self->conf->{aws_associate_id};

    my $ua = Net::Amazon->new(%$attr);

    my $keyword = encode("UTF-8", "$artist $album");
    my $req = Net::Amazon::Request::Keyword->new(
        keyword => $keyword,
        mode    => 'music'. $self->conf->{aws_locale},
    );

    my $response = $ua->request($req);
    my $item = ($response->properties())[0];
    return $item;
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
      title_format: %track - %artist
      aws_developer_token: XXXXXXXXXXXXXXXXXXXX
      aws_associate_id: xxxxxxxxxx-22
      aws_locale: jp

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

=item title_format

Set a title format of an entry.You can use %track, %artist and %album.

=item aws_developer_token

If you set this parameter, this plugin get information about a track from the Amazon web service.

=item aws_associate_id

Your Amazon associate ID.

=item aws_locale

Set a web service locale.

=back

=head1 AUTHOR

Gosuke Miyashita, E<lt>gosukenator@gmail.comE<gt>

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
