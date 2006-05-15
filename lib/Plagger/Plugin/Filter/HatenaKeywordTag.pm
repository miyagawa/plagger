package Plagger::Plugin::Filter::HatenaKeywordTag;
use strict;
use base qw( Plagger::Plugin );
use Hatena::Keyword;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;
    my $title = $args->{entry}->title;
    my $body = $args->{entry}->body;
    Encode::_utf8_off($body); # Hatena::Keyword's Bug?
    my $keywords = Hatena::Keyword->extract($title . ' ' . $body);
    my @terms = sort { $a->refcount <=> $b->refcount } @$keywords;

    for my $term (@terms) {
        $args->{entry}->add_tag($term);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaKeywordTag - Hatena::Keyword API for auto-tagging

=head1 SYNOPSIS

  - module: Filter::HatenaKeywordTag
  - module: Filter::2chNewsokuTitle

=head1 DESCRIPTION

Hatena::Keyword API for auto-tagging

=head1 AUTHOR

Yuichi Tateno (id:secondlife)

=head1 SEE ALSO

L<Plagger>
L<Hatena::Keyword>

=cut
