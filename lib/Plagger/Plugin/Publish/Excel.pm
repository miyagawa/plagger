package Plagger::Plugin::Publish::Excel;
use strict;
use warnings;
use base qw(Plagger::Plugin);

use Spreadsheet::WriteExcel;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    Plagger->context->error("filename is missing")
        unless exists $self->conf->{filename};
}

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.init' => \&initialize,
        'publish.feed' => \&feed,
    );
}

sub initialize {
    my ($self, $context) = @_;
    my $workbook = Spreadsheet::WriteExcel->new($self->conf->{filename});
    $self->{workbook} = $workbook;
    $self->{body_format} = $workbook->add_format(text_wrap => 1);
}

sub feed {
    my ($self, $context, $args) = @_;
    my $feed = $args->{feed};
    my $worksheet = $self->{workbook}->add_worksheet(escape_sheet_name($feed->title));
    my $row = 0;
    for my $entry ($feed->entries) {
        my $col = 0;
        $worksheet->write($row, $col++, $entry->date->format('Mail'));
        $worksheet->write($row, $col++, $entry->title);
        $worksheet->write($row, $col++, $entry->permalink);
        $worksheet->write($row, $col++, $entry->body->plaintext, $self->{body_format});
        $row++;
    }
}

sub escape_sheet_name {
    my $name = shift;
    $name =~ s![\[\]:*?/\\]! !g;
    $name = substr $name, 0, 31 if length $name > 31;
    $name;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::Excel - Publish feeds as Excel workbook

=head1 SYNOPSIS

  - module: Publish::Excel
    config:
      filename: /path/to/workbook.xls

=head1 DESCRIPTION

This plugin creates Excel workbook.

=head1 AUTHOR

Jiro Nishiguchi

=head1 SEE ALSO

L<Plagger>, L<Spreadsheet::WriteExcel>

=cut
