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

Plagger::Plugin::Filter::Profanity - Profanity filter for entry body

=head1 SYNOPSIS

  - module: Filter::Profanity
    config:
      text_only: 1

=head1 DESCRIPTION

This plugin filters bad English terms into something like I<!@$~>
using Regexp::Common::profanity_us.

=head1 CONFIG

=over 4

=item text_only

When set to 1, uses HTML::Parser to avoid replacing bad terms inside
HTML tags.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Regexp::Common::profanity_us>

=cut
