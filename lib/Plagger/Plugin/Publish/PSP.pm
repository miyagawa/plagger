package Plagger::Plugin::Publish::PSP;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.notify'   => \&notify,
        'publish.finalize' => \&finalize,
    );
}

sub notify {
    my($self, $context, $feed) = @_;

    $feed->{title} = $feed->{title} || '(no-title)';
    $context->log(warn => "Store $feed->{title}");
    push @{ $self->{__feeds} }, $feed;
}


sub finalize {
    my($self, $context) = @_;

    my $body = $self->templatize($context, $self->{__feeds});
    my $cfg  = $self->conf;
    my $file = $cfg->{output_file};

    open(FH, ">:utf8", $file) or die $!;
    print FH $body;
    close (FH);
}

sub templatize {
    my($self, $context, $feeds) = @_;
    my $tt = $context->template();
    $tt->process('psp.tt', {
        feeds => $feeds,
    }, \my $out) or die $tt->error;
    $out;
}
1;

