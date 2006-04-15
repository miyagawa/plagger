package Plagger::Plugin::Filter::StripRSSAd;
use strict;
use base qw( Plagger::Plugin );

use DirHandle;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    Plagger->context->autoload_plugin('Filter::BloglinesContentNormalize');
    $self->load_patterns();
}

sub load_patterns {
    my $self = shift;

    my $dir = $self->assets_dir;
    my $dh = DirHandle->new($dir) or Plagger->context->error("$dir: $!");
    for my $file (grep -f $_->[0] && $_->[1] =~ /^[\w\-]+$/,
                  map [ File::Spec->catfile($dir, $_), $_ ], sort $dh->read) {
        $self->load_pattern(@$file);
    }
}

sub load_pattern {
    my($self, $file, $base) = @_;

    Plagger->context->log(debug => "loading $file");

    open my $fh, $file or Plagger->context->error("$file: $!");
    my $re = join '', <$fh>;
    chomp($re);

    push @{$self->{pattern}}, { site => $base, re => qr/$re/ };
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
    my $body = $self->filter($args->{entry}->body, $args->{entry}->link);
    $args->{entry}->body($body);
}

sub filter {
    my($self, $body, $link) = @_;

    for my $pattern (@{ $self->{pattern} }) {
        my $re = $pattern->{re};
        if (my $count = $body =~ s!$re!defined($1) ? $1 : ''!egs) {
            Plagger->context->log(debug => "Stripped $pattern->{site} Ad on $link");
        }
    }

    $body;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::StripRSSAd - Strip RSS Ads from feed content

=head1 SYNOPSIS

  - module: Filter::StripRSSAd

=head1 DESCRIPTION

This plugin strips RSS context based ads from feed content, like
Google AdSense or rssad.jp. It uses quick regular expression to strip
the images and map tags.

=head1 AUTHOR

Tatsuhiko Miyagawa, Masahiro Nagano

=head1 SEE ALSO

L<Plagger>

=cut
