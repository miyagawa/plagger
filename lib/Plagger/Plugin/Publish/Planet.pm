package Plagger::Plugin::Publish::Planet;
use strict;
use base qw( Plagger::Plugin );

use File::Copy::Recursive qw[rcopy];
use HTML::Tidy;
use HTML::Scrubber;

our $VERSION = '0.01';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&add_feed,
    );
}

sub add_feed {
    my($self, $context, $args) = @_;
    my $feed = $args->{feed};
    if ($feed->id ne 'smartfeed:all') {
        $context->error("Publish::Planet requires SmartFeed::All to run.");
    }

    $self->_sanitize_entries($context, $feed);

    $self->_write_index(
        $context,
        $self->templatize($context, $feed),
        $self->conf->{dir} . '/index.html',
    );
    
    $self->_apply_skin(
        $context,
        $self->conf->{skin},
        $self->conf->{dir},
    );
}


sub templatize {
    my($self, $context, $feed) = @_;
    my $tt   = $context->template();
    my $skin = $self->conf->{skin} || 'default';

    $tt->process("$skin/template/index.tt", {
        feed  => $feed,
    }, \my $out) or $context->error($tt->error);
    $out;
}

sub _sanitize_entries {
    my ($self, $context, $feed) = shift;
    
    foreach my $entry (@{$feed->{entries}}) {
        $entry->{body} = HTML::Tidy->new->clean($entry->{body});
        $entry->{body} = HTML::Scrubber->new->scrub($entry->{body});
    }
}

sub _write_index {
    my ($self, $context, $index, $file) = @_;

    open my $out, ">:utf8", $file or $context->error("$file: $!");
    print $out $index;
    close $out;
}

sub _apply_skin {
    my ($self, $context, $skin_name, $output_dir) = @_;
    
    $context->log(debug => "Assets Directory: " . $self->assets_dir);
    
    rcopy(
        join('/', $self->assets_dir, $skin_name, 'static'),
        $output_dir,
    ) or $context->error("rcopy: $!");
}

1;

