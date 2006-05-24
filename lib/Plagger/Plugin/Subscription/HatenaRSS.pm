package Plagger::Plugin::Subscription::HatenaRSS;
use strict;
use base qw( Plagger::Plugin::Subscription::OPML );

use Plagger::Mechanize;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $username = $self->conf->{username}
        or $context->error("username is missing");

    my $mech = Plagger::Mechanize->new(cookie_jar => $self->cookie_jar);
    $mech->get("http://r.hatena.ne.jp/$username/opml");

    if ($mech->content !~ /<opml version/) {
        $mech->get("https://www.hatena.ne.jp/login?backurl=http%3A%2F%2Fr.hatena.ne.jp%2F");
        $mech->submit_form(
            fields => {
                key      => $username,
                password => $self->conf->{password},
            },
        );

        if ( $mech->content =~ m!<div class="error">! ) {
            $context->log(error => "Login to HatenaRSS failed.");
            return;
        }
    }

    $context->log(info => "Login to HatenaRSS succeed.");

    my $opml = $mech->content;
    $context->log(info => "Exported OPML: " . length($opml) . " bytes");

    $self->load_opml($context, \$opml);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::HatenaRSS - HatenaRSS Subscription via OPML

=head1 SYNOPSIS

  - module: Subscription::HatenaRSS
    config:
      username: example

=head1 DESCRIPTION

This plugin creates Subscription by fetching Hatena RSS
L<http://r.hatena.ne.jp> OPML by HTTP.

If your OPML is shared public (which is default), you don't have to
pass password to the config. Also, even if you OPML is private, you
can share Cookies with your favorite browser like Firefox, using

  global:
    user_agent:
      cookies: /path/to/cookies.txt

so that you don't have to pass password to the config, again.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::OPML>, L<WWW::Mechanize>

=cut
