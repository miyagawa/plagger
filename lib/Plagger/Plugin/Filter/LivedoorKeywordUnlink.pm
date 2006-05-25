package Plagger::Plugin::Filter::LivedoorKeywordUnlink;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;
    my $body = $args->{entry}->body;

    my $count = $body =~ s!<a .*?href="http://keyword\.livedoor\.com/w/.*?"[^>]*>(.*?)</a>!$1!g;

    if ($count) {
        $context->log(info => "Stripped $count links to Livedoor Keyword");
    }

    $args->{entry}->body($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::LivedoorKeywordUnlink - Strip Livedoor keyword links from fulltext feeds

=head1 SYNOPSIS

  - module: Filter::LivedoorKeywordUnlink

=head1 DESCRIPTION

This plugin strips link toLivedoor keyword links in feeds.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HatenaDiaryKeywordUnlink>

=cut
