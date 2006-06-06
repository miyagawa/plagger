package Plagger::Plugin::Publish::Planet;
use strict;
use base qw( Plagger::Plugin );

use File::Copy::Recursive qw[rcopy];
use File::Spec;
#use HTML::Tidy;
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

    $self->_sanitize_entries(
        $context,
        $feed,
#        HTML::Tidy->new,
        undef,
#        HTML::Scrubber->new(
#            rules => [
#                style => 0,
#                script => 0,
#            ],
#            default => [ 1, { '*' => 1, style => 0 } ],
#        ),
        undef,
    );

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
        %{ $self->conf->{template} },
        feed  => $feed,
        members => [ $context->subscription->feeds ],
        context => $context,
    }, \my $out) or $context->error($tt->error);
    $out;
}

sub _sanitize_entries {
    my ($self, $context, $feed, $tidy, $scrubber) = @_;
    
    foreach my $entry ($feed->entries) {
#        $entry->{body} = $tidy->clean($entry->{body});
        $entry->{body} = $scrubber->scrub($entry->{body}) if $scrubber;
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

    my $static = File::Spec->catfile($self->assets_dir, $skin_name, 'static');
    if (-e $static) {
        rcopy($static, $output_dir) or $context->log(error => "rcopy: $!");
    }
}

1;

