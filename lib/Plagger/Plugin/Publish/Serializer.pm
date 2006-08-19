package Plagger::Plugin::Publish::Serializer;
use strict;
use base qw( Plagger::Plugin );

use Data::Serializer;
use Plagger::Util;
use Plagger::Walker;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'plugin.init'  => \&initialize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;
    my $dir = $self->conf->{dir} or $context->error("dir is required");

    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }
}

sub feed {
    my($self, $context, $args) = @_;

    my $file = Plagger::Util::filename_for($args->{feed}, $self->conf->{filename});
    my $path = File::Spec->catfile($self->conf->{dir}, $file);

    my $data = $self->serialize( Plagger::Walker->serialize($args->{feed}) );
    utf8::encode($data) if utf8::is_utf8($data);

    $context->log(info => "Serializing " . $args->{feed}->id . " to $path");
    open my $out, ">", $path or $context->error("$path: $!");
    print $out $data;
    close $out;
}

sub serialize {
    my($self, $data) = @_;

    my $selializer =  Data::Serializer->new(
        serializer => $self->conf->{serializer} || 'Data::Dumper',
        options    => $self->conf->{option} || {},
    );

    $selializer->raw_serialize($data);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::Serializer - Serialize feed data using Data::Serializer

=head1 SYNOPSIS

  - module: Publish::Serializer
    config:
      serializer: YAML
      filename: %i.yaml

=head1 DESCRIPTION

This plugin dumps feed data to whatever serialization format that Data::Serializer supports.

=head1 CONFIG

=over 4

=item dir

Directory to save the serialized data in. Required.

=item serializer

  serializer: YAML::Syck

Serializer subclass that Data::Serializer uses. Defaults to I<Data::Dumper>.

=item filename

Filename to save the data to. Required.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
