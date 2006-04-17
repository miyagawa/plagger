package Plagger::Plugin::Filter::2chRSSPermalink;
use strict;
use base qw( Plagger::Plugin );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    Plagger->context->log(warn => $self->class_id . " is now deprecated. Use Filter::PermalinkNormalize");
    Plagger->context->autoload_plugin('Filter::PermalinkNormalize');
}

sub register { }

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::2chRSSPermalink - Fix 2ch rss permalink to HTML version

=head1 SYNOPSIS

B<THIS MODULE IS DEPRECATED. USE Filter::PermalinkNormalize INSTEAD>

  - module: Filter::2chRSSPermalink

=head1 DESCRIPTION

This plugin fixes 2ch RSS L<http://rss.s2ch.net/> permalink to HTML
version, rather than RSS URL.

=head1 AUTHOR

youpy

=head1 SEE ALSO

L<Plagger>

=cut

