package Plagger::Plugin::CustomFeed::PerlMonks;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use Plagger::Util;
use URI;
use URI::QueryParam;
use XML::LibXML;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my ( $self, $context, $args ) = @_;

    if ( $args->{feed}->url =~ /perlmonks.(?:com|org)\/\?node_id=30175$/ ) {
        $self->aggregate( $context, $args );
        return 1;
    }

    return;
}

sub aggregate {
    my ( $self, $context, $args ) = @_;

    my $url = URI->new( $args->{feed}->url );
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res   = $agent->fetch( $url, $self );

    if ( $res->is_error ) {
        $context->log( error => "GET $url failed: " . $res->status );
        return;
    }

    my $content = Plagger::Util::decode_content($res);
    my $title   = "Perl Monks Newest Nodes";

    my $feed = Plagger::Feed->new;
    $feed->title($title);
    $feed->meta( $args->{feed}->meta );
    $feed->link( $args->{feed}->url );

    my $parser = XML::LibXML->new;
    my $pm_doc = $parser->parse_string( $content );

    my ($node) = $pm_doc->findnodes("/NEWESTNODES/INFO");

    my @nodes = ();
    for my $node ( $pm_doc->findnodes("/NEWESTNODES/NODE") ) {
        my $type = $node->getAttribute( 'nodetype' );
        next if $type eq "note" || $type eq "user";

        my $new_node = {
            author     => $node->getAttribute('authortitle'),
            createtime => $node->getAttribute('createtime'),
            title      => $node->textContent,
        };

        $new_node->{title} =~ s/\n//g;
        $new_node->{link} = "http://perlmonks.org/?node_id="
            . $node->getAttribute('node_id');

        push @nodes, $new_node;
    }

    for my $node ( sort { $a->{createtime} <=> $b->{createtime} } @nodes ) {
        my $entry = Plagger::Entry->new;
        $entry->title( $node->{title} );
        $entry->link( $node->{link} );
        $entry->author( $node->{author} );

        my $dt = Plagger::Date->strptime( "%Y%m%d%H%M%S", $node->{createtime} );
        $dt->set_time_zone('America/New_York');
        $entry->date( $dt );

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::PerlMonks - Perl Monks Newest Nodes Custom Feed

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - http://perlmonks.org/?node_id=30175

  - module: CustomFeed::PerlMonks

=head1 DESCRIPTION

This plugin creates a custom feed off of the Perl Monks Newest Nodes
XML Feed.

=head1 AUTHOR

Jeff Bisbee

=head1 SEE ALSO

L<Plagger>

=cut
