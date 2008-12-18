package Plagger::Plugin::Filter::Delicious;
use strict;
use base qw( Plagger::Plugin );

use JSON::Syck;
use Digest::MD5 qw(md5_hex);
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $interval = $self->conf->{interval} || 1;
    sleep $interval;

    my $md5  = md5_hex($args->{entry}->permalink);
    my $url = "http://feeds.delicious.com/feeds/json/url/data?hash=$md5";

    $self->log(info => "Going to fetch $url");

    my $ua  = Plagger::UserAgent->new;
    my $res = $ua->fetch($url);

    if ($res->is_error) {
        $self->log(error => "Fetch URL $url failed.");
        return;
    }
    
    my $data = JSON::Syck::Load($res->content);
    unless (ref $data eq 'ARRAY') {
        $self->log(error => "json parse error: $data");
        return;
    }
    my $h = @{$data}[0];

    for my $tag (keys %{$h->{top_tags}}) {
        $args->{entry}->add_tag($tag);
        $self->log(debug => "add tag $tag");
    }

    my $delicious_users = $h->{total_posts} || 0;
    $args->{entry}->meta->{delicious_rate} = rate_of_color($delicious_users);
    $args->{entry}->meta->{delicious_users} = $delicious_users;
    $args->{entry}->meta->{delicious_hash} = $h->{hash};
    $self->log(info => "set delicious_users to $delicious_users");
}

sub rate_of_color {
    my $n = shift;
    return 100 unless $n;
    int(log($n) / log(0.82) + 100);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Delicious - Fetch tags and users count from del.icio.us

=head1 SYNOPSIS

  - module: Filter::Delicious

=head1 DESCRIPTION

B<Note: this module is mostly untested and written just for a proof of
concept. If you run this on your box with real feeds, del.icio.us will
be likely to ban your IP. See http://del.icio.us/help/ for details.>

This plugin queries del.icio.us using its JSON API to get the tags
people added to the entries, and how many people bookmarked them.

Users count is stored in C<delicious_users> metadata of
Plagger::Entry, so that other plugins and smartfeeds can make use of.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://delicious.com/help/api>
L<http://delicious.com/help/feeds/>, L<http://delicious.com/help/html>

=cut
