package Plagger::Rule::DateTimeCron;
use strict;
use base qw( Plagger::Rule );

use Plagger::Date;
use DateTime::Event::Cron;

sub init {
    my $self = shift;
    my $now = Plagger::Date->now(%{Plagger->context->conf});
    $now->set_second(0);
    $self->{cron_valid} = 1;
    eval {
        Plagger->context->log(debug => "crontab $self->{crontab} set");
        my $cron = DateTime::Event::Cron->new_from_cron( cron => $self->{crontab} );
        $self->{cron_valid} = $cron->valid($now);
    };
    Plagger->context->error("Can't parse crontab : $@") if $@;
}

sub dispatch {
    my($self, $args) = @_;
    $self->{cron_valid};
}

1;
__END__
example config.
    rule:
      - module: DateTimeCron
        crontab: * 12 * * *
