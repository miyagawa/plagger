package Plagger::Plugin::Bundle::Planet;
use strict;
use base qw( Plagger::Plugin );

use File::Spec;

sub register {
    my($self, $context) = @_;

    # check required configs
    for my $directive (qw( title dir url )) {
        unless ($self->conf->{$directive}) {
            $context->error("Bundle::Planet: config '$directive' is missing");
        }
    }

    $context->load_plugin({
        module => 'Filter::StripTagsFromTitle',
    });

    $context->load_plugin({
        module => 'Filter::HTMLScrubber',
        config => $self->conf->{scrubber} || {},
    });

    my @rules;
    my $duration = defined $self->conf->{duration}
        ? $self->conf->{duration} : "7 days";
    if ($duration ne '0') {
        push @rules, {
            module   => 'Fresh',
            duration => $duration,
        };
    }

    if (my $rule = $self->conf->{extra_rule}) {
        push @rules, (ref $rule eq 'ARRAY' ? @{$rule} : ($rule));
    }

    $context->load_plugin({
        module => 'SmartFeed::All',
        rule => \@rules,
        config => {
            title => $self->conf->{title},
            link  => $self->conf->{url},
            description => $self->conf->{description},
        },
    });

    my $rule = {
        expression => q{ $args->{feed}->id eq 'smartfeed:all' },
    };

    $context->load_plugin({
        module => 'Publish::Planet',
        rule   => $rule,
        config => {
            dir  => $self->conf->{dir},
            skin => $self->conf->{theme},
            template => {
                style_url => $self->conf->{stylesheet},
                url => {
                    base => $self->conf->{url},
                    atom => $self->conf->{url} . "atom.xml",
                    rss  => $self->conf->{url} . "rss.xml",
                    opml => $self->conf->{url} . "subscriptions.opml",
                    foaf => $self->conf->{url} . "foafroll.xml",
                },
            },
        },
    });

    $context->load_plugin({
        module => 'Publish::Feed',
        rule   => $rule,
        config => {
            dir => $self->conf->{dir},
            filename => 'atom.xml',
            format => 'Atom',
        },
    });

    $context->load_plugin({
        module => 'Publish::Feed',
        rule   => $rule,
        config => {
            dir => $self->conf->{dir},
            filename => 'rss.xml',
            format => 'RSS',
        },
    });

    $context->load_plugin({
        module => 'Publish::OPML',
        config => {
            filename => File::Spec->catfile($self->conf->{dir}, 'subscriptions.opml'),
            title => $self->conf->{title},
        },
    });

    $context->load_plugin({
        module => 'Publish::FOAFRoll',
        config => {
            filename => File::Spec->catfile($self->conf->{dir}, 'foafroll.xml'),
            link => $self->conf->{url},
            url  => $self->conf->{url} . "foafroll.xml",
            title => $self->conf->{title},
        },
    });
}

1;

__END__

=head1 NAME

Plagger::Plugin::Bundle::Planet - Bundle package to create Planet site

=head1 SYNOPSIS

  - module: Bundle::Planet
    config:
      title: Planet Foobar
      dir: /path/to/planet
      url: http://example.org/planet
      theme: sixapart-std
      stylesheet: foo.css
      duration: 7 days
      description: Everything about Foobar from the Web

=head1 DESCRIPTION

This plugin is a I<Bundle> plugin to load bunch of required modules to
create Planet site with a single Plugin setup. Using this plugin will
load following plugins and automatically sets up necessary
configurations.

=over 4

=item Filter::StripTagsFromTitle

=item Filter::HTMLScrubber

=item SmartFeed::All

=item Publish::Planet

=item Publish::Feed

=item Publish::OPML

=item Publish::FOAFRoll

=back

=head1 CONFIGS

=over 4

=item title

Title of Planet site. Required.

=item dir

Directory to create HTML, Feed and CSS files in. Required.

=item url

Public URL to access the Planet site, which is used to construct Feed and CSS URLs with. Required.

=item theme

Name of I<theme> to use with Publish::Planet. Defaults to I<default>.

=item stylesheet

URL(s) of stylesheet (CSS) to use with I<sixapart-std> theme. Optional.

=item duration

Duration of feed entries to display. When you pass I<0> as a value, the Planet plugin displays
all the entries aggregated. Defaults to I<7 days>.

=item extra_rule

Additional rule to add to filter entries using SmartFeed::All. Optional and defaults to nothing.

=item description

Description to use in XHTML tagline and Atom/RSS feeds. Optional.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Publish::Feed>, L<Plagger::Plugin::Publish::Planet>

=cut
