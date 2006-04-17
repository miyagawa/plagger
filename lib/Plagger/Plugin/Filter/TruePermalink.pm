package Plagger::Plugin::Filter::TruePermalink;
use strict;
use base qw( Plagger::Plugin );

use DirHandle;
use YAML;
use URI;
use URI::QueryParam;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_plugins;
}

sub load_plugins {
    my $self = shift;

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or Plagger->context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[1] =~ /\.yaml$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], sort $dh->read) {
        $self->load_plugin(@$file);
    }
}

sub load_plugin {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "loading $file");
    push @{$self->{plugins}}, YAML::LoadFile($file);
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $orig = $args->{entry}->permalink;
    my $count = 0;

    for my $plugin (@{ $self->{plugins}}) {
        my $match = $plugin->{match} || '.'; # anything
        next unless $args->{entry}->permalink =~ m/$match/i;

        if ($plugin->{rewrite}) {
            local $_ = $args->{entry}->permalink;
            $count += eval $plugin->{rewrite};
            if ($@) {
                $context->error("$@ in $plugin->{rewrite}");
            }
            $args->{entry}->link($_);
        } elsif ($plugin->{query_param}) {
            my $link = URI->new($args->{entry}->permalink)->query_param($plugin->{query_param})
                or $context->error("No query param $plugin->{query_param} in " . $args->{entry}->permalink);
            $args->{entry}->link($link);
            $count++;
        }
    }

    if ($count) {
        $context->log(info => "Permalink $orig rewritten to " . $args->{entry}->permalink);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::TruePermalink - Normalize permalink using its own plugin files

=head1 SYNOPSIS

  - module: Filter::TruePermalink

=head1 DESCRIPTION

This plugin normalizes permalink using YAML based URL pattern
files. Various permalink fix filters in the past (YahooBlogSearch,
Namaan, 2chRSSPermalink) can now be writting as a pattern file for
this plugin.

This plugin rewrites I<link> attribute of C<$entry>, rather than I<permalink>.

=head1 PATTERN FILES

You can write your own pattern file using YAML data format. Usable keys are:

=over 4

=item author

Your name. (Optional)

=item match

Regular expression rule to match with entry's link. Rewrites only
happen when the URL form matches. You can omit this configuration to
apply the rewrite rule to any URLs.

=item rewrite

Replacement regexp to filter permalink. Permalink is stored in C<$_> variable so that you can write:

  rewrite: s/;jsession_id=\w+//

=item query_param

URL query parameter to extract normalized permalink.

  query_param: destination

=back

See C<assets/plugins/Filter-TruePermalink> for more examples.

=head1 AUTHOR

youpy

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
