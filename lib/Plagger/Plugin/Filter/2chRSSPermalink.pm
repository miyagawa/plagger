package Plagger::Plugin::Filter::2chRSSPermalink;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    if($args->{entry}->permalink =~ m|^http://rss\.s2ch\.net/|) {
        my $permalink = $args->{entry}->permalink;
        $permalink =~ s!rss\.s2ch\.net/test/\-/!!;
        $permalink =~ s!(2ch\.net/)!\1test/read.cgi/!;
        $args->{entry}->link($permalink);
        $context->log(info => "Permalink rewritten to $permalink");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::2chRSSPermalink - Fix 2ch rss permalink to HTML version

=head1 SYNOPSIS

  - module: Filter::2chRSSPermalink

=head1 DESCRIPTION

This plugin fixes 2ch RSS L<http://rss.s2ch.net/> permalink to HTML
version, rather than RSS URL.

=head1 AUTHOR

youpy

=head1 SEE ALSO

L<Plagger>

=cut

