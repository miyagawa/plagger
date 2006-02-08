package Plagger::Rule::Rating;
use strict;
use base qw( Plagger::Rule );

my %ops = (
    '<'  => sub { $_[0] < $_[1] },
    '>'  => sub { $_[0] > $_[1] },
    '<=' => sub { $_[0] <= $_[1] },
    '>=' => sub { $_[0] >= $_[1] },
    '!=' => sub { $_[0] != $_[1] },
    '==' => sub { $_[0] == $_[1] },
);

sub init {
    my $self = shift;

    my $re = join("|", map quotemeta, keys %ops);
    $self->{rate} =~ /^($re)\s+(\-?[\d\.]+)\s*$/
        or Plagger->context->error("Can't parse rate: $self->{rate}");

    my($op, $value) = ($1, $2);
    $self->{dispatcher} = sub { $ops{$op}->($_[0], $value) };
}

sub hooks { [ 'publish.add_feed' ] }

sub dispatch {
    my($self, $args) = @_;

    my $feed = $args->{feed}
        or Plagger->context->error("No feed object in this plugin phase");

    my $rate = 0;
    $rate += $_->rate for $feed->entries;

    Plagger->context->log(debug => "dispatch rate $rate against $self->{rate}");
    $self->{dispatcher}->($rate);
}

1;
