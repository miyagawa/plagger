package Plagger::Plugin::Filter::BloglinesContentNormalize;
use strict;
use base qw( Plagger::Plugin );

our $Pattern = qr! target=_blank class=blines[23] title="Link (?:outside of|to another page in) this blog"!;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $body = $args->{entry}->body;
    my $c  = $body =~ s!$Pattern!!g;
       $c += $body =~ s!&#13;!!g;
    if ($c) {
        $context->log(info => "Stripped Bloglines extra attributes on " . $args->{entry}->link);
        $args->{entry}->body($body);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::BloglinesContentNormalize - Strip extra attributes in Bloglines body

=head1 SYNOPSIS

  - module: Filter::BloglinesContentNormalize

=head1 DESCRIPTION

This plugin strips extra attributes contained in Bloglines entry feed, e.g.

  target=_blank class=blines2 title="Link to another page in this blog"
  target=_blank class=blines3 title="Link outside of this blog"

This plugin is autoloaded via Filter::StripRSSAd plugin.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::StripRSSAd>, L<http://www.bloglines.com/>

=cut
