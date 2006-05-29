package Plagger::Plugin::Filter::FetchEnclosure;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;
use File::Path;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    defined $self->conf->{dir} or Plagger->context->error("config 'dir' is not set.");
    unless (-e $self->conf->{dir} && -d _) {
        Plagger->context->log(warn => $self->conf->{dir} . " does not exist. Creating");
        mkpath $self->conf->{dir};
    }
}

sub filter {
    my($self, $context, $args) = @_;

    my $ua = Plagger::UserAgent->new;
    for my $enclosure ($args->{entry}->enclosures) {
        my $feed_dir = File::Spec->catfile($self->conf->{dir}, $args->{feed}->id_safe);
        unless (-e $feed_dir && -d _) {
            $context->log(info => "mkdir $feed_dir");
            mkdir $feed_dir, 0777;
        }

        my $path = File::Spec->catfile($feed_dir, $enclosure->filename);
        $context->log(info => "fetch " . $enclosure->url . " to " . $path);

        my $request = HTTP::Request->new(GET => $enclosure->url);
        if ($self->conf->{fake_referer}) {
            $context->log(debug => "Sending Referer: " . $args->{entry}->permalink);
            $request->header('Referer' => $args->{entry}->permalink);
        }

        my $res = $ua->mirror($request, $path);
        $enclosure->local_path($path); # set to be used in later plugins

        # Fix length if it's broken
        if ($res->header('Content-Length')) {
            $enclosure->length( $res->header('Content-Length') );
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FetchEnclosure - Fetch enclosure(s) in entry

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure
    config:
      dir: /path/to/files

=head1 DESCRIPTION

This plugin downloads enclosure files set for each entry.

=head1 TODO

=over 4

=item Support asynchronous download using POE

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

