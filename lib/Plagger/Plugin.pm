package Plagger::Plugin;
use strict;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw(conf rule rule_hook cache) );

use Plagger::Cookies;
use Plagger::Crypt;
use Plagger::Rule;
use Plagger::Rules;

use FindBin;
use File::Find::Rule ();
use File::Spec;
use Scalar::Util qw(blessed);

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

    if ($self->conf->{assets_path}) {
        return $self->conf->{assets_path}; # look at config:assets_path first
    }

    my $assets_base =
        $context->conf->{assets_path} ||              # or global:assets_path
        File::Spec->catfile($FindBin::Bin, "assets"); # or "assets" under plagger script

    return File::Spec->catfile(
        $assets_base, "plugins", $self->class_id,
    );
}

sub log {
    my $self = shift;
    Plagger->context->log(@_, caller => ref($self));
}

sub cookie_jar {
    my $self = shift;

    my $agent_conf = Plagger->context->conf->{user_agent} || {};
    if ($agent_conf->{cookies}) {
        return Plagger::Cookies->create($agent_conf->{cookies});
    }

    return $self->cache->cookie_jar;
}

sub templatize {
    my($self, $file, $vars) = @_;

    my $context = Plagger->context;
    $vars->{context} ||= $context;

    my $template = Plagger::Template->new($context, $self);
    $template->process($file, $vars, \my $out) or $context->error($template->error);

    $out;
}

sub load_assets {
    my($self, $rule, $callback) = @_;

    unless (blessed($rule) && $rule->isa('File::Find::Rule')) {
        $rule = File::Find::Rule->name($rule);
    }

    # $rule isa File::Find::Rule
    for my $file ($rule->in($self->assets_dir)) {
        my $base = File::Basename::basename($file);
        $callback->($file, $base);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin - Base class for Plagger Pluggins

=head1 SYNOPSIS

  package Plagger::Plugin::Something;
  use base qw(Plagger::Plugin);

  # register hooks
  sub register {
    my ($self, $context) = @_;
    $context->register_hook( $self,
       'thingy.wosit'  => $self->can('doodad'),
    )
  }
  
  sub doodad { ... }

=head1 DESCRIPTION

This is the base class for plagger plugins.  Pretty much everything is done
by pluggins in Plagger.

To write a new plugin, simply inherit from Plagger::Plugin:

  package Plagger::Plugin;
  use base qw(Plagger::Plugin);

Then register some hooks:

  # register hooks
  sub register {
    my ($self, $context) = @_;
    $context->register_hook( $self,
       'thingy.wosit'  => $self->can('doodad'),
    )
  }


This means that the "doodad" method will be called at the
"thingy.wosit" stage. The handy L<tools/plugin-start.pl> is a
I<helper> tool that creates all templates, dependency and test files
required for you.

  > ./tools/plugin-start.pl Foo::Bar

=head2 Methods

=over

=item new

Standard constructor.  Calls init.

=item init

Initilises the plugin

=item walk_config_encryption

=item do_walk

=item decrypt_config

=item conf

=item rule

=item rule_hook

=item cache

=item dispatch_rule_on

=item class_id

=item assets_dir

=item log

=item cookie_jar

Access the Plagger::Cookies object.

=item templatize

=item load_assets

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>

=cut
