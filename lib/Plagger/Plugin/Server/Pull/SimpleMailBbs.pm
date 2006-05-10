package Plagger::Plugin::Server::Pull::SimpleMailBbs;
use strict;
use base qw( Plagger::Plugin::Server::Pull);

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'pull.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    $context->log(debug => "handle.");

    my $req = $args->{req}->protocol;
    return unless $req->mail_from && $req->body;

    my $title = 'no title';
    $title = $1 if $req->body =~ /^Subject: (.+?)[\r\n]/smo;

    my $feed = $args->{feed};
    my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S');
    my $entry = Plagger::Entry->new;
    $entry->link($feed->link . time);

    my $author = $req->mail_from;
    my $body   = $req->body;
    utf8::decode($title)  unless utf8::is_utf8($title);
    utf8::decode($author) unless utf8::is_utf8($author);
    utf8::decode($body)   unless utf8::is_utf8($body);
    $entry->title($title);
    $entry->author($author);
    $entry->body($body);

    my $dt = DateTime->from_epoch( epoch => time );
    $dt->set_time_zone($context->conf->{timezone});
    $entry->date( Plagger::Date->parse($format, $dt->ymd . ' ' . $dt->hms) );

    $feed->add_entry($entry);
}

1;
