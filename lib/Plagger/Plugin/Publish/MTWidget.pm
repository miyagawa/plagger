package Plagger::Plugin::Publish::MTWidget;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $mt_home = $self->conf->{mt_path}
        or Plagger->context->error('mt_path is missing');

    $ENV{MT_HOME} = $mt_home;
    unshift @INC, File::Spec->catfile($mt_home, 'lib');

    eval {
	require MT; 
        require MT::Template;
	$self->{mt} = MT->new or Plagger->context->error(MT->errstr);
    };
    if ($@) {
        Plagger->context->error("Error loading MT: $@");
    }
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $blog_id = $self->conf->{blog_id} || 1;
    my $title = $self->conf->{title} || $args->{feed}->title;
    my $body  = $self->templatize($context, $args);

    my $trimed_title = substr($title, 0, 10);
       $trimed_title .= '..' if $trimed_title ne $title;
    my $widget_title = "Sidebar: $trimed_title";

    my $tmpl = MT::Template->load({ name => $widget_title });

    if ($tmpl) {
	$context->log(info => "Updating MT Widget for $title on blog_id $blog_id");
    } else {
	$context->log(info => "Creating MT Widget for $title on blog_id $blog_id");
	$tmpl = MT::Template->new;
	$tmpl->blog_id($blog_id);
	$tmpl->type('custom');
	$tmpl->name($widget_title);
    }

    $tmpl->text($body);
    $tmpl->save or $context->error($tmpl->errstr);
}

sub templatize {
    my($self, $context, $args) = @_;

    my $tt = $context->template();
    $tt->process('mt_widget.tt', $args, \my $out)
        or $context->error($tt->error);

    $out;
}

sub finalize {
    my($self, $context) = @_;

    my $rebuild = $self->conf->{rebuild} or return;
       $rebuild = [ $rebuild ] unless ref($rebuild);
    my $blog_id = $self->conf->{blog_id};

    for my $tmpl (@{$rebuild}) {
	$context->log(info => "Rebuilding Template $tmpl");

	my $template = MT::Template->load({
	    name => $rebuild, blog_id => $blog_id,
	});
	unless ($template) {
	    $context->log(error => "Can't load template $rebuild");
	    next;
	}

	$self->{mt}->rebuild_indexes( BlogID => $blog_id, Template => $template, Force => 1 )
	    or $context->log(error => "Rebuild error: " . $self->{mt}->errstr);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::MTWidget - Publish feeds as MT widget

=head1 SYNOPSIS

  - module: Publish::MTWidget
    config:
      blog_id: 1
      mt_path: /path/to/mt
      rebuild:
        - Main Index

=head1 DESCRIPTION

This plugin automatically creates Movable Type's Sidebar Manager
compatible Widget using MT Perl API. You need to run Plagger in a box
where MT is installed.

=head1 AUTHOR

Tatsuhiko Miyagawa

Thanks to Benjamin Trott and Anil Dash for the idea, and Byrne Reese
for creating MT Sidebar Manager.

=head1 SEE ALSO

L<Plagger>, L<http://www.majordojo.com/projects/SidebarManager/>

=cut

