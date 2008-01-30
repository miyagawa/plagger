package Plagger::Plugin::Publish::HatenaDiary;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use WWW::HatenaDiary;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'      => \&initialize,
        'publish.init'     => \&publish_init,
        'publish.entry'    => \&publish_entry,
        'publish.finalize' => \&publish_finalize,
    );
}

sub initialize {
    my($self, $context) = @_;
    my $config = {
        username => $self->conf->{username},
        password => $self->conf->{password},
        group    => $self->conf->{group},
        mech_opt => {
            agent => Plagger::UserAgent->new,
        },
    };
    $self->{diary} = WWW::HatenaDiary->new($config);
}

sub publish_init {
    my($self, $context, $args) = @_;
    local $@;
    eval { $self->{diary}->login };
    if ($@) {
        $context->log(error => $@);
        delete $self->{diary};
    }
}

sub publish_entry {
    my($self, $context, $args) = @_;
    return unless $self->{diary};

    my $body = $self->templatize('template.tt', $args);
    my $uri = $self->{diary}->create({
        title => encode_utf8( $args->{entry}->title_text ),
        body  => encode_utf8( $body ),
    });
    $context->log(debug => "Post entry success: $uri");

    my $sleeping_time = $self->conf->{interval} || 3;
    $context->log(info => "sleep $sleeping_time.");
    sleep( $sleeping_time );
}

sub publish_finalize {
    my($self, $context, $args) = @_;
    return unless $self->{diary};
    $self->{diary}->{login}->logout;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::HatenaDiary - Publish to HatenaDiary

=head1 SYNOPSIS

  - module: Publish::HatenaDiary
    config:
      username: hatena-id
      password: hatena-password

=head1 DESCRIPTION

This plugin sends feed entries to your Hatena Diary.

=head1 CONFIG

=over 4

=item username

Hatena username. Required.

=item password

Hatena password. Required.

=item group

Hatena group name. Optional.

=item interval

Optional.

=back

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<WWW::HatenaDiary>

=cut
