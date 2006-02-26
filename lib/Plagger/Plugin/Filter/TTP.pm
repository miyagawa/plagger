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

    local @URI::ttp::ISA = qw(URI::http);

    my $finder = URI::Find->new(sub {
        my ($uri, $orig_uri) = @_;
        return ($uri->scheme eq 'ttp') ? qq{<a href="h$orig_uri">$orig_uri</a>} : $orig_uri;
    });
    $finder->find(\$body);

    $args->{entry}->body($body);
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

=head1 AUTHOR

Matsuno Tokuhiro

=head1 SEE ALSO

L<Plagger>

=cut
