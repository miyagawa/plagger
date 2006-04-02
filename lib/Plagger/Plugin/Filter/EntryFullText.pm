package Plagger::Plugin::Filter::EntryFullText;
use strict;
use base qw( Plagger::Plugin );

use DirHandle;
use Encode;
use File::Spec;
use List::Util qw(first);
use HTML::ResolveLink;
use Plagger::Date; # for metadata in plugins
use Plagger::Util qw( decode_content );

use Plagger::UserAgent;

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
    $self->load_plugins();

    $self->{ua} = Plagger::UserAgent->new;
}

sub load_plugins {
    my $self = shift;
    my $context = Plagger->context;

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or $context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[0] =~ /\.pl$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], $dh->read) {
        $self->load_plugin(@$file);
    }
}

sub load_plugin {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "loading $file");

    open my $fh, $file or Plagger->context->error("$file: $!");
    (my $pkg = $base) =~ s/\.pl$//;
    my $plugin_class = "Plagger::Plugin::Filter::EntryFullText::Site::$pkg";

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::Filter::EntryFullText::Site );",
              "sub site_name { '$pkg' }",
              $code,
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    my $plugin = $plugin_class->new;
    push @{ $self->{plugins} }, $plugin;
}

sub filter {
    my($self, $context, $args) = @_;

    my $handler = first { $_->handle_force($args) } @{ $self->{plugins} };
    if ( !$handler && $args->{entry}->body && $args->{entry}->body =~ /<\w+>/ ) {
        $self->log(debug => $args->{entry}->link . " already contains body. Skipped");
        return;
    }

    my $res = $self->{ua}->fetch( $args->{entry}->permalink, $self );
    return if $res->http_response->is_error;

    $args->{content} = decode_content($res);

    my @plugins = $handler ? ($handler) : @{ $self->{plugins} };

    for my $plugin (@plugins) {
        if ( $handler || $plugin->handle($args) ) {
            $context->log(debug => $args->{entry}->permalink . " handled by " . $plugin->site_name);
            my $data = $plugin->extract($args);
               $data = { body => $data } if $data && !ref $data;
            if ($data) {
                $context->log(info => "Extract content succeeded on " . $args->{entry}->permalink);
                my $resolver = HTML::ResolveLink->new( base => $args->{entry}->permalink );
                $data->{body} = $resolver->resolve( $data->{body} );
                $args->{entry}->body($data->{body});
                $args->{entry}->title($data->{title}) if $data->{title};
                $args->{entry}->date($data->{date})   if $data->{date};
                return 1;
            }
        }
    }

    # failed to extract: store whole HTML if the config is on
    if ($self->conf->{store_html_on_failure}) {
        $args->{entry}->body($args->{content});
        return 1;
    }

    $context->log(warn => "Extract content failed on " . $args->{entry}->permalink);
}


package Plagger::Plugin::Filter::EntryFullText::Site;
sub new { bless {}, shift }
sub handle_force { 0 }
sub handle { 0 }

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::EntryFullText - Framework to fetch entry full text

=head1 SYNOPSIS

  - module: Filter::EntryFullText

  # assets/plugins/filter-entryfulltext/asahi_com.pl
  sub handle {
      my($self, $args) = @_;
      $args->{entry}->link =~ qr!^http://www\.asahi\.com/!;
  }

  sub extract_body {
      my($self, $content) = @_;
      ( $content =~ /<!-- Start of Kiji -->(.*)<!-- End of Kiji -->/s )[0];
  }

=head1 DESCRIPTION

This plugin allows you to fetch entry full text by doing HTTP GET and
apply regexp to HTML. You can write custom fulltext handler by putting
C<.pl> files under assets plugin directory.

=head1 CONFIG

=over 4

=item store_html_on_failure

Even if fulltext handlers fail to extract content body from HTML, this
option enables to store the whole document HTML as entry body. It will
be useful to use with search engines like Gmail and Search:: plugins.
Defaults to 0.

=back

=head1 WRITING CUSTOM FULLTEXT HANDLER

(To be documented)

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>
