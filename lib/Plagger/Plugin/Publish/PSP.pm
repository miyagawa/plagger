package Plagger::Plugin::Publish::PSP;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.notify' => \&notify,
    );
}

sub notify {
    my($self, $context, $feed) = @_;

    my @items = $feed->entries;
    $self->store_items_as_html($context, $feed, \@items);
}

sub store_items_as_html {
    my($self, $context, $feed, $items) = @_;
    $feed->{title} = $feed->{title} || '(no-title)';
    my $body =  $self->templatize($context, $feed, $items);
    $self->do_store_item($context, $feed, $body);
}

sub do_store_item {
    my($self, $context, $feed, $body) = @_;

    my $cfg = $self->conf;
    my $file= $cfg->{output_file};
    $context->log(warn => "Store $feed->{title} to $file");

    open(FH, ">:utf8", $file) or die $!;
    print FH $body;
    close (FH);
}

sub templatize {
    my($self, $context, $feed, $items) = @_;
    my $tt = $context->template();
    $tt->process('psp_notify.tt', {
        feed => $feed,
        items => $items,
        cfg  => $self->conf,
        utf8 => sub { encode("utf-8", $_[0]) }
    }, \my $out) or die $tt->error;
    $out;
}
1;

