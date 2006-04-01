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

    if (my $params = $self->encrypt_config) {
        $params = [ $params ] unless ref $params;

        for my $key (@$params) {
            my $config = $self->conf;
            # support foo/bar/baz
            while ($key =~ s!^(\w+)/!!) {
                $config = $config->{$1};
            }
            my $decrypted = Plagger::Crypt->decrypt($config->{$key});
            if ($decrypted eq $config->{$key}) {
                Plagger->context->add_rewrite_task($key, $decrypted, Plagger::Crypt->encrypt($decrypted, 'base64'));
            } else {
                $config->{$key} = $decrypted;
            }
        }
    }
}

sub encrypt_config { }

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

    return join '-', map lc, @pkg;
}

# subclasses may overload to avoid cache sharing
sub plugin_id {
    my $self = shift;
    $self->class_id;
}

sub assets_dir {
    my $self = shift;

    my $assets_dir = File::Spec->catfile(
                            $self->conf->{assets_path}
                         || ($FindBin::Bin, "assets/plugins", $self->class_id)
                     );

}

sub log {
    my $self = shift;
    Plagger->context->log(@_, caller => ref($self));
}

1;
