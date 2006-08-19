package Plagger::Plugin::Publish::JSON;
use strict;
use base qw( Plagger::Plugin::Publish::JavaScript );

use File::Spec;
use JSON::Syck;
use Plagger::Walker;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $file = $self->gen_filename($args->{feed}, $self->conf->{filename} || '%i.json');
    my $path = File::Spec->catfile($self->conf->{dir}, $file);
    $context->log(info => "writing output to $path");

    local $JSON::Syck::ImplicitUnicode = 1;
    my $body = JSON::Syck::Dump(Plagger::Walker->serialize($args->{feed}->clone));

    if (my $var = $self->conf->{varname}) {
        $body = "var $var = $body;";
    } elsif (my $jsonp = $self->conf->{jsonp}) {
        $body = "$jsonp($body)";
    }

    open my $out, ">:utf8", $path or $context->error("$path: $!");
    print $out $body;
    close $out;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::JSON - Publish JSON data output

=head1 SYNOPSIS

  - module: Publish::JSON
    config:
      dir: /path/to/data

=head1 DESCRIPTION

This plugin dumps feed data to JSON JavaScript Object Notation.

=head1 CONFIG

=over 4

=item dir

Directory name to save.

=item varname

  varname: foo

Variable name to store JSON data. If set, .json file would include the
variable declaration e.g.:

  var foo = { ... }

Optional.

=item jsonp

  jsonp: bar

JSONP callback name to pass JSON data back. Optional. If set, .json
file would wrap the returned data in a callback function, e.g.:

  bar({ ... })

Optional.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<JSON::Syck>

=cut
