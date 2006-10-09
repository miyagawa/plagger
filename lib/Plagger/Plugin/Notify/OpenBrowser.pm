package Plagger::Plugin::Notify::OpenBrowser;
use strict;
use base qw( Plagger::Plugin );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $class  = 'Plagger::Plugin::Notify::OpenBrowser::' . lc($^O);
    eval "require $class;";
    if ($@) {
        Plagger->context->error("Browser plugin doesn't run on your platform $^O");
    }
    bless $self, $class;
}

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
    );
}

sub entry {
    my($self, $context, $args) = @_;
    $self->open($args->{entry}->permalink);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::OpenBrowser - Open updated entries in a browser

=head1 SYNOPSIS

  - module: Notify::OpenBrowser

=head1 DESCRIPTION

This plugins opens updated entries in a browser of your choice. This
module will automatically use system default browser, except your OS
is Unix which uses Firefox explicitly.

=head1 EXAMPLES

Following configuration will get new items from your del.icio.us
network, deduplicate them and open them in a browser.

  - module: Subscription::Config
    config:
      feed:
        - http://del.icio.us/rss/network/{username}?private={private}

  - module: Filter::Rule
    rule:
      module: Deduped

  - module: Notify::OpenBrowser

=head1 AUTHOR

Masahiro Nagano

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
