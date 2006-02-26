package Plagger::Plugin::Publish::Speech;
use strict;
use base qw( Plagger::Plugin );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    if ($^O eq 'MSWin32') {
        require Plagger::Plugin::Publish::Speech::Win32;
        bless $self, 'Plagger::Plugin::Publish::Speech::Win32';
#    } elsif ($^O eq 'Darwin') {
# xxx somebody will write MacOSX.pm
    } else {
        Plagger->context->error("Speech plugin doesn't run on your platform $^O");
    }
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => $self->can('feed'),
        'publish.finalize' => $self->can('finalize'),
    );
}

sub feed      { $_[1]->error('Subclass should override this') }
sub finalize { $_[1]->error('Subclass should override this') }

1;
