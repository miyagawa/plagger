package Plagger::Rule::Fresh;
use strict;
use base qw( Plagger::Rule );

sub init {
    my $self = shift;
    $self->{duration} ||= 120; # minutes
}

sub id {
    my $self = shift;
    return "fresh:$self->{duration}min";
}

sub as_title {
    my $self = shift;
    return "updated within " . $self->duration_friendly;
}

sub duration_friendly {
    my $self = shift;
    eval { require Time::Duration };
    return $@ ? "$self->{duration} minutes"
              : Time::Duration::duration(60 * $self->{duration});
}

sub dispatch {
    my($self, $args) = @_;

    my $date;
    if ($args->{entry}) {
        $date = $args->{entry}->date;
    } elsif ($args->{feed}) {
        $date = $args->{feed}->updated;
    } else {
        Plagger->context->error("No entry nor feed object in this plugin phase");
    }

    $date >= Plagger::Date->now->subtract(minutes => $self->{duration});
}

1;

__END__

=head1 NAME

Plagger::Rule::Fresh - Rule to find 'fresh' entries or feeds

=head1 SYNOPSIS

  - module: SmartFeed
    config:
      id: fresh-entries
    rule:
      module: Fresh
      duration: 120

=head1 DESCRIPTION

This rule finds fresh entries or feeds, which means updated date is
within C<duration> minutes. It defaults to 2 hours, but you'd better
configure the value with your cronjob interval.

=head1 AUTHOR

Tatsuhiko Miyagawa

Thanks to youpy, who originally wrote Plagger::Plugin::Filter::Fresh
at L<http://subtech.g.hatena.ne.jp/youpy/20060224/p1>

=head1 SEE ALSO

L<Plagger>, L<Time::Duration>

=cut
