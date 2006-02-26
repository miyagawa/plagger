package Plagger::Plugin::Publish::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Net::Delicious;
use URI::Escape qw(uri_escape uri_escape_utf8);

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
    my ($self, $context, $args) = @_;

    my @tags = @{$args->{entry}->tags};
    my $tag_string;
    if (scalar(@tags)) {
        $tag_string = uri_escape_utf8( join ' ', @tags );
    } else {
        $tag_string = "";
    }

    $self->{delicious}->add_post({
        url         => uri_escape( $args->{entry}->link ),
        description => uri_escape_utf8( $args->{entry}->title ),
        extended    => uri_escape_utf8( $args->{entry}->body ),
        tags        => $tag_string,
    });

    my $sleeping_time = $context->conf->{interval} || 4;
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

=head1 DESCRIPTION

This plugin posts feed updates to del.icio.us, using its REST API.

=head1 AUTHOR

Tsutomu Koyacho

=head1 SEE ALSO

L<Plagger>, L<Net::Delicious>, L<http://del.icio.us/>

=cut
