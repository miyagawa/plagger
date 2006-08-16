package Plagger::Plugin::Filter::EntryFullText;
use strict;
use base qw( Plagger::Plugin );

use DirHandle;
use Encode;
use File::Spec;
use List::Util qw(first);
use HTML::ResolveLink;
use Plagger::Date; # for metadata in plugins
use Plagger::Util qw( decode_content );
use Plagger::Plugin::CustomFeed::Simple;
use Plagger::UserAgent;

sub rule_hook { 'update.entry.fixup' }

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle'  => \&handle,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_plugins();

    $self->{ua} = Plagger::UserAgent->new;
    $self->{ua}->parse_head(0);
}

sub load_plugins {
    my $self = shift;
    my $context = Plagger->context;

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or $context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[0] =~ /\.(?:pl|yaml)$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], sort $dh->read) {
        $self->load_plugin(@$file);
    }
}

sub load_plugin {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "loading $file");

    my $load_method = $file =~ /\.pl$/ ? 'load_plugin_perl' : 'load_plugin_yaml';
    push @{ $self->{plugins} }, $self->$load_method($file, $base);
}

sub load_plugin_perl {
    my($self, $file, $base) = @_;

    open my $fh, $file or Plagger->context->error("$file: $!");
    (my $pkg = $base) =~ s/\.pl$//;
    my $plugin_class = "Plagger::Plugin::Filter::EntryFullText::Site::$pkg";

    if ($plugin_class->can('new')) {
        Plagger->context->log(warn => "$plugin_class is already defined. skip compiling code");
        return $plugin_class->new;
    }

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::Filter::EntryFullText::Site );",
              "sub site_name { '$pkg' }",
              $code,
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    return $plugin_class->new;
}

sub load_plugin_yaml {
    my($self, $file, $base) = @_;
    my @data = YAML::LoadFile($file);

    return map { Plagger::Plugin::Filter::EntryFullText::YAML->new($_, $base) }
        @data;
}

sub handle {
    my($self, $context, $args) = @_;

    my $handler = first { $_->custom_feed_handle($args) } @{ $self->{plugins} };
    if ($handler) {
        $args->{match} = $handler->custom_feed_follow_link;
        return $self->Plagger::Plugin::CustomFeed::Simple::aggregate($context, $args);
    }
}

sub filter {
    my($self, $context, $args) = @_;

    my $handler = first { $_->handle_force($args) } @{ $self->{plugins} };
    if ( !$handler && $args->{entry}->body && $args->{entry}->body =~ /<\w+>/ && !$self->conf->{force_upgrade} ) {
        $self->log(debug => $args->{entry}->link . " already contains body. Skipped");
        return;
    }

    if (! $args->{entry}->permalink) {
        $self->log(debug => "Entry " . $args->{entry}->title . " doesn't have permalink. Skipped");
        return;
    }

    # NoNetwork: don't connect for 3 hours
    my $res = $self->{ua}->fetch( $args->{entry}->permalink, $self, { NoNetwork => 60 * 60 * 3 } );
    if (!$res->status && $res->is_error) {
        $self->log(debug => "Fetch " . $args->{entry}->permalink . " failed");
        return;
    }

    $args->{content} = decode_content($res);

    # if the request was redirected, set it as permalink
    if ($res->http_response) {
        my $base = $res->http_response->request->uri;
        if ( $base ne $args->{entry}->permalink ) {
            $context->log(info => "rewrite permalink to $base");
            $args->{entry}->permalink($base);
        }
    }

    # use Last-Modified to populate entry date, even if handler doesn't find one
    if ($res->last_modified && !$args->{entry}->date) {
        $args->{entry}->date( Plagger::Date->from_epoch($res->last_modified) );
    }

    my @plugins = $handler ? ($handler) : @{ $self->{plugins} };

    for my $plugin (@plugins) {
        if ( $handler || $plugin->handle($args) ) {
            $context->log(debug => $args->{entry}->permalink . " handled by " . $plugin->site_name);
            my $data = $plugin->extract($args);
               $data = { body => $data } if $data && !ref $data;
            if ($data) {
                $context->log(info => "Extract content succeeded on " . $args->{entry}->permalink);
                my $resolver = HTML::ResolveLink->new( base => $args->{entry}->permalink );
                $data->{body} = $resolver->resolve( $data->{body} );
                $args->{entry}->body($data->{body});
                $args->{entry}->title($data->{title}) if $data->{title};
                $args->{entry}->icon({ url => $data->{icon} }) if $data->{icon};

                # extract date using found one
                if ($data->{date}) {
                    $args->{entry}->date($data->{date});
                }

                return 1;
            }
        }
    }

    # failed to extract: store whole HTML if the config is on
    if ($self->conf->{store_html_on_failure}) {
        $args->{entry}->body($args->{content});
        return 1;
    }

    $context->log(warn => "Extract content failed on " . $args->{entry}->permalink);
}


package Plagger::Plugin::Filter::EntryFullText::Site;
sub new { bless {}, shift }
sub custom_feed_handle { 0 }
sub custom_feed_follow_link { }
sub handle_force { 0 }
sub handle { 0 }

package Plagger::Plugin::Filter::EntryFullText::YAML;
use Encode;
use List::Util qw(first);

sub new {
    my($class, $data, $base) = @_;

    # add ^ if handle method starts with http://
    for my $key ( qw(custom_feed_handle handle handle_force) ) {
        next unless defined $data->{$key};
        $data->{$key} = "^$data->{$key}" if $data->{$key} =~ m!^https?://!;
    }

    # decode as UTF-8
    for my $key ( qw(extract extract_date_format) ) {
        next unless defined $data->{$key};
	if (ref $data->{$key} && ref $data->{$key} eq 'ARRAY') {
	    $data->{$key} = [ map decode("UTF-8", $_), @{$data->{$key}} ];
	} else {
	    $data->{$key} = decode("UTF-8", $data->{$key});
	}
    }

    bless {%$data, base => $base }, $class;
}

sub site_name {
    my $self = shift;
    $self->{base};
}

sub custom_feed_handle {
    my($self, $args) = @_;
    $self->{custom_feed_handle} ?
        $args->{feed}->url =~ /$self->{custom_feed_handle}/ : 0;
}

sub custom_feed_follow_link {
    $_[0]->{custom_feed_follow_link};
}

sub handle_force {
    my($self, $args) = @_;
    $self->{handle_force}
        ? $args->{entry}->permalink =~ /$self->{handle_force}/ : 0;
}

sub handle {
    my($self, $args) = @_;
    $self->{handle}
        ? $args->{entry}->permalink =~ /$self->{handle}/ : 0;
}

sub extract {
    my($self, $args) = @_;
    my $data;

    if ($self->{extract}) {
	if (my @match = $args->{content} =~ /$self->{extract}/s) {
	    my @capture = split /\s+/, $self->{extract_capture};
	    @{$data}{@capture} = @match;
	}
    }

    if ($self->{extract_xpath}) {
        eval { require HTML::TreeBuilder::XPath };
        if ($@) {
            Plagger->context->log(error => "HTML::TreeBuilder::XPath is required. $@");
            return;
        }

        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($args->{content});
        $tree->eof;

        for my $capture (keys %{$self->{extract_xpath}}) {
            my @children = $tree->findnodes($self->{extract_xpath}->{$capture});
            $data->{$capture} = $children[0]->as_HTML;
        }
    }

    if ($data) {
        if ($self->{extract_after_hook}) {
            eval $self->{extract_after_hook};
            Plagger->context->error($@) if $@;
        }

        if ($data->{date}) {
            if (my $format = $self->{extract_date_format}) {
                $format = [ $format ] unless ref $format;
                $data->{date} = (map { Plagger::Date->strptime($_, $data->{date}) } @$format)[0];
                if ($data->{date} && $self->{extract_date_timezone}) {
                    $data->{date}->set_time_zone($self->{extract_date_timezone});
                }
            } else {
                $data->{date} = Plagger::Date->parse_dwim($data->{date});
            }
        }

        return $data;
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::EntryFullText - Upgrade your feeds to fulltext class

=head1 SYNOPSIS

  - module: Filter::EntryFullText

=head1 DESCRIPTION

This plugin allows you to fetch entry full text by doing HTTP GET and
apply regexp to HTML. It's just like upgrading your flight ticket from
economy class to business class!

You can write custom fulltext handler by putting C<.pl> or C<.yaml>
files under assets plugin directory.

=head1 CONFIG

=over 4

=item store_html_on_failure

Even if fulltext handlers fail to extract content body from HTML, this
option enables to store the whole document HTML as entry body. It will
be useful to use with search engines like Gmail and Search:: plugins.
Defaults to 0.

=item force_upgrade

Even if entry body already contains HTML, this config forces the
plugin to upgrade the body. Defaults to 0.

=back

=head1 WRITING CUSTOM FULLTEXT HANDLER

(To be documented)

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>
