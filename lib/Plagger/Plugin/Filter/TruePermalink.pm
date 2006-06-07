package Plagger::Plugin::Filter::TruePermalink;
use strict;
use base qw( Plagger::Plugin );

use DirHandle;
use YAML;
use Plagger::UserAgent;
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
    my $data = YAML::LoadFile($file);
    if (ref($data) eq 'ARRAY') {
        push @{$self->{redirectors}}, { follow_link => "^(?:" . join("|", @$data) . ")" };
    } else {
        push @{$self->{plugins}}, $data;
    }
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

    $self->rewrite(sub { $args->{entry}->link }, sub { $args->{entry}->link(@_) }, $args);
    for my $enclosure ($args->{entry}->enclosures) {
        $self->rewrite(sub { $enclosure->url }, sub { $enclosure->url( URI->new(@_) ) });
    }
}

sub rewrite {
    my($self, $getter, $callback) = @_;

    my $loop;
    while ($self->rewrite_link($getter, $callback, $args)) {
        if ($loop++ >= 100) {
            Plagger->error("Possible infinite loop on " . $getter->());
        }
    }
}

sub rewrite_link {
    my($self, $getter, $callback, $args) = @_;

    my $context = Plagger->context;

    my $link = $getter->();
    my $orig = $link; # copy
    my $count = 0;
    my $rewritten;

    for my $plugin (@{ $self->{plugins}}) {
        my $match = $plugin->{match} || '.'; # anything
        next unless $link =~ m/$match/i;

        if ($plugin->{rewrite}) {
            local $_ = $link;
            my $done = eval $plugin->{rewrite};
            if ($@) {
                $context->error("$@ in $plugin->{rewrite}");
            } elsif ($done) {
                $count += $done;
                $rewritten = $_;
                last;
            }
        } elsif ($plugin->{query_param}) {
            my $param = URI->new($link)->query_param($plugin->{query_param})
                or $context->error("No query param $plugin->{query_param} in " . $link);
            $count++;
            $rewritten = $param;
            last;
        }
    }

    unless ($count) {
        for my $red (@{ $self->{redirectors} }) {
            next unless $red->{follow_link};
            if ($link =~ /$red->{follow_link}/i) {
                my $url = $self->follow_redirect($link);
                if ($url && $url ne $link) {
                    $count++;
                    $rewritten = $url;
                    last;
                }
            }
        }
    }

    if ($count) {
        $callback->($rewritten);
        $context->log(info => "Link $orig rewritten to $rewritten");
    }

    return $count;
}

sub follow_redirect {
    my($self, $link) = @_;

    my $url = $self->cache->get_callback(
        "redirector:$link",
        sub {
            my $ua  = Plagger::UserAgent->new;
            my $res = $ua->simple_request( HTTP::Request->new(GET => $link) );
            if ($res->is_redirect) {
                return $res->header('Location');
            }
            return;
        },
        '1 day',
    );

    Plagger->context->log(debug => "Resolving redirection of $link: $url") if $url;

    return $url;
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

This plugin rewrites I<link> attribute of C<$entry>, rather than
I<permalink>. If C<$entry> has enclosures, this plugin also tries to
rewrite url of them.

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
