package Plagger::Plugin::Server::Pull::SimpleBbs;
use strict;
use base qw( Plagger::Plugin::Server::Pull);

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'pull.handle' => \&handle,
        'pull.publish' => \&publish,
    );
}

sub dispatch_rule_on { 1 }

sub handle {
    my($self, $context, $args) = @_;

    $context->log(debug => "handle.");

    my $req = $args->{req}->protocol;
    my $r = $req->cgi;
    return unless $r->param('title') || $r->param('body');

    my $feed = $args->{feed};
    my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M:%S');
    my $entry = Plagger::Entry->new;
    $entry->link($feed->link . time);

    my $title  = $r->param('title') || 'no title';
    my $author = $r->param('name') || 'no name';
    my $body   = $r->param('body') || '';
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

    my $u = $args->{req}->protocol->uri;
    $args->{req}->protocol->add_headders_out(Location => sprintf("%s://%s:%s%s", $u->scheme, $u->host, $u->port, $u->path));
}

sub publish {
    my($self, $context, $args) = @_;

    $context->log(debug => "finalize.");

    my $feed = $args->{feed};
    my @entries = $feed->entries;
    for my $entry (reverse @entries) {
        $feed->delete_entry($entry);
        $feed->add_entry($entry);
    }
    $args->{req}->protocol->body($self->templatize($context, $args));
}

sub templatize {
    my($self, $context, $opt) = @_;
    my $tt = $context->template();
    $tt->process('index.tt', $opt, \my $out) or $context->error($tt->error);
    $out;
}

1;
