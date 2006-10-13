package Plagger::Plugin::Summary::Auto;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&auto_summarize,
    );
}

sub auto_summarize {
    my($self, $context, $args) = @_;

    if ($args->{entry}->body && !$args->{entry}->summary) {
        # give plugins a chance
        my $summary = $context->run_hook_once('summarizer.summarize', {
            entry => $args->{entry},
            feed  => $args->{feed},
            text  => $args->{entry}->body,
        });
        $args->{entry}->summary($summary) if defined $summary;
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::Auto - Auto-create summary for entry without summary

=head1 SYNOPSIS

  - module: Summary::Auto

=head1 DESCRIPTION

This plugin automatically creates summary for entries without summary,
using Plagger::Util::summarize function. Summary::Auto is autoloaded
by core and you don't actually need to specify in config files.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
