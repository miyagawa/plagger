package Plagger::Plugin::Filter::TTP;
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
    $body =~ s!\b(ttp://)!h$1!g;
    $args->{entry}->body($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::TTP - auto link the ttp://

=head1 SYNOPSIS

  - module: Filter::TTP

=head1 DESCRIPTION

ttp:// => http://

=head1 AUTHOR

Matsuno Tokuhiro

=head1 SEE ALSO

L<Plagger>

=cut
