package Plagger::Rule::FeedType;
use strict;
use base qw( Plagger::Rule );


sub init {
    my $self = shift;

    if (my $type = $self->{type}) {
        $type = [ $type ] if ref($type) ne 'ARRAY';
	$self->{type} = +{ map {$_ => 1} @{ $type } };
    } else {
	Plagger->context->error("Can't parse type");
    }
}

sub hooks { [ 'publish.add_feed' ] }

sub dispatch {
    my($self, $args) = @_;

    my $feed = $args->{feed}
        or Plagger->context->error("No feed object in this plugin phase");

    my $bool =  $self->{type}->{$feed->type};
    $bool = !$bool if $self->{negative};
    $bool;
}

1;
