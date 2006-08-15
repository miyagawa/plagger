use strict;
use t::TestPlagger;

plan 'no_plan';

run {
    my $block = shift;
    my $config = YAML::Load($block->input);

    my $context = bless {}, 'Plagger';
    $context->load_include($config);
    $context->load_recipes($config);

    # no need to compare these things
    delete $config->{recipes};
    delete $config->{include};
    delete $config->{define_recipes};

    is_deeply $config, $block->expected, $block->name;
}

__END__

=== Test include
--- input interpolate
include:
  - $t::TestPlagger::BaseDir/t/samples/included.yaml
global:
  foo: bar
plugins:
  - module: Foo::Bar

--- expected yaml
global:
 baz: baaa
 foo: bar
plugins:
  - module: Foo::Bar

=== Test recipe
--- input interpolate
include:
  - $t::TestPlagger::BaseDir/t/samples/included-recipe.yaml
recipes:
  - foo

--- expected yaml
plugins:
  - module: Foo::Bar
    config:
      bar: baz

=== Test two recipes
--- input interpolate
include:
  - $t::TestPlagger::BaseDir/t/samples/included-recipe.yaml
recipes:
  - foo
  - bar

--- expected yaml
plugins:
  - module: Foo::Bar
    config:
      bar: baz
  - module: Baz::Bar
    config:
      baz: zzzz

=== Test recipe + global include
--- input interpolate
include:
  - $t::TestPlagger::BaseDir/t/samples/included-recipe.yaml
  - $t::TestPlagger::BaseDir/t/samples/included.yaml
global:
  foo: bar
recipes:
  - foo

--- expected yaml
global:
 baz: baaa
 foo: bar
plugins:
  - module: Foo::Bar
    config:
      bar: baz
