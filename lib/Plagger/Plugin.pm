package Plagger::Plugin;
use strict;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw(conf rule rule_hook cache) );

use Plagger::Crypt;
use Plagger::Rule;
use Plagger::Rules;

use FindBin;
use File::Spec;

sub new {
    my($class, $opt) = @_;
    my $self = bless {
        conf => $opt->{config} || {},
        rule => $opt->{rule},
        rule_op => $opt->{rule_op} || 'AND',
        rule_hook => '',
        meta => {},
    }, $class;
    $self->init();
    $self;
}

sub init {
    my $self = shift;

    if (my $rule = $self->{rule}) {
        $rule = [ $rule ] if ref($rule) eq 'HASH';
        my $op = $self->{rule_op};
        $self->{rule} = Plagger::Rules->new($op, @$rule);
    } else {
        $self->{rule} = Plagger::Rule->new({ module => 'Always' });
    }

    $self->walk_config_encryption();
}

sub walk_config_encryption {
    my $self = shift;
    my $conf = $self->conf;

    $self->do_walk($conf);
}

sub do_walk {
    my($self, $data) = @_;
    return unless defined($data) && ref $data;

    if (ref($data) eq 'HASH') {
        for my $key (keys %$data) {
            if ($key =~ /password/) {
                $self->decrypt_config($data, $key);
            }
            $self->do_walk($data->{$key});
        }
    } elsif (ref($data) eq 'ARRAY') {
        for my $value (@$data) {
            $self->do_walk($value);
        }
    }
}

sub decrypt_config {
    my($self, $data, $key) = @_;

    my $decrypted = Plagger::Crypt->decrypt($data->{$key});
    if ($decrypted eq $data->{$key}) {
        Plagger->context->add_rewrite_task($key, $decrypted, Plagger::Crypt->encrypt($decrypted, 'base64'));
    } else {
        $data->{$key} = $decrypted;
    }
}

sub conf { $_[0]->{conf} }
sub rule { $_[0]->{rule} }

sub dispatch_rule_on {
    my($self, $hook) = @_;
    $self->rule_hook && $self->rule_hook eq $hook;
}

sub class_id {
    my $self = shift;

    my $pkg = ref($self) || $self;
       $pkg =~ s/Plagger::Plugin:://;
    my @pkg = split /::/, $pkg;

    return join '-', @pkg;
}

# subclasses may overload to avoid cache sharing
sub plugin_id {
    my $self = shift;
    $self->class_id;
}

sub assets_dir {
    my $self = shift;

    my $context = Plagger->context;
    my $assets_base = $context->conf->{assets_path} || File::Spec->catfile($FindBin::Bin, "assets");
    return File::Spec->catfile(
        $assets_base, "plugins", $self->class_id,
    );
}

sub log {
    my $self = shift;
    Plagger->context->log(@_, caller => ref($self));
}

1;
