package Plagger::Plugin::Publish::MT;
use strict;
use warnings;
use base qw (Plagger::Plugin);

our $VERSION = 0.01;

use Net::MovableType;
use SOAP::Transport::HTTP; # need to preload

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub mt {
    my $self = shift;

    # hack to replace XMLRPC::Lite internal UserAgent class so we can add credentials
    local $SOAP::Transport::HTTP::Client::USERAGENT_CLASS = "Plagger::UserAgent";

    return $self->{mt} if $self->{mt};
    $self->{mt} = Net::MovableType->new($self->conf->{rsd});
    unless (defined $self->{mt}) {
        die "couldn't create MT object: " . Net::MovableType->errstr;
    }
    $self->{mt}->username($self->conf->{username});
    $self->{mt}->password($self->conf->{password});
    $self->{mt}->blogId($self->conf->{blog_id} || 1);
    return $self->{mt};
}

sub feed {
    my ($self, $context, $args) = @_;
    my $body = $self->templatize(
        $self->{conf}->{template} || 'mt.tt',
        { feed => $args->{feed} }
    );
    eval {
        my $id = $self->post_to_mt(
            title => $args->{feed}->title,
            body  => $body,
        );
        my $post = $self->mt->getPost($id);
        $context->log(info => "Successfuly posted: $post->{link}");
    }; if (my $err = $@) {
        $err = $err->[0] if ref $err && ref $err eq 'ARRAY';
        $context->error($err);
    }
}

sub post_to_mt {
    my $self = shift;
    my %args = @_;
    my $mt = $self->mt;

    # FIXME: Can I use XML::RPC::Lite without hack?
    Encode::_utf8_off($args{title});
    Encode::_utf8_off($args{body});

    my $id = $mt->newPost({
        title       => $self->conf->{title} || $args{title} || '',
        description => $args{body} || '',
    }) or die $mt->errstr;
    $mt->publishPost($id);
    $id;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::MT - Post feeds to Movable Type

=head1 SYNOPSIS

  - module: Publish::MT
    config:
      rsd: http://www.example.com/mt/rsd.xml
      username: Melody
      password: Nelson
      blog_id: 1
      title: "Today's post from Plagger"

=head1 CONFIG

=head2 rsd

URL of rsd.xml on your Movable Type, which includes your API
end-point.

=head2 username

Your username on Movable Type.

=head2 password

Specify your password. Note that it's not your login password but API
password.

=head2 blog_id

Your blog's ID number.

=head2 title

You can specify the title of new entry which will be defaults to
title of the feed.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>, L<Net::MovableType>

=cut
