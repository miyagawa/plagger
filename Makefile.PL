use inc::Module::Install;

name('plagger');
all_from('lib/Plagger.pm');
requires(YAML => 0.39);
build_requires(Test::More => 0.42);

features(
    'Bloglines subscription' => [
        -default => 1,
        recommends('WebService::Bloglines', 0.06),
    ],
);

auto_include;
auto_install;
WriteAll;
