package Plagger::ConfigLoader;
use strict;
use Carp;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub load {
    my($self, $stuff) = @_;

    my $config;
    if (-e $stuff && -r _) {
        $config = YAML::LoadFile($stuff);
        $self->{config_path} = $stuff;
    } elsif (ref($stuff) && ref($stuff) eq 'SCALAR') {
        $config = YAML::Load(${$stuff});
    } elsif (ref($stuff) && ref($stuff) eq 'HASH') {
        $config = Storable::dclone($stuff);
    } else {
        croak "Plagger::ConfigLoader->load: $stuff: $!";
    }

    return $config;
}

sub load_include {
    my($self, $config) = @_;

    return unless $config->{include};
    for (@{ $config->{include} }) {
        my $include = YAML::LoadFile($_);

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
