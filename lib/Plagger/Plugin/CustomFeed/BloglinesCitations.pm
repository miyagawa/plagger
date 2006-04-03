package Plagger::Plugin::CustomFeed::BloglinesCitations;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Plagger::UserAgent;
use Plagger::Util qw( decode_content );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    if ($args->{feed}->url =~ m!^http://bloglines\.com/citations\?url=!) {
        $self->aggregate($context, $args);
        return 1;
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res = $agent->fetch($url, $self);

    if ($res->is_error) {
        $context->log(error => "GET $url failed: " . $res->status_code);
        return;
    }

    my $content = decode_content($res);

    my %query = URI->new($url)->query_form;
    my $orig_url = $query{url};

    my $feed = Plagger::Feed->new;
    $feed->title("Bloglines: Pages linking to $orig_url");
    $feed->link($url);

    my $re = <<'RE';
<tr><td valign="top" align="right">
<span class="blogtitle">\d+\.</span>
</td><td valign="top" align="left">
<span class="blogtitle"><a href="(.*?)">(.*?)</a></span><br>
From: <a href="(.*?)">(.*?)</a>
<br>
(.*?)<br>
<font color=\#008000>.*? - (\w+, \w+ \d+ \d{4} \d\d?:\d\d (?:AM|PM))</font> -
RE

    $content =~ s/\r\n/\n/g;

    my @matches;
    my @keys = qw( link title feed_link feed_title body date );
    my $date_format = "%a, %b %d %Y %I:%M %p";

    while ($content =~ /$re/gs) {
        my $data;
        @{$data}{@keys} = ($1, $2, $3, $4, $5, $6);
        $data->{date} = Plagger::Date->strptime($date_format, $data->{date});

        my $entry = Plagger::Entry->new;
        $entry->title($data->{title});
        $entry->link($data->{link});
        $entry->date($data->{date});
        $entry->body($data->{body});

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::BloglinesCitations - Custom feed for Bloglines Citations

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - http://bloglines.com/citations?url=http%3A//blog.bulknews.net/

  - module: CustomFeed::BloglinesCitations

=head1 DESCRIPTION

This plugin creates a custom feed off of Bloglines Citations page.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://bloglines.com/citations>

=cut
