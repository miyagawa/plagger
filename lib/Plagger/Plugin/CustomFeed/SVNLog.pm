package Plagger::Plugin::CustomFeed::SVNLog;

use strict;
use base qw( Plagger::Plugin );
use SVN::Core;
use SVN::Client;
use DateTime::Format::Strptime;

our $VERSION = '0.01';

our $error_msg;
our @data;
our $current_target;

$SVN::Error::handler = \&error_handler;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    $self->{svnlog} = SVN::Client->new();

    my $feed = Plagger::Feed->new;
    $feed->aggregator(sub { $self->aggregate(@_) });
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    $error_msg = '';
    @data = ();
    $current_target = '';

    if (ref($self->conf->{target}) ne 'ARRAY') {
        $self->conf->{target} = [$self->conf->{target}];
    }

    my $feed = Plagger::Feed->new;
    $feed->type('svnlog');
    $feed->title($self->conf->{title} or 'SVN Log');
    $feed->link($self->conf->{link} or $self->conf->{target}->[0]);

    my $revision_from = $self->conf->{revision_from} || 1;
    my $revision_to   = $self->conf->{revision_to}   || 'HEAD';

    for my $target (@{ $self->conf->{target} }) {
        $context->log(debug => 'Connecting repository ' . $target);

        $current_target = $target;
        $self->{svnlog}->log(
            $target,
            $revision_from,
            $revision_to,
            1,
            1,
            \&log_receiver
        );

        if ($error_msg) {
            $context->log(error => $error_msg);
            exit;
        }
    }

    my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%H:%M:%S.%6NZ');

    if ($self->conf->{reverse}) {
        @data = sort { $b->{revision} <=> $a->{revision} } @data;
    }
    else {
        @data = sort { $a->{revision} <=> $b->{revision} } @data;
    }

    my $items_count = 0;
    for my $data (@data) {
        last if $items_count++ >= $self->conf->{fetch_items};

        my $entry = Plagger::Entry->new;
        $entry->title('revision ' . $data->{revision});
        $entry->link($data->{target});
        $entry->author($data->{author});
        $entry->date( Plagger::Date->parse($format, $data->{date}) );
        $entry->body($data->{message});

        $feed->add_entry($entry);
    }
    $context->update->add($feed);
}

sub log_receiver {
    my ($changed_paths, $revision, $author, $date, $message, $pool) = @_;

    $message =~ s/\x0D\x0A|\x0D|\x0A/<br>/g;
    push(@data, {
        target => $current_target,
        changed_paths => [sort keys %$changed_paths],
        revision => $revision,
        author => $author,
        date => $date,
        message => $message,
    });
}

sub error_handler {
    if (ref($_[0]) and UNIVERSAL::isa($_[0], '_p_svn_error_t')) {
        $error_msg = $_[0]->message;
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::SVNLog -  Custom feed for SVN Log

=head1 SYNOPSIS

    - module: CustomFeed::SVNLog
      config:
        target: scheme://url/to/repository
        title: SVN Log of blah blah blah
        link: http://url/to/repository/viewer
        revision_from: 5
        revision_to: 123
        reverse: 1
        fetch_items: 20

=head1 DESCRIPTION

This plugin fetches log from svn repository and creates a custom feed.

=head1 CONFIGURATION

=over 4

=item target

Specifies the repository url.

=item title

Specifies the feed title you want. If not specified, default is 'SVN Log'.

=item link

Specifies the repository viewer url.

=item revision_from

Specifies a revision number you wish to start publish from.
default is 1.

=item revision_to

Specifies a revision number you wish to end publish to.
default is 'HEAD'.

=item reverse

If set to 1, this option makes feed to reverse order.
default is 0.

=item fetch_items

Specifies a numeric value of limit to publish.
This functions well with reverse, revision_from, and the revision_to option.

=back

=head1 AUTHOR

Michiya Honda <pia@cpan.org>

=head1 SEE ALSO

L<Plagger>, L<SVN::Client>

=cut
