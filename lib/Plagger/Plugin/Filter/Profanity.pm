package Plagger::Plugin::Filter::Profanity;
use strict;
use base qw( Plagger::Plugin::Filter::Base );

use Regexp::Common qw(profanity_us);

our $RE = $RE{profanity}{us}{normal}{label}{-keep}{-dist=>3};
our @Bogus = ('!','@','$','*','%','#','~','=');

sub filter {
    my($self, $body) = @_;
    my $count = $body =~ s/$RE/bogus_string(length($1))/eg;
    return ($count, $body);
}

sub bogus_string {
    my $len = shift;
    return join '', map $Bogus[$_ % $#Bogus], 0..$len-1;
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

=item text_only

When set to 1, uses HTML::Parser to avoid replacing C<ttp://> inside
HTML attributes. Defaults to 0.

=back

=head1 AUTHOR

Matsuno Tokuhiro

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Parser>

=cut
