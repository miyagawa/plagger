package Plagger::Plugin::Widget::Simple;
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

    my $widget = Plagger::Plugin::Widget::Simple::Widget->new;
    $widget->{feed}   = $args->{entry}->source || $args->{feed};
    $widget->{plugin} = $self;

    $args->{entry}->add_widget($widget);
}

package Plagger::Plugin::Widget::Simple::Widget;

sub new { bless {}, shift }

sub feed { shift->{feed} }
sub plugin { shift->{plugin} }

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new($self->plugin->conf->{link});

    my $args = { entry => $entry, feed => $self->{feed} };

    if (my $query = $self->plugin->conf->{query}) {
        my @query = map {
            if ($query->{$_} =~ /\$/) { # DWIM
                $query->{$_} = eval $query->{$_};
                Plagger->context->log(error => $@) if $@;
            }
            ($_ => $query->{$_});
        } sort keys %$query;
        $uri->query_form(@query);
    }

    my $url = HTML::Entities::encode($uri->as_string);

    my $content;
    if ($self->plugin->conf->{content_dynamic}) {
        $content = $self->plugin->templatize(\$self->plugin->conf->{content_dynamic}, $args);
    } else {
        $content = $self->plugin->conf->{content};
    }

    return qq(<a href="$url">$content</a>);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Widget::Simple - Simple widget creation using config

=head1 SYNOPSIS

  - module: Widget::Simple
    config:
      link: http://www.example.com/
      content_dynamic: "Entry from [% entry.author %]"

=head1 DESCRIPTION

Widget::Simple is a plugin that allows you to write your own widget
using a simple configuration file.

=head1 CONFIG

=over 4

=item link

  link: http://example.com/add

URL that the widget links to. Required.

=item query

  query:
    version: 4
    url: $args->{entry}->url

Query parameter to append to the URL. If the value contains C<$>,
it'll be automatically eval()ed. Optional.

=item content

  content: <img src="http://example.com/img.gif" alt="foo" />

Content to display in a widget. HTML tags will be displayed as is and
thus any HTML meta characters have to be escaped. Required, if you
don't use I<content_dynamic>.

=item content_dynamic

  content_dynamic: "Entry from [% entry.author | html %]"

If you want to dyncamically generate the content of widget, use
I<content_dynamic> instead. Value of the content_dynamic is compiled
and rendered using Template-Toolkit. Required, if you don't use
I<content>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
