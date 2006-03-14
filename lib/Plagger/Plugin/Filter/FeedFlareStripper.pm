package Plagger::Plugin::Filter::FeedFlareStripper;
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

    my $body = $args->{entry}->body;
    if ($body =~ s!<div class="feedflare">.*?</div>!!) {
        $context->log(info => "Stripped FeedFlare on " . $args->{entry}->link);
        $args->{entry}->body($body);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FeedFlareStripper - Strip FeedFlare from feeds

=head1 SYNOPSIS

  - module: Filter::FeedFlareStripper

=head1 DESCRIPTION

This plugin strips FeedBurner's FeedFlare widget from feed content.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.feedburner.com/>

=cut
