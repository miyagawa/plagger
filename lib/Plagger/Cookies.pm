package Plagger::Cookies;
use strict;

use UNIVERSAL::require;

our %Instances;

sub create {
    my($class, $conf) = @_;

    unless (ref $conf && $conf->{type}) {
        my $file = ref $conf ? $conf->{file} : $conf;
        $conf = $class->auto_guess($file);
    }

    $Instances{$conf->{file}} ||= do {
        my $type = delete $conf->{type};
        my $impl = $type ? "HTTP::Cookies::$type" : "HTTP::Cookies";
        Plagger->context->log(debug => "$conf->{file} => $impl");
        $impl->require or Plagger->context->error("Error loading $impl: $@");

        $impl->new(%$conf);
    };
}

sub auto_guess {
    my($self, $filename) = @_;

    # autosave is off by default for foreign cookies files

    if ($filename =~ /cookies\.txt$/i) {
        return { type => 'Mozilla', file => $filename };
    }
    elsif ($filename =~ /index\.dat$/i) {
        return { type => 'Microsoft', file => $filename };
    }
    elsif ($filename =~ /Cookies\.plist$/i) {
        return { type => 'Safari', file => $filename };
    }

    Plagger->context->log(warn => "Don't know type of $filename. Use it as LWP default");
    return { file => $filename, autosave => 1 };
}

1;

__END__

=head1 NAME

Plagger::Cookies - cookie_jar factory class

=head1 SYNOPSIS

  # config.yaml: Firefox's cookies.txt
  global:
    user_agent:
      cookies: /path/to/cookies.txt

  # or more verbosely
  global:
    user_agent:
      cookies:
        type: Safari
        file: /path/to/Cookies.plist
        autosave: 1

=head1 DESCRIPTION

Plagger::Cookies is a factory class to create HTTP::Cookies subclass
instances by detecting the proper subclass using its filename (and
possibly magic, if the filename format is share amongst multiple
subclasses, eventually).

=head1 THANKS TO

Thanks to brian d foy and Gisle Aas for creating HTTP::Cookies::* subclass modules.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTTP::Cookies>, L<HTTP::Cookies::Mozilla>, L<HTTP::Cookies::Microsoft>

=cut
