package Plagger::Plugin::Publish::Growl;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Mac::Growl ':all';

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
 	'publish.init' => \&initialize,
        'publish.entry' => \&entry,
    );
}

sub initialize {
    my ($self, $context) = @_;
    my @updates;
    for my $update ($context->update->feeds){
	push @updates, encode_utf8($update->title_text);
    }
    Mac::Growl::RegisterNotifications("plagger", [@updates],[@updates]);
}

sub entry {
    my($self, $context, $args) = @_;
    Mac::Growl::PostNotification(
        "plagger",
	encode_utf8($args->{feed}->title_text),
        encode_utf8($args->{entry}->title_text),
        encode_utf8($args->{entry}->body_text)
    );
}

1;


