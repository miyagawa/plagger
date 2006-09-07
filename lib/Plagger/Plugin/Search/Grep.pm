package Plagger::Plugin::Search::Grep;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use File::Grep ();
use File::Spec;
use YAML;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    _mkdir($self->conf->{dir});
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&entry,
        'searcher.search'  => \&search,
    );
}

sub entry {
    my($self, $context, $args) = @_;

    my $dir = File::Spec->catfile($self->conf->{dir}, $args->{feed}->id_safe);
    _mkdir($dir);

    my $yaml = File::Spec->catfile($dir, 'config.yaml');
    my $config = -e $yaml ? YAML::LoadFile($yaml) : {};
    for my $entry ($args->{feed}->entries) {
        next unless $entry->permalink;

        my $id = $entry->id_safe;
        my $path = File::Spec->catfile($dir, "$id.txt");
        $context->log(info => "Going to index entry " . $entry->permalink);

        $config->{$id} = {
            link   => $entry->link,
            author => _u($entry->author),
            date   => $entry->date ? $entry->date->format('W3CDTF') : '',
            title  => _u($entry->title),
            body   => _u($entry->summary) || '',
        };

        open my $out, '>', $path or $context->error("$path: $!");
        print $out join("\n", $entry->permalink, $entry->author, _u($entry->title_text), _u($entry->body_text));
        close $out;
    }

    YAML::DumpFile($yaml, $config);
}

sub search {
    my($self, $context, $args) = @_;

    my $path = File::Spec->catfile($self->conf->{dir}, '*', '*.txt');
    my $query = _u($args->{query});
    return unless $query;

    my $feed = Plagger::Feed->new;
    $feed->type('search:Grep');
    $feed->title("Search: $query");

    my $config_cache = {};
    my @matchs = grep { $_->{count} } File::Grep::fgrep { /$query/i } glob $path;
    for my $match (@matchs) {
        my ($drive, $dir, $file) = File::Spec->splitpath($match->{filename});
        $file =~ s/\.txt$//;

        my $yaml = File::Spec->catpath($drive, $dir, 'config.yaml');
        unless ($config_cache->{$yaml}) {
            $config_cache->{$yaml} = YAML::LoadFile($yaml);
        }
        my $config = $config_cache->{$yaml}->{$file};
        next unless $config;

        my $entry = Plagger::Entry->new;
        for my $key (qw( link author date title body )) {
            $entry->$key( $config->{$key} );
        }
        $feed->add_entry($entry);
    }

    return $feed;
}

sub _u {
    my $str = shift;
    Encode::_utf8_off($str);
    $str;
}

sub _mkdir {
    my $dir = shift;
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or Plagger->context->error("mkdir $dir: $!");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Search::Grep - Search entries using File::Grep

=head1 SYNOPSIS

  - module: Search::Grep
    config:
      dir: /home/yappo/plagger-grep

=head1 DESCRIPTION

This plugin uses L<File::Grep>
it's simple search interface!

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<File::Grep>

=cut
