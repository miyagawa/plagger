package Plagger::Plugin::Filter::YahooBlogSearchPermalink;
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

Plagger::Plugin::Filter::YahooBlogSearchPermalink - Fix Yahoo! Blog Search permalink

=head1 SYNOPSIS

B<THIS MODULE IS DEPRECATED. USE Filter::TruePermalink INSTEAD>

  - module: Filter::YahooBlogSearchPermalink

=head1 DESCRIPTION

This plugin replaces Yahoo! Blog Search feed's redirector URL with
original target URL for entry permalinks. It works with
http://blog-search.yahoo.co.jp/search?p=* feeds.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://blog-search.yahoo.co.jp/>, L<Plagger::Plugin::Subscription::Planet>

=cut
