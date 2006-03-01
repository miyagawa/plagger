package Plagger::Plugin::Filter::TTP;
use strict;
use base qw( Plagger::Plugin );

use URI::Find;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;
    my $body = $args->{entry}->body;

    my $count;
    if ($self->conf->{html_paranoia}) {
        ($count, $body) = $self->paranoia_rewrite($body);
    } else {
        ($count, $body) = $self->rewrite_ttp($body);
    }

    if ($count) {
        $context->log(info => "Rewrite $count ttp:// link(s) to http://");
    }

    $args->{entry}->body($body);
}

sub rewrite_ttp {
    my($self, $body) = @_;

    local @URI::ttp::ISA = qw(URI::http);

    my $count = 0;
    my $finder = URI::Find->new(sub {
        my ($uri, $orig_uri) = @_;
        if ($uri->scheme eq 'ttp') {
            $count++;
            return qq{<a href="h$orig_uri">$orig_uri</a>};
        } else {
            return $orig_uri;
        }
    });

    $finder->find(\$body);
    ($count, $body);
}

sub paranoia_rewrite {
    my($self, $body) = @_;
    require HTML::Parser;

    my($count, $output);

    my $p = HTML::Parser->new(api_version => 3);
    $p->handler( default => sub { $output .= $_[0] }, "text" );
    $p->handler( text => sub {
        my($c, $body) = $self->rewrite_ttp($_[0]);
        $count  += $c;
        $output .= $body;
    }, "text");

    $p->parse($body);
    $p->eof;

    ($count, $output);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::TTP - Replace ttp:// with http://

=head1 SYNOPSIS

  - module: Filter::TTP

=head1 DESCRIPTION

This plugin replaces C<ttp://> with C<http://>. C<ttp://> is a widely
adopted way of linking an URL without leaking a referer.

=head1 CONFIG

=over 4

=item html_paranoia

When set to 1, uses HTML::Parser to avoid replacing C<ttp://> inside
HTML elements. Defaults to 0.

=back

=head1 AUTHOR

Matsuno Tokuhiro

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
