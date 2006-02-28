package Plagger::Plugin::Filter::HatenaDiaryKeywordLink;
use strict;
use base qw( Plagger::Plugin );

use URI;
use XMLRPC::Lite;

our $XMLRPC_URL = 'http://d.hatena.ne.jp/xmlrpc';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    $context->log(info => "hatena diary keyword auto link start : " . $args->{entry}->link);

    my $rpc = XMLRPC::Lite->new;
    $rpc->proxy($XMLRPC_URL);
    my $body = $args->{entry}->body;

    my $res = $rpc->call('hatena.setKeywordLink' => {
        body => XMLRPC::Data->type('string', $body),
        a_target => '_blank',
        a_class => 'keyword',
    });

    if (my $fault = $res->fault){
        for (keys %{$fault}){
            $context->log(warn => "hatena diary keyword auto link failed : $_ => " . $fault->{$_});
        }
    } else {
        $body = $res->result;
        $body =~ s/&lt;/</ig;
        $body =~ s/&gt;/>/ig;
        $body =~ s/&quot;/"/ig;
    }

    $args->{entry}->body($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaDiaryKeywordLink - HatenaDiary keyword link

=head1 SYNOPSIS

  - module: Filter::HatenaBookmarkTag

=head1 DESCRIPTION

This plugin queries Hatena Diary (L<http://d.hatena.ne.jp/>) using
its Keyword AutoLink API to link to hatena keyword.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plagger>,
L<http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%C0%A5%A4%A5%A2%A5%EA%A1%BC%A5%AD%A1%BC%A5%EF%A1%BC%A5%C9%BC%AB%C6%B0%A5%EA%A5%F3%A5%AFAPI>

=cut
