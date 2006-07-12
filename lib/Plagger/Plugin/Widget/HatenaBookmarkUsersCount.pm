package Plagger::Plugin::Widget::HatenaBookmarkUsersCount;
use strict;
use base qw( Plagger::Plugin Class::Accessor::Fast );

sub register {
    my($self, $context) = @_;

    if ($context->is_loaded('Filter::HatenaBookmarkUsersCount')) {
        $self->conf->{use_filter} = 1;
    }

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

    my $permalink = $entry->permalink;
       $permalink =~ s/\#/%23/;
    my $url = HTML::Entities::encode("http://b.hatena.ne.jp/entry/$permalink");

    if ($self->conf->{use_filter}) {
        my $user = $entry->meta->{hatenabookmark_users};
        my $users = $user >= 2 ? "$user users" : "$user user";

        return
            $user >= 10 ?  qq(<strong style="background-color: #ffcccc; font-weight: bold; font-style: normal; display: inline;"><a href="$url" style="color: red;">$users</a></strong>)
          : $user >= 2  ?  qq(<em style="background-color: #fff0f0; font-weight: bold; display: inline; font-style: normal;"><a href="$url" style="color: #ff6666;">$users</a></em>)
          :                qq(<a href="$url">$users</a>);
    } else {
        my $size = $self->conf->{image_size} || 'normal';
        my $img_url = HTML::Entities::encode("http://b.hatena.ne.jp/entry/image/$size/$permalink");
        return qq(<a href="$url"><img src="$img_url" style="border:0;vertical-align:middle" /></a>);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Widget::HatenaBookmarkUsersCount - Widget to Hatena Bookmark with users count

=head1 SYNOPSIS

  - module: Widget::HatenaBookmarkUsersCount

=head1 DESCRIPTION

This plugin allows you to put a widget containing Hatena Bookmarks
users count and linking to the individual entry page.

If I<Filter::HatenaBookmarkUsersCount> plugin is loaded, it uses the
metadata found via XML-RPC, otherwise it uses Hatena Bookmarks' image
based API.

=head1 CONFIG

=over 4

=item image_size

If you use the default Hatena Bookmarks image API, you can change the
size of the image by this config. Optional and defaults to I<normal>.

=back

=head1 AUTHOR

Kazuhiro Osawa

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HatenaBookmarkUsersCount>, L<http://hatena.g.hatena.ne.jp/hatenabookmark/20060712/1152696382>
