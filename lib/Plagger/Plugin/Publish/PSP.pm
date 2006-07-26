package Plagger::Plugin::Publish::PSP;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&add_feed,
        'publish.finalize' => \&finalize,
    );
}

sub add_feed {
    my($self, $context, $args) = @_;
    push @{ $self->{__feeds} }, $args->{feed};
}


sub finalize {
    my($self, $context) = @_;

    my $body = $self->templatize('psp.tt', { feeds => $self->{__feeds} });
    my $file = $self->conf->{output_file};

    $context->log(info => "Output HTML to $file");
    open my $out, ">:utf8", $file or $context->error("$file: $!");
    print $out $body;
    close $out;
}

1;

