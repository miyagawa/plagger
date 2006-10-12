package Plagger::Plugin::Filter::Pipe;
use strict;
use warnings;
use base qw( Plagger::Plugin );
use Encode;
use HTML::Entities;
use IPC::Run qw( start pump finish timeout );
use Text::ParseWords qw(shellwords);

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    local $| = 1;
    eval {
        local $SIG{ALRM} = sub { die "ALRM" };
        alarm($self->conf->{timeout} || 10);

        my ($in, $out, $err);
        my $h = start [shellwords($self->conf->{command})], \$in, \$out, \$err, timeout(10);

        my $meth = $self->conf->{text_only} ? 'rewrite_text_only' : 'rewrite';
        my $body = $self->$meth($args->{entry}->body, $h, \$in, \$out);
        $args->{entry}->body( $body );
        $h->finish;

        alarm 0;
    };
    if ($@) {
        if ($@ =~ /ALRM/) {
            $context->log(error => "filter timeout");
            return;
        } else {
            die $@; # rethrow
        }
    }
}

sub rewrite {
    my ($self, $body, $h, $in_ref, $out_ref) = @_;

    $$out_ref = '';
    $$in_ref .= encode($self->conf->{encoding}, $body);
    $h->pump while $$in_ref;
    $h->pump until $$out_ref;

    return decode($self->conf->{encoding}, $$out_ref);
}

sub rewrite_text_only {
    my ($self, $body, $h, $in_ref, $out_ref) = @_;
    require HTML::Parser;

    my $output;

    my $p = HTML::Parser->new(api_version => 3);
    $p->handler( default => sub { $output .= $_[0] }, "text" );
    $p->handler( text => sub {
        my $text = $self->rewrite(decode_entities("$_[0]\n"), $h, $in_ref, $out_ref);
        $text =~ s/\n$//g;
        $output .= encode_entities($text, q("<>&));
    }, "text");

    $p->parse($body);
    $p->eof;

    return $output;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::Pipe - Filtering with pipe

=head1 SYNOPSIS

  - module: Filter::Pipe
    config:
      command: /usr/bin/kakasi -Ha -Ka -Ja -Ea -ka -u
      encoding: euc-jp
      text_only: 1

=head1 DESCRIPTION

This plugin filtering feed with other program using a pipe.

=head1 CONFIG

=over 4

=item text_only

When set to 1, uses HTML::Parser so that the regexp substitution should
be applied only to HTML text part. Defaults to 0.

=back

=head1 AUTHOR

Tokuhiro Matsuno, Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>, L<IPC::Run>

=cut
