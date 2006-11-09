package Plagger::Plugin::Summary::AppleScript;
use strict;
use base qw( Plagger::Plugin );

use Mac::AppleScript qw(RunAppleScript);

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $result = 
    RunAppleScript(qq{summarize "@{[escape($args->{text}->plaintext)]}" in 1});
    if ($@) {
        $context->log(error => "AppleScript error: $@");
        return;
    }

    return fixquote($result); 
}

sub escape { $_[0] =~ s/"/\\"/mg; $_[0] }

sub fixquote {
    $_[0] =~ s/(?:\xC2\xA5|\\)"/"/mg; # delete YEN SIGN or BACKSLASH
    return substr $_[0], 1, length($_[0])-2; # strip quotation
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::AppleScript - use AppleScript summarize Command

=head1 SYNOPSIS

  - module: Summary::AppleScript

=head1 DESCRIPTION

This plugin uses AppleScript summarize command to generate summary off of
plaintext-ized body.

=head1 AUTHOR

Masafumi Otsune

=head1 SEE ALSO

L<Plagger>, L<Mac::AppleScript>

=cut
