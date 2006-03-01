package Plagger::Cache;
use strict;
use File::Spec;
use UNIVERSAL::require;

sub new {
    my($class, $conf, $name) = @_;

    mkdir $conf->{base}, 0777 unless -e $conf->{base} && -d_;

    # Cache default configuration
    $conf->{class}  ||= 'Cache::File';
    $conf->{params} ||= {
        cache_root      => File::Spec->catfile($conf->{base}, 'cache'),
        default_expires => '30 minutes',
    };

    $conf->{class}->require or die $@;

    my $self = bless {
        base  => $conf->{base},
        cache => $conf->{class}->new($conf->{params}),
    }, $class;
}

sub get {
    my $self = shift;
    my $getter = $self->{cache}->isa('Cache') ? 'thaw' : 'get';
    $self->{cache}->$getter(@_);
}

sub get_callback {
    my $self = shift;
    my($key, $callback, $expiry) = @_;

    my $data = $self->get($key);
    if (defined $data) {
        Plagger->context->log(debug => "Cache hit: $key");
        return $data;
    }

    Plagger->context->log(debug => "Cache miss: $key");
    $data = $callback->();
    if (defined $data) {
        $self->set($key => $data, $expiry);
    }

    $data;
}

sub set {
    my $self = shift;
    my($key, $value, $expiry) = @_;

    my $setter = $self->{cache}->isa('Cache') ? 'freeze' : 'set';
    $self->{cache}->$setter(@_);
}

sub remove {
    my $self = shift;
    $self->{cache}->remove(@_);
}

1;
