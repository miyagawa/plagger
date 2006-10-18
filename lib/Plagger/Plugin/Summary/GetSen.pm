package Plagger::Plugin::Summary::GetSen;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use XMLRPC::Lite;

sub register {
    my($self, $context) = @_;
    $context->autoload_plugin({ module => 'Filter::GuessLanguage' });
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $lang = $args->{entry}->language || $args->{feed}->language;
    return unless $lang && $lang eq 'ja';

    $context->log(info => "Call GetSen XMLRPC API for " . ( $args->{entry}->permalink || '(no-url)' ));
    my $res;
    eval {
        $res = XMLRPC::Lite->proxy("http://www.ryo.com/getsen/rpc.php")
            ->call("ryocomJapanese.getsen", encode_utf8($args->{text}->plaintext))
            ->result;
    };

    if (my $err = $res->{flerror} ? $res->{message} : $@) {
        $context->log(error => "Got error: $err");
        return;
    }

    decode_utf8($res->{summarySentence});
}

1;
__END__

=for stopwords GetSen

=head1 NAME

Plagger::Plugin::Summary::GetSen - Use GetSen XML-RPC API to extract summary from Japanese text

=head1 SYNOPSIS

  - module: Summary::GetSen

=head1 DESCRIPTION

This plugin uses GetSen L<http://www.ryo.com/getsen/getsen.php>
XML-RPC API to auto-summarize Japanese text.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.ryo.com/getsen/getsen.php>, L<http://www.ryo.com/ryo/2005/06/03/45/>

=cut
