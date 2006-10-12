package Plagger::Plugin::Filter::DeliciousFeedTags;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Tag;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    return unless $args->{feed}->url =~ m!^http://del\.icio\.us/rss/!;

    $context->log(debug => "Fixing del.icio.us tags " . $args->{entry}->tags->[0]);

    my @tags = Plagger::Tag->parse($args->{entry}->tags->[0]);
    $args->{entry}->tags(\@tags);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::DeliciousFeedTags - Fix del.icio.us tags

=head1 SYNOPSIS

  - module: Filter::DeliciousFeedTags

=head1 DESCRIPTION

del.icio.us RSS feeds contain information to "tags", but they're
encoded in a single I<dc:subject> element as whitespace-separated,
like C<foo bar baz>.

This plugin walks through feeds matching with
I<http://del.icio.us/rss/*> and fixes the tags information by
splitting them out.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://del.icio.us/>

=cut
