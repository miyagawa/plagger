package Plagger::Plugin::Filter::FeedBurnerPermalink;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.entry.fixup' => \&fixup,
    );
}

sub fixup {
    my($self, $context, $args) = @_;

    # RSS 1.0 & 2.0
    if (my $orig_link = $args->{orig_entry}->{entry}->{'http://rssnamespace.org/feedburner/ext/1.0'}->{origLink}) {
        $args->{entry}->permalink($orig_link);
        $context->log(info => "Permalink rewritten to $orig_link");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FeedBurnerPermalink - Fix FeedBurner's permalink

=head1 SYNOPSIS

  - module: Filter::FeedBurnerPermalink

=head1 DESCRIPTION

Entries in FeedBurner feeds contain links to feedburner's URL
redirector and that breaks some plugins like social bookmarks
integration.

This plugin updates the C<< $entry->permalink >> with I<guid> value in
FeedBurner's feed, so it actually points to the permalink, rather than
redirector.

Note that C<< $entry->link >> will still point to the redirector.

=head1 AUTHOR

Masahiro Nagano

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.feedburner.com/>

=cut
