package Plagger::ConfigLoader;
use strict;
use Carp;
use Plagger::Walker;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my($self, $stuff, $context) = @_;

    my $config;
    if ((!ref($stuff) && $stuff eq '-') ||
        (-e $stuff && -r _)) {
        $config = YAML::LoadFile($stuff);
        $context->{config_path} = $stuff if $context;
    } elsif (ref($stuff) && ref($stuff) eq 'SCALAR') {
        $config = YAML::Load(${$stuff});
    } elsif (ref($stuff) && ref($stuff) eq 'HASH') {
        $config = Storable::dclone($stuff);
    } else {
        croak "Plagger::ConfigLoader->load: $stuff: $!";
    }

    unless ($config->{global} && $config->{global}->{no_decode_utf8}) {
        Plagger::Walker->decode_utf8($config);
    }

    return $config;
}

sub load_include {
    my($self, $config) = @_;

    my $includes = $config->{include} or return;
    $includes = [ $includes ] unless ref $includes;

    for my $file (@$includes) {
        my $include = YAML::LoadFile($file);

        for my $key (keys %{ $include }) {
            my $add = $include->{$key};
            unless ($config->{$key}) {
                $config->{$key} = $add;
                next;
            }
            if (ref($config->{$key}) eq 'HASH') {
                next unless ref($add) eq 'HASH';
                for (keys %{ $include->{$key} }) {
                    $config->{$key}->{$_} = $include->{$key}->{$_};
                }
            } elsif (ref($include->{$key}) eq 'ARRAY') {
                $add = [ $add ] unless ref($add) eq 'ARRAY';
                push(@{ $config->{$key} }, @{ $include->{$key} });
            } elsif ($add) {
                $config->{$key} = $add;
            }
        }
    }
}

sub load_recipes {
    my($self, $config) = @_;

    for (@{ $config->{recipes} }) {
        $self->error("no such recipe to $_") unless $config->{define_recipes}->{$_};
        my $plugin = $config->{define_recipes}->{$_};
        $plugin = [ $plugin ] unless ref($plugin) eq 'ARRAY';
        push(@{ $config->{plugins} }, @{ $plugin });
    }
}

1;
