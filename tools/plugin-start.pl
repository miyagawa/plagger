#!/usr/bin/perl
use strict;
use warnings;

use Config;
use FindBin;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Path;
use YAML;
use Template;

chdir "$FindBin::Bin/..";

my $module = shift @ARGV or die "Usage: plugin-start.pl Plugin::Name\n";
   $module =~ s/-/::/g;

my $file   = "$ENV{HOME}/.plagger-module.yml";
my $config = eval { YAML::LoadFile($file) } || {};

my $save;
$config->{author} ||= do {
    $save++;
    prompt("Your name: ");
};

write_plugin_files($module, $config->{author});

YAML::DumpFile($file, $config) if $save;

sub write_plugin_files {
    my($module, $author) = @_;

    # $module = "Foo::Bar"
    # $plugin = "Foo-Bar"
    # $path   = "Foo/Bar"
    (my $plugin = $module) =~ s!::!-!g;
    (my $path   = $module) =~ s!::!/!g;

    my $template = YAML::Load(join '', <DATA>);
    my $vars = { module => $module, plugin => $plugin, path => $path, author => $author };

    my @files;
    push @files, write_file("lib/Plagger/Plugin/$path.pm", $template->{plugin}, $vars);
    push @files, write_file("deps/$plugin.yaml", $template->{deps}, $vars);
    push @files, write_file("t/plugins/$plugin/base.t", $template->{test}, $vars);

    if (my $vcs = version_control()) {
        my $ans = prompt("$vcs add newly created files? [Yn]", 'y');
        if ($ans =~ /[Yy]/) {
            system($vcs, 'add', @files);
        }
    }
}

sub write_file {
    my($path, $template, $vars) = @_;

    if (-e $path) {
        my $ans = prompt("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    }

    my $dir = File::Basename::dirname($path);
    unless (-e $dir) {
        warn "Creating directory $dir\n";
        File::Path::mkpath($dir, 1, 0777);
    }

    my $tt = Template->new;
    $tt->process(\$template, $vars, \my $content);

    warn "Creating $path\n";
    open my $out, ">", $path or die "$path: $!";
    print $out $content;
    close $out;

    return $path;
}

sub version_control {
    return 'svk' if check_command('svk', 'svk info', qr/Checkout Path/);
    return 'svn' if -e ".svn/entries";
    return;
}

sub check_command {
    my($bin, $command, $re) = @_;
    return unless grep { -e File::Spec->catfile($_, $bin) } split /$Config::Config{path_sep}/, $ENV{PATH};

    my $res = qx($command);
    defined $res && $res =~ $re;
}

__DATA__
plugin: |
  package Plagger::Plugin::[% module %];
  use strict;
  use base qw( Plagger::Plugin );

  sub register {
      my($self, $context) = @_;
      $context->register_hook(
          $self,
          # ...
      );
  }

  1;
  __END__

  =head1 NAME

  Plagger::Plugin::[% module %] -

  =head1 SYNOPSIS

    - module: [% module %]

  =head1 DESCRIPTION

  XXX Write the description for [% module %]

  =head1 CONFIG

  XXX Document configuration variables if any.

  =head1 AUTHOR

  [% author %]

  =head1 SEE ALSO

  L<Plagger>

  =cut

deps: |
  name: [% plugin %]
  author: [% author %]
  depends:

test: |
  use strict;
  use t::TestPlagger;

  test_plugin_deps;
  plan 'no_plan';
  run_eval_expected;

  __END__

  === Loading [% module %]
  --- input config
  plugins:
    - module: [% module %]
  --- expected
  ok 1, $block->name;
