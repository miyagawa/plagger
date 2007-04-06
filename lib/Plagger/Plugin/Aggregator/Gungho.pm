# $Id$
#
#
#

package Plagger::Plugin::Aggregator::Gungho::Handler;
use strict;
use base qw(Gungho::Handler::Null);

__PACKAGE__->mk_accessors($_) for qw(gungho_plugin);

sub handle_response
{
    my $self = shift;
    my $c    = shift;
    my $res  = shift;

    $self->next::method($c, $res);
    $self->gungho_plugin->handle_feed($res->request->uri, $res->content_ref);
}

package Plagger::Plugin::Aggregator::Gungho;
use strict;
use base qw(Plagger::Plugin::Aggregator::Simple);
use Gungho;
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(requests);

sub register
{
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle'   => \&accumulate,
        'aggregator.finalize' => \&aggregate,
    );
    $self->requests([]);
}

sub accumulate
{
    my($self, $context, $args) = @_;
    
    my $url = $args->{feed}->url;
    return unless $url =~ m!^https?://!i;

    $context->log(info => "Fetch $url");
    push @{ $self->requests }, Gungho::Request->new(GET => $url);
}

sub aggregate
{
    my ($self, $context) = @_;
    my $g = Gungho->new({
        provider => {
            module => 'Simple'
        },
        handler  => {
            module => '+Plagger::Plugin::Aggregator::Gungho::Handler'
        }
    });
    $g->provider()->requests( $self->requests );
    $g->provider()->has_requests( 1 );
    $self->requests([]);
    $g->handler()->gungho_plugin( $self );
    $g->run;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Aggregator::Gungho - Go Gungho!

=head1 SYNOPSIS

  - module: Aggregator::Gungho

=head1 DESCRIPTION

[06 Apr 2007] Gungho is, as of this writing, extremely new crawler framework. 
Beware of bugs! Please report them to the author. I'll be happy to apply
patches or fix problems.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1

