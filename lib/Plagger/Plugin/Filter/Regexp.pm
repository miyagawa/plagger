package Plagger::Plugin::Filter::Regexp;
use strict;
use base qw( Plagger::Plugin );

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

    my $regexp = $self->conf->{regexp};
    unless ($regexp) {
        $context->log(error => "regexp is missing");
        return;
    }

    my $count;
    if ($self->conf->{text_only}) {
        ($count, $body) = $self->rewrite_text_only($body, $regexp);
    } else {
        ($count, $body) = $self->rewrite($body, $regexp);
    }

    if ($count) {
        $context->log(info => "Replaced $count time(s) using $regexp");
    }

    $args->{entry}->body($body);
}

sub rewrite {
    my($self, $body, $regexp) = @_;

    local $_ = $body;
    my $count = eval $regexp;

    if ($@) {
        Plagger->context->log(error => "Error: $@ in $regexp");
        return (0, $body);
    }

    return ($count, $_);
}

sub rewrite_text_only {
    my($self, $body, $regexp) = @_;
    require HTML::Parser;

    my($count, $output);

    my $p = HTML::Parser->new(api_version => 3);
    $p->handler( default => sub { $output .= $_[0] }, "text" );
    $p->handler( text => sub {
        my($c, $body) = $self->rewrite($_[0], $regexp);
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

Plagger::Plugin::Filter::Regexp - Rewrite entry body using regular expression

=head1 SYNOPSIS

  - module: Filter::Regexp
    config:
      regexp: s/Plagger/$1, the pluggable Aggregator/g
      text_only: 1

=head1 DESCRIPTION

This plugin applies regular expression to each entry body by using
C<eval>.

=head1 CONFIG

=over 4

=item text_only

When set to 1, uses HTML::Parser so that the regexp substition should
be applied only to HTML text part. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
