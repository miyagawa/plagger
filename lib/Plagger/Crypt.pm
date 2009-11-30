package Plagger::Crypt;
use strict;
use Module::Pluggable::Object;

my $pluggable = Module::Pluggable::Object->new(
    'search_path' => [qw/Plagger::Crypt/],
    'require'     => 1,
);
my %handlers = map { $_->id => $_ } $pluggable->plugins;
my $re = "^(" . join("|", map $_->id, $pluggable->plugins) . ")::";

sub decrypt {
    my($class, $ciphertext, @args) = @_;

    if ($ciphertext =~ s!$re!!) {
        my $handler = $handlers{$1};
        my @param = split /::/, $ciphertext;
        return $handler->decrypt(@param, @args);
    }

    return $ciphertext; # just plain text
}

sub encrypt {
    my($class, $plaintext, $driver, @param) = @_;
    my $handler = $handlers{$driver}
        or Plagger->context->error("No crypt handler for $driver");
    join '::', $driver, $handler->encrypt($plaintext, @param);
}

1;
