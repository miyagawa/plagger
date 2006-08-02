package t::TestPlagger;
use Test::Base -Base;
use Plagger;

our @EXPORT = qw(test_requires test_requires_network test_requires_command
                 run_eval_expected slurp_file file_contains file_doesnt_contain);

sub test_requires() {
    my($mod, $ver) = @_;

    if ($ver) {
        eval qq{use $mod $ver};
    } else {
        eval qq{use $mod};
    }

    if ($@) {
        plan skip_all => "$@";
    }
}

sub has_network {
    return if $ENV{NO_NETWORK};

    require IO::Socket::INET;
    my $conn = IO::Socket::INET->new("www.google.com:80");
    defined $conn;
}

sub test_requires_network {
    unless (has_network) {
        plan skip_all => "Test requires network which is not available now.";
    }
}

sub test_requires_command() {
    my $command = shift;
    for my $path (split /:/, $ENV{PATH}) {
        if (-e File::Spec->catfile($path, $command) && -x _) {
            return 1;
        }
    }
    plan skip_all => "Test requires '$command' command but it's not found";
}

sub run_eval_expected {
    run {
        my $block = shift;
        my $context = $block->input; # it's not always true
        eval $block->expected;
        fail $@ if $@;
    };
}

sub slurp_file() {
    my $file = shift;
    open my $fh, $file or return;
    return join '', <$fh>;
}

sub file_contains() {
    my($file, $pattern) = @_;

    like slurp_file($file), $pattern;
}

sub file_doesnt_contain() {
    my($file, $pattern) = @_;

    my $content = slurp_file($file) or return fail("$file: $!");
    unlike $content, $pattern;
}

package t::TestPlagger::Filter;
use Test::Base::Filter -base;

sub config {
    my $config = shift;
    $config =~ s/(?<!\\)(\$[\w\:]+)/$1/eeg;
    $config =~ s/\\\$/\$/g;
    Plagger->bootstrap(config => YAML::Load($config));
}

sub output_file {
    my $output = $main::output or die "\$main::output is undefined";
    open my $fh, $output or return ::fail("$output: $!");
    return join '', <$fh>;
}

1;
