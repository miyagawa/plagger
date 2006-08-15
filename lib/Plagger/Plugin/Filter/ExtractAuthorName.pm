package Plagger::Plugin::Filter::ExtractAuthorName;
use strict;
use base qw( Plagger::Plugin );

use Email::Address;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup'  => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    $self->extract($args->{feed});
    for my $entry ($args->{feed}->entries) {
        $self->extract($entry);
    }
}

sub extract {
    my($self, $stuff) = @_;

    return unless $stuff->author && $stuff->author =~ /\@/;

    eval {
        my $address = (Email::Address->parse($stuff->author))[0];
        if (my $name = $address->name) {
            $stuff->author($name);
            Plagger->context->log(info => "Author name '$name' is extracted and set");
        }
    };

    if ($@) {
        Plagger->context->log(warn => "Failed to parse author field: $@");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::ExtractAuthorName - Extract author's name from RSS 2.0 <author> field

=head1 SYNOPSIS

  - module: Filter::ExtractAuthorName

=head1 DESCRIPTION

This plugin extracts author's actual name from RSS 2.0 author
field. In RSS 2.0 (or 0.91), you need to write:

  <author>lawyer@example.com (Lawyer Boyer)</author>

but typically you just want the name, I<Lawyer Boyer> and ditch the
email address. This plugin uses Email::Address module to extract the
name part, if any.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Email::Address>

=cut

