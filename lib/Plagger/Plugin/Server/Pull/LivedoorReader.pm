package Plagger::Plugin::Server::Pull::LivedoorReader;
use strict;
use base qw( Plagger::Plugin::Server::Pull );

use JSON;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'pull.publish' => \&handle,
        'pull.finalize' => \&finalize,
    );
}

sub dispatch_rule_on { 1 }

sub handle {
    my($self, $context, $args) = @_;

    $context->log(debug => "handle.");

    my $req = $args->{req}->protocol;
    return unless $req->uri->path =~ m!/(subs|unread)$!;
    $self->{mode} = $1;

    my $feed = $args->{feed};
    if ($self->{mode} eq 'subs') {
        my $unread = scalar(@{ $feed->entries });
        my @subs = ref($self->{data}) eq 'ARRAY' ? @{ $self->{data} } : ();
        push @subs, {
            icon => "http://image.reader.livedoor.com/img/icon/default.gif", # TODO
            subscribe_id => $feed->id,
            unread_count => $unread,
            folder => eval { ($feed->tags)[0]->name } || '',
            tags => [], # TODO
            rate => 0,
            modified_on => ($feed->updated ? $feed->updated->epoch : time),
            title => $feed->title,
            subscribers_count => 1,
        };
        $self->{data} = \@subs;
    } elsif ($self->{mode} eq 'unread') {
        return unless $req->cgi->param('subscribe_id') eq $feed->id;

        my $data;
        $data->{subscribe_id} = $feed->id;
        $data->{channel} = {
            link => $feed->link,
            error_count => 0,
            description => $feed->description,
            image => $feed->image,
            title => $feed->title,
            subscribers_count => 1,
            feedlink => $feed->url,
            expires => time + 300,
        };

        my @items;
        for my $entry ( $feed->entries ) {
            my $id = $entry->id;
            $entry->id('');
            push @items, {
                link => $entry->link,
                enclosure => undef,
                enclosure_type => undef,
                author => $entry->author,
                body => $entry->body,
                modified_on => ($entry->date ? $entry->date->epoch : time),
                created_on => ($entry->date ? $entry->date->epoch : time),
                category => eval { ($entry->tags)[0]->name } || undef,
                title => $entry->title,
                id => $entry->id_safe,
            };
            $entry->id($id);
        }
        $data->{items} = \@items;

        $self->{data} = $data;
    }
}

sub finalize {
    my($self, $context, $args) = @_;

    $context->log(debug => "finalize.");

    $args->{req}->protocol->body(objToJson($self->{data}));
    $args->{req}->protocol->content_type('text/javascript+json');
}
1;

