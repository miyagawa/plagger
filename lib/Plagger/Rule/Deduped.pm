package Plagger::Rule::Deduped;
use strict;
use base qw( Plagger::Rule );

use UNIVERSAL::require;

sub init {
    my $self = shift;

    $self->{engine} ||= 'DB_File';

    my $class = "Plagger::Rule::Deduped::$self->{engine}";
    $class->require or Plagger->context->error("Error loading $class: $@");

    my $deduper = $class->new($self);
    $self->{deduper} = $deduper;
}

sub id {
    my $self = shift;
    return "Deduped";
}

sub as_title {
    my $self = shift;
    return "Deduped entries";
}

sub dispatch {
    my($self, $args) = @_;

    unless ($args->{entry}) {
        Plagger->context->error("This rule needs entry object to work.");
    }

    my $is_new = $self->{deduper}->is_new($args->{entry});
    $self->{deduper}->add($args->{entry}) if $is_new;

    return $is_new;
}

1;

__END__

=head1 NAME

Plagger::Rule::Deduped - Rule to get Deduped entries based on the database

=head1 SYNOPSIS

  # remove entries you already seen
  - module: Filter::Rule
    rule:
      module: Deduped
      path: /tmp/var.db

=head1 DESCRIPTION

This rule de-duplicates entry based on cached index (database).

=head1 CONFIG

=over 4

=item path

Specified path to the database. This config is dependent for the
DB_File backend.

=item compare_body

If set, this rule checks digest of entry, which is a MD5 hash of
entry's title with body. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

Kazuhiro Osawa created Plagger::Plugin::Cache in early days, which
gives me a base idea of this module.

=head1 SEE ALSO

L<Plagger>, L<DB_File>

=cut
