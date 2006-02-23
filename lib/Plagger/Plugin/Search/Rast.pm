package Plagger::Plugin::Search::Rast;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use POSIX;
use Rast;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
        'publish.finalize' => \&finalize,
    );
}


sub init {
    my($self) = @_;
    $self->SUPER::init(@_);

    my $dir = $self->conf->{dir};
    $self->{encode} = $self->conf->{encode} || 'utf8';

    unless (-e $dir && -d _) {
	my $ret = Rast->create($dir, {
	    encoding => $self->{encode},
	    preserve_text => 1,
	    properties => [
                   [
                    'feedlink',
                    RAST_TYPE_STRING,
                    RAST_PROPERTY_FLAG_SEARCH | RAST_PROPERTY_FLAG_TEXT_SEARCH
                    ],
                   [
                    'permalink',
                    RAST_TYPE_STRING,
                    RAST_PROPERTY_FLAG_SEARCH | RAST_PROPERTY_FLAG_TEXT_SEARCH
                    ],
                   [
                    'title',
                    RAST_TYPE_STRING,
                    RAST_PROPERTY_FLAG_TEXT_SEARCH | RAST_PROPERTY_FLAG_FULL_TEXT_SEARCH
                    ],
                   [
                    'author',
                    RAST_TYPE_STRING,
                    RAST_PROPERTY_FLAG_SEARCH | RAST_PROPERTY_FLAG_TEXT_SEARCH
                    ],
                   [
                    'date',
                    RAST_TYPE_DATE,
                    RAST_PROPERTY_FLAG_SEARCH
                    ],
                   [
                    'tags',
                    RAST_TYPE_STRING,
                    RAST_PROPERTY_FLAG_TEXT_SEARCH
                    ]
                   ],
                });
	unless ($ret) {
	    Plagger->context->error("create index error $dir");
	    return;
	}
	Plagger->context->log(info => "create index $dir");
    }

    #euc_jp to euc-jp
    $self->{encode} =~ s/_/-/;
    $self->{rast} = Rast->open($dir, RAST_DB_RDWR);
}

sub feed {
    my($self, $context, $args) = @_;
 
    my $rast = $self->{rast};
    return unless $rast;
    my $dir = $self->conf->{dir};

    my $feed = $args->{feed};
    for my $entry ($feed->entries) {
	next unless $entry->text;

	my $result = $rast->search('feedlink = ' . $feed->link . ' & permalink = ' . $entry->permalink, {
	    need_summary => 1,
	    properties => ['permalink']
	    });
	unless ($result) {
	    $context->error('search error ' . $entry->permalink);
	    return;
	}

	my $tags;
	my $time = eval { $entry->date->epoch } || time;
	my $options = [ 
			$feed->link, 
			$entry->permalink, 
			$self->convert($entry->title) || '', 
			$self->convert($entry->author) || '', 
			POSIX::strftime('%Y-%m-%dT%H:%M:%S', localtime($time)),
			$self->convert(join(' ', @{ $entry->tags }))
			];

	my $text = $self->convert($entry->text);
	unless ($result->hit_count) {
	    my $id = $rast->register($text, $options);
	    $context->log(info => "add new docid = $id: " . $entry->permalink);
	} elsif ($self->conf->{replace}) {
	    my $row = $result->fetch;
	    my $id = $rast->update($text, $options, $row->{doc_id});
	    $context->log(info => "replace: old docid = " . $row->{doc_id} . " to new docid = $id: " . $entry->permalink);
	}
    }
}

sub convert {
    my ($self, $str) = @_;
    $str = encode($self->{encode}, $str) unless $self->{encode} eq 'utf8';
    $str;
}

sub finalize {
    my($self, $context) = @_;
    return unless $self->{rast};
    $self->{rast}->close;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Search::Rast - Search Feed updates by Rast

=head1 SYNOPSIS

  - module: Search::Rast
    config:
      encode: euc_jp
      replace: 1
      dir: /home/yappo/plagger-rast

=head1 DESCRIPTION

This plugin can be indexed via Rast. please use the rast-search command to search.

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<http://projects.netlab.jp/rast/>, L<http://tech.yappo.jp/rast/>

=cut
