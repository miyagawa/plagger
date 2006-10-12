package Plagger::Plugin::Publish::CSV;
use strict;
use warnings;
use base qw ( Plagger::Plugin );

our $VERSION = 0.02;

use Encode;
use File::Spec;
use Text::CSV_PP;
use IO::File;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my ($self, $context, $args) = @_;
    my $csv = Text::CSV_PP->new({ binary => 1 });
    my $append = ($self->conf->{mode} && $self->conf->{mode} eq 'append');
    my $dir = $self->conf->{dir};
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }

    my $file = Plagger::Util::filename_for($args->{feed}, $self->conf->{filename} || "%i.csv");
    my $path = File::Spec->catfile($dir, $file);
    my $io = IO::File->new($append  ? ">> $path" : "> $path");

    my $columns = $self->conf->{column} || [qw(title permalink)];
    for my $entry ($args->{feed}->entries) {
        my $st = $csv->combine(map { $entry->$_ } @$columns);
        $context->log(error => $self->convert($csv->error_input)) unless $st;
        $io->printf("%s\n", $self->convert($csv->string)) if $st;
    }

    $context->log(
        info => sprintf(
            "%s to %s: %d entries",
            $append ? 'Append' : 'Write',
            $path,
            $args->{feed}->count
        )
    );
}

sub convert {
    my ($self, $str) = @_;
    utf8::decode($str) unless utf8::is_utf8($str);
    return encode($self->conf->{encoding} || 'utf8', $str);
}

1;

__END__

=head1

Plagger::Plugin::Publish::CSV - Publish feeds as CSV

=head1 SYNOPSIS

  - module: Publish::CSV
    config:
      dir: /var/web/csv
      encoding: euc-jp
      filename: my_%t.csv
      mode: append
      column:
       - title
       - permalink

=head1 CONFIG

=head2 dir

Directory to save csv files in.

=head2 filename

Filename to be used to create csv files. It defaults to C<%i.csv>. It
supports the following format like printf():

=over 4

=item * %u url

=item * %l link

=item * %t title

=item * %i id

=back

=head2 mode

Specify 'append' if you want to append entries to an existing file
rather than creating a new file.

=head2 column

Chose the columns of entry which you want to write to the csv. It
defaults to title and permalink.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>, L<Text::CSV_PP>

=cut
