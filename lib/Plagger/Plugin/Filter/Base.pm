package Plagger::Plugin::Filter::Base;
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

    my $count;
    if ($self->conf->{text_only}) {
        ($count, $body) = $self->filter_textonly($body);
    } else {
        ($count, $body) = $self->filter($body);
    }

    if ($count) {
        $self->log(info => "Filtered $count occurence(s)");
    }

    $args->{entry}->body($body);
}

sub filter {
    my $self = shift;
    Plagger->context->error(ref($self) . " should override filter");
}

sub filter_textonly {
    my($self, $body) = @_;
    require HTML::Parser;

    my($count, $output);

    my $p = HTML::Parser->new(api_version => 3);
    $p->handler( default => sub { $output .= $_[0] }, "text" );
    $p->handler( text => sub {
        my($c, $body) = $self->filter($_[0]);
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

Plagger::Plugin::Filter::Base - Base filter class to handle HTML snippets

=head1 SYNOPSIS

  package Plagger::Plugin::Filter::Foo;
  use base qw( Plagger::Plugin::Filter::Base )

  sub filter {
      my($self, $body) = @_;

      # filter $body
      # store how many chunks are filtered into $count

      return ($count, $body);
  }

=head1 DESCRIPTION

Plagger::Plugin::Filter::Base is a base class for
Plagger::Plugin::Filter to handle entry body with as much care as
possible not to break HTML structure.

Your filter will support C<text_only> configuration by subclassing
this module:

  - module: Filter::Foo
    config:
      text_only: 1

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
