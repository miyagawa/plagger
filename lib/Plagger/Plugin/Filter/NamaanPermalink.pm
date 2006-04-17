package Plagger::Plugin::Filter::NamaanPermalink;
use strict;
use base qw( Plagger::Plugin );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    Plagger->context->log(warn => $self->class_id . " is now deprecated. Use Filter::TruePermalink");
    Plagger->context->autoload_plugin('Filter::TruePermalink');
}

sub register { }

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::NamaanPermalink - Fix NAMAAN's permalink

=head1 SYNOPSIS

B<THIS MODULE IS DEPRECATED. USE Filter::TruePermalink INSTEAD>

  - module: Filter::NamaanPermalink

=head1 DESCRIPTION

This plugin replaces NAMAAN's redirector URL with original target URL
for entry permalinks.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.namaan.net/>

=cut
