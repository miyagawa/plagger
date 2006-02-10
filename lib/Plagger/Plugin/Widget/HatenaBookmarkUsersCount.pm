package Plagger::Plugin::Widget::HatenaBookmarkUsersCount;
use strict;
use base qw( Plagger::Plugin Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( permalink map ));
use Plagger::Rule;
use XMLRPC::Lite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&vacuum,
        'update.fixup' => \&update,
        'publish.entry.fixup' => \&entry,
    );
    $self->permalink({});
}

sub vacuum {
    my($self, $context, $args) = @_;
    $self->permalink->{$args->{entry}->permalink} = 0;
}

sub update {
    my($self, $context) = @_;
    $self->map(XMLRPC::Lite->
	       proxy('http://b.hatena.ne.jp/xmlrpc')->
	       call('bookmark.getCount', keys %{$self->permalink})->
	       result);
}

sub entry {
    my($self, $context, $args) = @_;
    return unless $self->map;
    $args->{entry}->add_widget($self) if $self->map->{$args->{entry}->permalink};
}

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new('http://b.hatena.ne.jp/entry/' . $entry->permalink);
    my $url = HTML::Entities::encode($uri->as_string);
    my $user = $self->map->{$entry->permalink};
    my $users = $user > 1 ? "$user users" : "$user user";
    $user > 9 ? 
	qq(<strong style="background-color: #ffcccc; font-weight: bold; font-style: normal; display: inline;"><a href="$url" style="color: red;">$users</a></strong>)
	: $user > 2 ?
	qq(<em style="background-color: #fff0f0; font-weight: bold; display: inline; font-style: normal;"><a href="$url" style="color: #ff6666;">$users</a></em>)
	: qq(<a href="$url">$users</a>);
}
1;
