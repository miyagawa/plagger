package Plagger::Plugin::Filter::HTMLScrubber;
use strict;
use base qw( Plagger::Plugin );

use HTML::Scrubber;

sub rules {
    return(
        img => {
            src => qr{^http://},    # only URL with http://
            alt => 1,               # alt attributes allowed
            '*' => 0,               # deny all others
        },
        style  => 0,
        script => 0,
    );
}

sub default {
    return(
        '*'    => 1,                        # default rule, allow all attributes
        'href' => qr{^(?!(?:java)?script)}i,
        'src'  => qr{^(?!(?:java)?script)}i,
        'cite'     => '(?i-xsm:^(?!(?:java)?script))',
        'language' => 0,
        'name'        => 1,                 # could be sneaky, but hey ;)
        'onblur'      => 0,
        'onchange'    => 0,
        'onclick'     => 0,
        'ondblclick'  => 0,
        'onerror'     => 0,
        'onfocus'     => 0,
        'onkeydown'   => 0,
        'onkeypress'  => 0,
        'onkeyup'     => 0,
        'onload'      => 0,
        'onmousedown' => 0,
        'onmousemove' => 0,
        'onmouseout'  => 0,
        'onmouseover' => 0,
        'onmouseup'   => 0,
        'onreset'     => 0,
        'onselect'    => 0,
        'onsubmit'    => 0,
        'onunload'    => 0,
        'src'         => 0,
        'type'        => 0,
        'style'       => 0,
    );
}

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook( $self, 'update.entry.fixup' => \&update, );

    $self->{scrubber} = do {
        my $scrubber = HTML::Scrubber->new;
        my $config   = $self->conf;

        my ( %rules, %default );
        unless ( delete $config->{no_default_configs} ) {
            %rules   = $self->rules;
            %default = $self->default;
        }
        $scrubber->rules( %rules, %{ delete $config->{rules} || {} } );
        $scrubber->default(1, { %default, %{ delete $config->{default} || {} } });

        while ( my ( $method, $arg ) = each %$config ) {
            eval {
                $scrubber->$method(
                      ref $arg eq 'ARRAY' ? @$arg
                    : ref $arg eq 'HASH'  ? %$arg
                    : $arg );
            };
            $context->error(qq/Invalid method call "$method": $@/) if $@;
        }

        $scrubber;
    };
}

sub update {
    my ( $self, $context, $args ) = @_;

    if (defined $args->{entry}->body) {
        my $body = $self->{scrubber}->scrub( $args->{entry}->body );
        $args->{entry}->body($body);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HTMLScrubber - Scrub feed content

=head1 SYNOPSIS

  - module: Filter::HTMLScrubber
    config:
      rules:
        style: 0
        script: 0

=head1 DESCRIPTION

This plugin scrubs feed content using L<HTML::Scrubber>.

All config parameters (except 'no_default_configs') are implemented as
HTML::Scrubber's method: value.  For example, if you write:

    method: value

in the config: section, this plugin will automatically turn the config
into the method call:

    $scrubber->method('value');

See L<HTML::Scrubber> document for details.

=head1 CONFIG

=over 4

=item no_default_configs

Some rules and default config parameters are set by default. See I<rules>
and I<default> methods defined in this module code for details.

If you don't need these settings, use C<no_default_configs>

   no_detault_configs: 1

Defaults to 0, which means it uses the default (somewhat secure) config.

=back

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Scrubber>

=cut
