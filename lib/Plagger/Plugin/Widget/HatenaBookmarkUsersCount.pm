package Plagger::Plugin::Widget::HatenaBookmarkUsersCount;
use strict;
use base qw( Plagger::Plugin Class::Accessor::Fast );

sub register {
    my($self, $context) = @_;
    $context->autoload_plugin('Filter::HatenaBookmarkUsersCount');
    $context->register_hook(
        $self,
        'publish.entry.fixup' => \&add,
    );
}

sub add {
    my($self, $context, $args) = @_;
    $args->{entry}->add_widget($self)
        if defined($args->{entry}->meta->{hatenabookmark_users});
}

sub html {
    my($self, $entry) = @_;

    my $permalink = $entry->permalink;
       $permalink =~ s/\#/%23/;
    my $uri = URI->new('http://b.hatena.ne.jp/entry/' . $permalink);

    my $url = HTML::Entities::encode($uri->as_string);

    my $user = $entry->meta->{hatenabookmark_users};
    my $users = $user >= 2 ? "$user users" : "$user user";

    $user >= 10 ?
	qq(<strong style="background-color: #ffcccc; font-weight: bold; font-style: normal; display: inline;"><a href="$url" style="color: red;">$users</a></strong>)
	: $user >= 2 ?
	qq(<em style="background-color: #fff0f0; font-weight: bold; display: inline; font-style: normal;"><a href="$url" style="color: #ff6666;">$users</a></em>)
	: qq(<a href="$url">$users</a>);
}

1;

