package Plagger::Plugin::Filter::RewriteEnclosureURL;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{rewrite} or Plagger->context->error("config 'rewrite' is not set.");
    $self->conf->{rewrite} = [ $self->conf->{rewrite} ] unless ref $self->conf->{rewrite};
}

sub filter {
    my($self, $context, $args) = @_;

    for my $enclosure ($args->{entry}->enclosures) {
        my $local_path = $enclosure->local_path;
        unless ($local_path) {
            $context->log(error => "\$enclosure->local_path is not set. You need to load Filter::FetchEnclosure to use this plugin.");
            return;
        }

        for my $rewrite (@{ $self->conf->{rewrite} }) {
            if ($local_path =~ s/^$rewrite->{local}//) {
                $enclosure->url( $rewrite->{url} . $local_path );
                $context->log(info => "enclosure URL set to " . $enclosure->url);
                last;
            }
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::RewriteEnclosureURL - Rewrite enclosure URL for republishing

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure
    config:
      dir: /home/miyagawa/public_html

  - module: Filter::RewriteEnclosureURL
    config:
      rewrite:
        - local: /home/miyagawa/public_html/
          url:   http://rock/~miyagawa/

=head1 DESCRIPTION

This plugin downloads enclosure files set for each entry.

=head1 TODO

=over 4

=item Support asynchronous download using POE

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

