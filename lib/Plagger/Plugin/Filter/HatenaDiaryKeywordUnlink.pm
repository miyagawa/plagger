package Plagger::Plugin::Filter::HatenaDiaryKeywordUnlink;
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

    my $count = $body =~ s!<a class="o?keyword" href="http://(?:d|[\w\-]+\.g)\.hatena\.ne\.jp/keyword/.*?"[^>]*?>(.*?)</a>!$1!g;

    if ($count) {
        $context->log(info => "Stripped $count links to Hatena Diary Keywords");
    }

    $args->{entry}->body($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaDiaryKeywordUnlink - Strip Hatena Diary keyword links from fulltext feeds

=head1 SYNOPSIS

  - module: Filter::HatenaDiaryKeywordUnlink

=head1 DESCRIPTION

This plugin strips link to Hatena Diary keyword links in feeds. By
default Hatena Diary feeds don't contain links to keywords, but with
Filter::EntryFullText plugin it might contain them.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
