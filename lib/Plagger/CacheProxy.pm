package Plagger::CacheProxy;
use strict;

sub new {
    my($class, $plugin, $cache) = @_;
    bless {
        namespace => $plugin->class_id,
        cache     => $cache,
    }, $class;
}

no strict 'refs';
for my $meth (qw(get get_callback set remove)) {
    *{$meth} = sub {
        my $self = shift;
        my $key  = shift;
        $key = "$self->{namespace}|$key";
        $self->{cache}->$meth($key, @_);
    };
}

sub path_to {
    my($self, @path) = @_;
    $self->{cache}->path_to($self->{namespace}, @path);
}

sub cookie_jar {
    my $self = shift;
    $self->{cache}->cookie_jar($self->{namespace});
}

1;
