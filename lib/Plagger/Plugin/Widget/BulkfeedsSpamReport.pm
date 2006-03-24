package Plagger::Plugin::Widget::BulkfeedsSpamReport;
use strict;
use base qw( Plagger::Plugin );

use HTML::Entities;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry.fixup' => \&add,
    );
}

sub add {
    my($self, $context, $args) = @_;
    $args->{entry}->add_widget($self);
}

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new('http://bulkfeeds.net/app/report_spam');
    $uri->query_form(url => $entry->link);

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url">Report as Splog</a>);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Widget::BulkfeedsSpamReport - Widget to report as Splog to Bulkfeeds

=head1 SYNOPSIS

  - module: Widget::BulkfeedsSpamReport

=head1 DESCRIPTION

This plugins puts a widget to report current feed (blog) as a Splog to
Bulkfeeds Blacklist.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://bulkfeeds.net/app/blacklist>

=cut
