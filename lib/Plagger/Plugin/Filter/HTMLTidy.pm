package Plagger::Plugin::Filter::HTMLTidy;
use strict;
use base qw( Plagger::Plugin );

use HTML::Tidy;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

our %defaults = (
    doctype      => 'omit',
    output_xhtml => 1,
    wrap         => 0,
    break_before_br => 0,
    input_encoding => 'utf8',
    output_encoding => 'utf8',
    tidy_mark => 0,
);

sub filter {
    my($self, $context, $args) = @_;

    my $body = $args->{entry}->body;
    return unless $body && $body->is_html;

    my $conf = $self->conf || {};
    while (my($key, $value) = each %defaults) {
        $conf->{$key} = $value unless exists $conf->{$key};
    }

    my $tidy = HTML::Tidy->new( $self->conf || {} );
    $tidy->ignore( type => TIDY_WARNING );
    my $new_body = $tidy->clean($body->data); # pass in Unicode string, not UTF-8

    # HACK to extract <body /> only
    $new_body =~ s!^.*<body>\s*(.*?)\s*</body>\s*</html>\s*$!$1!s;

    $args->{entry}->body($new_body);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::HTMLTidy - Filters body HTML using HTML::Tidy

=head1 SYNOPSIS

  - module: Filter::HTMLTidy
    config:
      output-xhtml: yes
      char-encoding: utf-8

=head1 DESCRIPTION

This plugin glues HTML::Tidy as an entry filter, so it scrubs HTML to
make it tidy. Best used with Publish plugins like Planet.

=head1 CONFIG

This plugin accepts any config options that can be used as htmltidy
config file.  See L<http://tidy.sourceforge.net/docs/quickref.html> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::Tidy>, L<http://tidy.sourceforge.net/docs/quickref.html>

=cut
