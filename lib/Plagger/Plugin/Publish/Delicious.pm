package Plagger::Plugin::Publish::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Net::Delicious;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.init'        => \&initialize,
        'publish.entry.fixup' => \&add_entry,
    );
}

sub initialize {
    my ($self, $context, $args) = @_;
    $self->{delicious} = Net::Delicious->new({
        user => $self->conf->{username},
        pswd => $self->conf->{password},
    });
}

sub add_entry {
    my($self, $context, $args) = @_;

    my @tags = @{$args->{entry}->tags};
    my $tag_string = @tags ? join(' ', @tags) : '';

    my $params = {
        url         => $args->{entry}->link,
        description => encode('utf-8', $args->{entry}->title),
        tags        => encode('utf-8', $tag_string),
    };

    if ($self->conf->{post_body}) {
        $params->{extended} = encode('utf-8', $args->{entry}->body_text),
    }

    $self->{delicious}->add_post($params);

    my $sleeping_time = $self->conf->{interval} || 3;
    $context->log(info => "Post entry success. sleep $sleeping_time.");
    sleep( $sleeping_time );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Delicious - Post to del.icio.us automatically

=head1 SYNOPSIS

  - module: Publish::Delicious
    config:
      username: your-username
      password: your-password
      interval: 2
      post_body: 1

=head1 DESCRIPTION

This plugin posts feed updates to del.icio.us, using its REST API.

=head1 CONFIGURATION

=over 4

=item username, password

Your login and password for logging in del.icio.us.

=item interval

Interval (as seconds) to sleep after posting each bookmark. Defaults to 3.

=item post_body

A flag to post entry's body as extended field for del.icio.us. Defaults to 0.

=back

=cut

=head1 AUTHOR

Tsutomu Koyacho

=head1 SEE ALSO

L<Plagger>, L<Net::Delicious>, L<http://del.icio.us/>

=cut
