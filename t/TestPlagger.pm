package t::TestPlagger;
use Config;
use FindBin;
use File::Basename;
use File::Spec;
use Test::Base -Base;
use URI::Escape ();
use Plagger;

our @EXPORT = qw(test_requires test_requires_network test_requires_command test_plugin_deps
                 run_eval_expected run_eval_expected_with_capture
                 slurp_file file_contains file_doesnt_contain);

our($BaseDir, $BaseDirURI);
{
    my @path = File::Spec->splitdir($FindBin::Bin);
    while (defined(my $dir = pop @path)) {
        if ($dir eq 't') {
            $BaseDir = File::Spec->catfile(@path);
            $BaseDirURI = join "/", map URI::Escape::uri_escape($_), @path;
            last;
        }
    }
}

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

sub has_network() {
    my $host = shift;
    return if $ENV{NO_NETWORK};

    require IO::Socket::INET;
    my $conn = IO::Socket::INET->new(PeerAddr => $host, Timeout => 15);
    defined $conn;
}

sub test_requires_network() {
    my $host = shift || 'www.google.com:80';

    unless (has_network($host)) {
        plan skip_all => "Test requires network($host) which is not available now.";
    }
}

sub test_requires_command() {
    my $command = shift;
    for my $path (split /$Config::Config{path_sep}/, $ENV{PATH}) {
        if (-e File::Spec->catfile($path, $command) && -x _) {
            return 1;
        }
    }
    plan skip_all => "Test requires '$command' command but it's not found";
}

sub test_plugin_deps() {
    my($mod, $no_warning) = @_;
    $mod ||= File::Basename::basename($FindBin::Bin);
    $mod =~ s!::!-!g;

    my $file = File::Spec->catfile( $BaseDir, "deps", "$mod.yaml" );
    unless (-e $file) {
        warn "Can't find deps file for $mod" unless $no_warning;
        return;
    }

    my $meta = YAML::LoadFile($file);
    if ($meta->{platform} && $meta->{platform} ne $^O) {
        plan skip_all => "Test requires '$meta->{platform}'";
    }

    for my $plugin (@{ $meta->{bundles} || [] }) {
        $plugin =~ s/::/-/g;
        test_plugin_deps($plugin, 1);
    }

    while (my($mod, $ver) = each %{$meta->{depends} || {}}) {
        test_requires($mod, $ver);
    }
}

sub run_eval_expected {
    run {
        my $block = shift;
        my $context = $block->input; # it's not always true
        eval $block->expected;
        fail $@ if $@;
    };
}

sub run_eval_expected_with_capture {
    filters_delay;
    for my $block (blocks) {
        my $warning;
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $block->run_filters;
        }
        my $context = $block->input;
        eval $block->expected;
        fail $@ if $@;
    }
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
use File::Temp ();

sub interpolate {
    my $stuff = shift;
    $stuff =~ s/(?<!\\)(\$[\w\:]+)/$1/eeg;
    $stuff =~ s/\\\$/\$/g;
    $stuff;
}

sub config {
    my $yaml = shift;
    $yaml = $self->interpolate($yaml);

    # set sane defaults for testing
    my $config = YAML::Load($yaml);
    $config->{global}->{log}->{level}  ||= 'error' unless $ENV{TEST_VERBOSE};
    $config->{global}->{assets_path}   ||= File::Spec->catfile($t::TestPlagger::BaseDir, 'assets');
    $config->{global}->{cache}->{base} ||= File::Temp::tempdir(CLEANUP => 1);

    Plagger->bootstrap(config => $config);
}

sub output_file {
    my $output = $main::output or die "\$main::output is undefined";
    open my $fh, $output or return ::fail("$output: $!");
    return join '', <$fh>;
}

1;
