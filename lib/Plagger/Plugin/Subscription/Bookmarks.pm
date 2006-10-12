package Plagger::Plugin::Subscription::Bookmarks;
use strict;
use base qw( Plagger::Plugin );

use UNIVERSAL::require;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    
    my $browser = $self->conf->{browser} || $self->auto_configure;
    my $class = __PACKAGE__ . "::$browser";
    $class->require or Plagger->context->error("Error loading $class: $@");
    
    bless $self, $class;
}

sub auto_configure {
    my $self = shift;

    my $path = $self->conf->{path};
    if ($path) {
        if (-d _ && $^O eq 'MSWin32') {
            Plagger->context->log(debug => "$path is a directory. read as IE");
            return "InternetExplorer";
        } elsif ($path =~ /bookmarks\.html$/i) {
            Plagger->context->log(debug => "$path is a Mozilla bookmarks");
            return "Mozilla";
        } elsif ($path =~ /Bookmarks\.plist$/) {
            Plagger->context->log(debug => "$path is a Safari bookmarks");
            return "Safari";
        } else {
            Plagger->context->error("Don't know Bookmark type of $path");
        }
    }
    
    # Hmm, no clue for path. Find it automatically ... only works for IE
    if ($^O eq 'MSWin32') {
        return "InternetExplorer";
    } elsif ($^O eq 'darwin') {
        return "Safari"; # xxx
    } else {
        return "Mozilla"; # xxx don't work because path is missing
    }
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => $self->can('load'),
    );
}

sub load { die "Override load" }

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::Bookmarks - Subscribe to URLs in Favorites / Bookmarks

=head1 SYNOPSIS

  # DWIM: auto-detect browsers (and path) from your OS
  - module: Subscription::Bookmarks
  
  # be a little explicit
  - module: Subscription::Bookmarks
    config:
      browser: InternetExplorer

  # auto-configure as Mozilla
  - module: Subscription::Bookmarks
    config:
      path: /path/to/bookmarks.html

  # auto-configure as Safari
  - module: Subscription::Bookmarks
    config:
      path: /path/to/Bookmarks.plist

  # more verbose
  - module: Subscription::Bookmarks
    config:
      browser: Mozilla
      path: /path/to/bookmarks.html

=head1 DESCRIPTION

This plugin allows you to subscribe to your Bookmarks (or Favorites) of your browser
like IE, Firefox or Safari.

=head1 CONFIGURATION

=over 4

=item browser

Specify your browser name. Possible values are 'InternetExplorer', 'Mozilla' and 'Safari'.

=item path

Specify path to your bookmarks file (or directory).

=back

Configuration is optional. When you omit I<browser>, this plugin auto-configure
the default config. On Win32, I<browser> is "InternetExplorer" and I<path> is looked up
using Windows Registry. On darwin, I<browser> is "Safari". Otherwise, I<browser> is set 
to "Mozilla", but I<path> isn't set.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Netscape::Bookmarks>, L<Win32::IEFavorites>
