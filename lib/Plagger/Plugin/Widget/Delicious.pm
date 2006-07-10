package Plagger::Plugin::Widget::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Encode;
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
    my $uri = URI->new('http://del.icio.us/post');

    my %query;
    $query{url}   = $entry->permalink;
    $query{title} = encode('utf-8', $entry->title);
    $query{tags}  = $self->conf->{tags} if $self->conf->{tags};
    $query{jump}  = 'doclose' if $self->conf->{one_click_post};

    $uri->query_form(%query, v => 4);

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url"><img src="http://del.icio.us/static/img/delicious.small.gif" alt="del.icio.us it!" style="border:0;vertical-align:middle" /></a>);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Widget::Delicious - Widget to post to del.icio.us

=head1 SYNOPSIS

  - module: Widget::Delicious

=head1 DESCRIPTION

This plugin creates a widget to post to del.icio.us in the Publish
modules output.

=head1 CONFIG

=over 4

=item tags

Preset tags to tag the post.

  tags: foo bar

will set I<foo bar> as a predefined tag to use. Optional.

=item one_click_post

Flag to indicate that clicking the widget will automatically post the
item, without showing the form. Defaults to 0. (Optional)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://del.icio.us/>

=cut
