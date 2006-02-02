package Plagger::Entry;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( title author tags date link id summary body ));

use DateTime::Format::Mail;

sub new {
    my($class, $item) = @_;

    my @subject = $item->{dc}->{subject} ? ($item->{dc}->{subject}) : ();

    my $date = DateTime::Format::Mail->parse_datetime($item->{pubDate});
    $date = Plagger::Date->rebless($date);

    bless {
        title  => $item->{title},
        author => $item->{dc}->{creator},
        tags   => \@subject,
        date   => $date,
        link   => $item->{link},
        id     => $item->{guid},
        body   => $item->{description},
    }, $class;
}

1;

