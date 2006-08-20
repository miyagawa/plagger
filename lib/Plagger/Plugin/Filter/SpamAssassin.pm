package Plagger::Plugin::Filter::SpamAssassin;
use strict;
use base qw( Plagger::Plugin );

use Mail::SpamAssassin;
use MIME::Lite;
use Encode;
use Encode::MIME::Header;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'        => \&init_spamassassin,
        'update.entry.fixup' => \&filter,
    );
}

sub init_spamassassin {
    my($self, $context, $args) = @_;

    $context->log(debug => "initializing SpamAssassin");
    $self->{spamassassin} = Mail::SpamAssassin->new($self->conf->{new});
}

sub filter {
    my($self, $context, $args) = @_;

    my $sa    = $self->{spamassassin};
    my $entry = $args->{entry};
    my $tag   = $self->conf->{spam_tag} || 'spam';

    # create a pseudo mail header to skip some of the sa's default tests

    my $mail  = MIME::Lite->new(
        From       => 'plagger@localhost',
        To         => 'plagger@localhost',
        Subject    => encode('MIME-Header', $entry->title_text),
        'X-Mailer' => 'plagger',
        Data       => $entry->body_text,
    )->as_string;

    my $status = $sa->check_message_text( $mail );

    if ($status->is_spam) {
        $context->log(debug => "spam found");
        $entry->body($entry->body . $status->get_report) if $self->conf->{add_report};
        $entry->add_tag($tag);
    }

    $status->finish;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::SpamAssassin - Find spam entries

=head1 SYNOPSIS

  - module: Filter::SpamAssassin
    config:
      spam_tag: spam
      new:
        local_tests_only: 1
        site_rules_filename: some_rule.cf

=head1 CONFIG

=over 4

=item spam_tag

A string that will be added to the entry's tag. Defaults to 'spam'.

=item add_report (for debugging)

If set to true, the SpamAssassin's report will be added to spam 
entry's body.

=item new

Options passed to Mail::SpamAssassin->new(). See L<Mail::SpamAssassin>
for details.

=back

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<Mail::SpamAssassin>

=cut
