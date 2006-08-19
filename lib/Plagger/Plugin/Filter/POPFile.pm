package Plagger::Plugin::Filter::POPFile;
use strict;
use base qw( Plagger::Plugin );

use XMLRPC::Lite;
use File::Temp ();
use Encode;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'        => \&connect_popfile,
        'update.entry.fixup' => \&filter,
        'update.fixup'       => \&disconnect_popfile,
    );
}

sub rule_hook { 'update.entry.fixup' }

sub filter {
    my ($self, $context, $args) = @_;

    my $entry    = $args->{entry};
    my $filename = write_tmpfile($self, $context, $args);
    my $training = $self->conf->{training};
       $training = 1 unless defined $training;

    my $bucket;
    if ($training) {
        $bucket = $self->{popfile}->call(
            'POPFile/API.handle_message',
            $self->{popfile_session},
            $filename,
            "$filename.out"
        )->result;
    }
    else {
        $bucket = $self->{popfile}->call(
            'POPFile/API.classify',
            $self->{popfile_session},
            $filename
        )->result;
    }

    $context->log(debug => $entry->permalink . ": $bucket");

    $entry->add_tag($bucket);
}

sub connect_popfile {
    my ($self, $context, $args) = @_;

    $context->log(debug => "hello, POPFile");
    $self->{popfile} = XMLRPC::Lite->proxy($self->conf->{proxy});
    $self->{popfile_session} = $self->{popfile}->call(
        'POPFile/API.get_session_key',
        'admin',
        ''
    )->result;

    $context->log(debug => "session: $self->{popfile_session}");

    $self->{popfile_tempdir} = File::Temp::tempdir(
        $self->conf->{tempdir} ? ( DIR => $self->conf->{tempdir} ) : (),
        CLEANUP => 1,
    );
}

sub disconnect_popfile {
    my ($self, $context, $args) = @_;

    $context->log(debug => "good-bye, POPFile");
    $self->{popfile}->call(
         'POPFile/API.release_session_key',
         $self->{popfile_session}
    );
}

sub write_tmpfile {
    my ($self, $context, $args) = @_;

    my $encoding = $self->conf->{encoding} || 'utf8';
    my $entry    = $args->{entry};
    my $text     = $entry->body_text;

    my ($fh, $filename) = File::Temp::tempfile(
        DIR => $self->{popfile_tempdir},
    );

    print $fh
        'From: (', $entry->permalink, ') <plagger@localhost>', "\n",
        'To: <plagger@localhost>', "\n",
        'Subject: ', encode($encoding, $entry->title), "\n\n",
        encode($encoding, $text), "\n";
    close $fh;

    return $filename;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::POPFile - Categorize entries as spam et al

=head1 SYNOPSIS

  - module: Filter::POPFile
    rule:
      module: Fresh
      mtime:
        path: /home/ishigaki/.plagger/fresh_rule
        autoupdate: 1
    config:
      proxy: http://localhost:8081/RPC2
      encoding: euc-jp
      training: 1
      tempdir: /tmp

=head1 CONFIG

=over 4

=item proxy

Your POPFile proxy URL.

=item encoding

Your POPFile encoding. Specify 'euc-jp' for Nihongo users.

=item training

Enables POPFile training (i.e. Adds entries to POPFile history).
Defaults to true.

=item tempdir (Optional)

Temporary directory POPFile uses. Network directory might work,
though I haven't tried yet. If you want to communicate with a
remote POPFile (via Samba etc), try this.

=back

=head1 CAVEATS

Don't forget to use Fresh rule while you're training POPFile.
Otherwise your POPFile history would have a lot of duplicates. 

=head1 THANKS TO

Tatsuhiko Miyagawa

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<Plagger::Rule::Fresh>, POPFile

=cut
