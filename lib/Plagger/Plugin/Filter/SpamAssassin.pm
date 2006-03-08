package Plagger::Plugin::Filter::SpamAssassin;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.01';

use Mail::SpamAssassin;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init' => \&init_spamassassin,
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
    my $tag   = $self->conf->{spam_tag} || 'SPAM';

    # create a pseudo mail header to skip some of the sa's default tests
    my $status = $sa->check_message_text(
        join "\n", 'Subject: ' . $entry->title, "\n", $entry->body
    );

    if ($status->is_spam) {
        $context->log(debug => "spam found");

        $entry->title("[$tag] " . $entry->title) if $self->conf->{add_tag_to_title};
        $entry->body($entry->body . $status->get_report) if $self->conf->{add_report};
        $entry->add_tag($tag);
    }

    $status->finish;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::SpamAssassin - mark spams

=head1 SYNOPSIS

  - module: SmartFeed::SpamAssassin
    config:
      spam_tag: SPAM
      add_tag_to_title: 1
      add_report: 0
      new:
        local_tests_only: 1
        config_text:
          - score MISSING_SUBJECT 0.0
          - score MISSING_HB_SEP  0.0
          - score MISSING_HEADERS 0.0
          - score EMPTY_MESSAGE   0.0
          - score NO_RELAYS       0.0
          - score NO_RECEIVED     0.0
          - score TO_CC_NONE      0.0

=head1 CONFIG

=over 4

=item spam_tag

Specifies a tag string that will be added to entry's title or
tag (category)

=item add_tag_to_title

If set to true, the tag (enclosed in brackets) will be added to spam
entry's title.

=item add_report

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
