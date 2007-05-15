package Plagger::Plugin::Publish::Buzzurl;
use strict;
use base qw( Plagger::Plugin );

use WebService::BuzzurlAPI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'   => \&initialize,
        'publish.entry' => \&add_entry,
    );
}

sub rule_hook { 'publish.entry' }

sub initialize {
    my ($self, $context, $args) = @_;
    $self->{buzzurl} = WebService::BuzzurlAPI->new({
        email    => $self->conf->{usermail},
        password => $self->conf->{password},
    });
}

sub add_entry {
    my($self, $context, $args) = @_;

    my $params = {
        url     => $args->{entry}->link,
        title   => $args->{entry}->title,
        keyword => $args->{entry}->tags,
    };

    if ($self->conf->{post_body}) {
        $params->{comment} = $args->{entry}->body_text,
    }

    my $res = $self->{buzzurl}->add($params);

    if ($res->is_success) {
        $context->log(info  => "Post entry success :" . $res->json->{status});
    }else{
        $context->log(error => $res->errstr);
    }

    my $sleeping_time = $self->conf->{interval} || 2;
    $context->log(info => "Post entry success. sleep $sleeping_time.");
    sleep( $sleeping_time );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Buzzurl - Post to Buzzurl automatically

=head1 SYNOPSIS

  - module: Publish::Buzzurl
    config:
      usermail: your-email
      password: your-password
      interval: 2
      post_body: 1

=head1 DESCRIPTION

This plugin posts feed updates to Buzzurl, using its REST API.

=head1 CONFIGURATION

=over 4

=item usermail, password

Your login and password for logging in Buzzurl

=item interval

Interval (as seconds) to sleep after posting each bookmark. Defaults to 2.

=item post_body

A flag to post entry's body as extended field for Buzzurl. Defaults to 0.

=back

=cut

=head1 AUTHOR

Masafumi Otsune

=head1 SEE ALSO

L<Plagger>, L<WebService::BuzzurlAPI>, L<http://buzzurl.jp/>,
L<http://labs.ecnavi.jp/developer/buzzurl/api/>

=cut
