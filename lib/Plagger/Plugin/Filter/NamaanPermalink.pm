package Plagger::Plugin::Filter::NamaanPermalink;
use strict;
use base qw( Plagger::Plugin );

use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    if ($entry->permalink =~ m!^http://www\.namaan\.net/rd\?!) {
        my %param = URI->new( $entry->permalink )->query_form;
        if ($param{url}) {
            $entry->permalink($param{url});
            $context->log(info => "Permalink rewritten to " . $param{url});
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::NamaanPermalink - Fix NAMAAN's permalink

=head1 SYNOPSIS

  - module: Filter::NamaanPermalink

=head1 DESCRIPTION

This plugin replaces NAMAAN's redirector URL with original target URL
for entry permalinks.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.namaan.net/>

=cut
