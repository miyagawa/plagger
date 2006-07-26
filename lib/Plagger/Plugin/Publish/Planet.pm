package Plagger::Plugin::Publish::Planet;
use strict;
use base qw( Plagger::Plugin );

use File::Copy::Recursive qw[rcopy];
use File::Spec;
use URI;

our $VERSION = '0.02';

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

    my $theme = $self->conf->{theme} || $self->conf->{skin} || 'default'; # 'skin' as backward compatible
    my $file = File::Spec->catfile($theme, 'template', 'index.tt');

    my $stash = $self->build_stash;

    my $vars = {
        %$stash,
        feed    => $feed,
        entries => [ grep is_http($_->link), $feed->entries ],
        members => [ $context->subscription->feeds ],
    };

    $self->_write_index(
        $context,
        $self->templatize($file, $vars),
        File::Spec->catfile($self->conf->{dir}, 'index.html'),
    );

    $self->_apply_theme(
        $context,
        $theme,
        $self->conf->{dir},
    );
}

sub is_http {
    my $uri = URI->new(shift);
    my $scheme = $uri->scheme or return;
    $scheme eq 'http' or $scheme eq 'https';
}

sub build_stash {
    my $self = shift;

    my $stash = $self->conf->{template} || {};

    # backward compatible for non Bundle::Planet users
    $stash->{url}->{base} ||= '';
    $stash->{url}->{atom} ||= "$stash->{url}->{base}/smartfeed_all.atom";
    $stash->{url}->{rss}  ||= "$stash->{url}->{base}/smartfeed_all.rss";

    # make style_url as absolute URIs
    if (my $stylesheet = $stash->{style_url} and $stash->{url}->{base}) {
        $stylesheet = [ $stylesheet ] unless ref $stylesheet;
        $stash->{style_url} = [ map URI->new_abs($_, $stash->{url}->{base})->as_string, @$stylesheet ];
    }

    $stash;
}

sub _write_index {
    my ($self, $context, $index, $file) = @_;

    $context->log(info => "Save Planet HTML to $file");
    open my $out, ">:utf8", $file or $context->error("$file: $!");
    print $out $index;
    close $out;
}

sub _apply_theme {
    my ($self, $context, $theme_name, $output_dir) = @_;
    $context->log(debug => "Assets Directory: " . $self->assets_dir);

    my $static = File::Spec->catfile($self->assets_dir, $theme_name, 'static');
    if (-e $static) {
        rcopy($static, $output_dir) or $context->log(error => "rcopy: $!");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Planet - Planet XHTML publisher

=head1 SYNOPSIS

  - module: Publish::Planet
    rule:
      expression: $args->{feed}->id eq 'smartfeed:all'
    config:
      dir: /path/to/htdocs
      theme: sixapart-std

=head1 DESCRIPTION

This plugin generates XHTML out of aggregated feeds suitable to put on
the web as "Blog aggregator" like Python Planet does.

=head1 CONFIG

=over 4

=item dir

Directory to save output XHTML and CSS files in. Required.

=item theme

Name of "theme" to use as an XHTML template. Available options are
I<default> and I<sixapart-std>. Optional and defaults to 'default'.

=item template

Stash variables to pass to template. Example:

  template:
    style_url: http://example.com/foo.css
    url:
      base: http://example.org/planet/

=over 8

=item style_url

  style_url: http://www.example.com/style.css

URL of stylesheet to use in templates. You can pass multiple URLs by passing an array. Optional.

=item url

  url:
    base: http://example.com/planet/

URL to be used as a Planet base. This URL is used as a base URL for
RSS/Atom feeds and stylesheet if they're relative.. Optional.

=back

=back

=head1 EXAMPLES

You can see a couple of Publish::Planet powered sites.

L<http://plagger.org/planet/>

L<http://planet.yapcchicago.org/>

=head1 AUTHOR

Casey West

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://plagger.org/planet/>, L<http://planetplanet.org/>
