package Plagger::Plugin::Subscription::HatenaRSS;
use strict;
use base qw( Plagger::Plugin::Subscription::OPML );

use WWW::Mechanize;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $start = "https://www.hatena.ne.jp/login?backurl=http%3A%2F%2Fr.hatena.ne.jp%2F";

    # TODO: we should save the cookie and reuse
    my $mech = WWW::Mechanize->new;
    $mech->get($start);

    $mech->submit_form(
        fields => {
            key      => $self->conf->{username},
            password => $self->conf->{password},
        },
    );

    if ( $mech->content =~ m!<div class="erorr">! ) {
        $context->log(error => "Login to HatenaRSS failed.");
    }

    $context->log(info => "Login to HatenaRSS succeed.");

    $mech->get("http://r.hatena.ne.jp/miyagawa/config");

    # HatenaRSS config has two different 'opml' forms :/
    # so we loop through it and use the latter one
    for my $form ($mech->forms) {
        $mech->{form} = $form if $form->attr('name') eq 'opml';
    }

    $mech->submit_form();

    my $opml = $mech->content;
    $context->log(info => "Exported OPML: " . length($opml) . " bytes");

    $self->load_opml($context, \$opml);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscrption::HatenaRSS - HatenaRSS Subscription via OPML

=head1 SYNOPSIS

  - module: Subscription::HatenaRSS
    config:
      username: example
      password: xxxxxxxx

=head1 DESCRIPTION

This plugin creates Subscription by fetching Hatena RSS
L<http://r.hatena.ne.jp> OPML by HTTP. Since Hatena RSS OPML export
requires login state, it uses WWW::Mechanize module to emulate the
browser's login authentication procedure.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::OPML>, L<WWW::Mechanize>

=cut
