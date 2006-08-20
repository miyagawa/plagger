package Plagger::Walker;
use strict;
use Carp;
use Scalar::Util qw(blessed);
use UNIVERSAL;

sub new {
    my $class = shift;
    my $self  = @_ ? {@_} : {};
    bless $self, $class;
}

*isa = \&UNIVERSAL::isa;

sub decode_utf8 {
    my($self, $stuff) = @_;
    $self = $self->new( apply_keys => 1 ) unless ref $self;
    $self->apply(sub { utf8::decode($_[0]) unless utf8::is_utf8($_[0]) })->($stuff);
}

sub apply($&;@) {
    my $self = shift;
    my $code = shift;
    my $keyapp = $self->{apply_keys} ?
        sub { $code->(shift) } : sub { shift };
    my $curry; # recursive so can't init
    $curry = sub {
        my @retval;
        for my $arg (@_){
            my $class = ref $arg;
            croak 'blessed reference forbidden'
                if  !$self->{apply_blessed} and blessed $arg;
            my $val =
                !$class ?
                    $code->($arg) :
                isa($arg, 'ARRAY') ?
                    [ $curry->(@$arg) ] :
                isa($arg, 'HASH') ?
                    {
                     map { $keyapp->($_)
                               => $curry->($arg->{$_}) } keys %$arg
                    } :
                isa($arg, 'SCALAR') ?
                    \do{ $curry->($$arg) } :
                isa($arg, 'REF') && $self->{apply_ref} ?
                    \do{ $curry->($$arg) } :
                isa($arg, 'GLOB')  ?
                    *{ $curry->(*$arg) } :
                isa($arg, 'CODE') && $self->{apply_code} ?
                    $code->($arg) :
                croak "I don't know how to apply to $class" ;
            bless $val, $class if blessed $arg;
            push @retval, $val;
        }
        return wantarray ? @retval : $retval[0];
    };
    @_ ? $curry->(@_) : $curry;
}

sub serialize {
    my($class, $stuff) = @_;

    my $curry;
    $curry = sub {
        my @retval;
        for my $arg (@_) {
            my $class = ref $arg;
            my $val =
                blessed $arg && $arg->can('serialize') ?
                    $arg->serialize :
                !$class ?
                    $arg :
                isa($arg, 'ARRAY') ?
                    [ $curry->(@$arg) ] :
                isa($arg, 'HASH') ?
                    {
                     map { $_ => $curry->($arg->{$_}) } keys %$arg
                    } :
                isa($arg, 'SCALAR') ?
                    \do{ $curry->($$arg) } :
                isa($arg, 'REF') ?
                    \do{ $curry->($$arg) } :
                isa($arg, 'GLOB')  ?
                    *{ $curry->(*$arg) } :
                isa($arg, 'CODE') ?
                    $arg :
                croak "I don't know how to apply to $class" ;
            push @retval, $val;
        }
        return wantarray ? @retval : $retval[0];
    };
    $curry->($stuff->clone);
}

1;

