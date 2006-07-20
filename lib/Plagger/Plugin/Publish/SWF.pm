package Plagger::Plugin::Publish::SWF;

use strict;
use base qw(Plagger::Plugin);
use File::Spec;
use SWF::Builder;
use Jcode;


sub register{
    my ($self,$context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed{
    my ($self,$context,$args) = @_;
    my $dir = $self->conf->{dir} || 'swf';
    unless (-e $dir && -d _) {
        mkdir $dir, 0755 or $context->error("mkdir $dir: $!");
    }
    my $file = File::Spec->catfile($dir, $args->{feed}->id . ".swf");
    my $id = $args->{feed}->id;
    unless($self->conf->{font}){
         $context->error("Error font file  $!");
    }
    my $movie = $self->create_stage($context,$args);
    $movie->save($file);
    return;
}

sub convert{
    my ($self, $str) = @_;
    utf8::decode($str) unless utf8::is_utf8($str);
    return $str;
}

sub create_stage{
    my ($self,$context,$args) = @_;
    my $bgcolor = $self->conf->{bgcolor} || 'ffffff';
    my $width = $self->conf->{width} || 500;
    my $height = $self->conf->{height} || 500;
    my $movie = SWF::Builder->new (
          FrameRate => 12,
          FrameSize => [0, 0,$width,$height],
          BackgroundColor => $bgcolor
    );

    $movie->frame_action(1)->compile( <<AS_END );
        this.page=0;
        nextPage();
        _root.pre_mc._visible=false;
        function nextPage(){
            var title_name = 'title_text' + this.page.toString();
            var entry_name = 'entry_text' + this.page.toString();
            this[title_name].onEnterFrame=function(){}
            this[title_name]._alpha=0;
            this[title_name]._visible=false;
            this[entry_name].onEnterFrame=function(){}
            this[entry_name]._alpha=0;
            this[entry_name]._visible=false;

            this.page++;
            entry_name = 'entry_text' + this.page.toString();
            title_name = 'title_text' + this.page.toString();
            if(!this[entry_name]){
            this.page=1;
                entry_name = 'entry_text' + this.page.toString();
            title_name = 'title_text' + this.page.toString();
            }
            this[entry_name].onEnterFrame=function(){
                this._alpha+=6;
                this._visible=true;
            }
            this[title_name].onEnterFrame=function(){
                this._alpha+=6;
                this._visible=true;
            }
         }
AS_END

    my $new_mc = $movie->new_movie_clip;
    my $shape = $new_mc->new_shape;
    $shape->fillstyle($bgcolor);
    $shape->lineto(0,0)->lineto(0,$height)->lineto($width,$height)->lineto($width,0)->lineto(0,0);
    $shape->place;
    my $new_mc_ins = $new_mc->place;
    $new_mc_ins->on('Press')->compile('_root.nextPage();');

    my $new_pre_mc = $movie->new_movie_clip;
    my $pre_shape = $new_pre_mc->new_shape;
    my $color = $self->conf->{color} || '000000';
    $pre_shape->fillstyle($color);
    $pre_shape->lineto(0,0)->lineto(0,$height)->lineto($width,$height)->lineto($width,0)->lineto(0,0);
    $pre_shape->place;
    $new_pre_mc->place->name('pre_mc');

    my $page=0;
    for my $entry ($args->{feed}->entries) {
        $page++;
        $self->create_page($movie,$page,$entry->title,$entry->body);
    }

    $movie;
}

sub create_page(){
    my ($self,$movie,$page,$title,$body) = @_;
    my $font = $self->conf->{font};
    my $color = $self->conf->{color} || '000000';
    my $title_size = $self->conf->{title_size} || 32;
    my $body_size = $self->conf->{body_size} || 24;

    $title = $self->convert($title);

    $body =~ s/<.+?>//g;
    $body = $self->linefeed($body);
    $body = $self->convert($body);

    my $entry_name = 'entry_text'.$page;
    my $title_name = 'title_text'.$page;
    $font = $movie->new_font($font);

    my $title_text_mc = $movie->new_movie_clip;
    my $title_ins = $title_text_mc->new_static_text($font);
    $title_ins->size($title_size)->color($color)->text($title)->place;
    my $title_text_ins = $title_text_mc->place;
    $title_text_ins->on('Load')->compile('this._visible=false;this._alpha=0;');
    $title_text_ins->name($title_name);
    $title_text_ins->moveto(10,10);

    my $entry_text_mc = $movie->new_movie_clip;
    my $entry_ins = $entry_text_mc->new_static_text($font);
    $entry_ins->size($body_size)->color($color)->text($body)->place;
    my $entry_text_ins = $entry_text_mc->place;
    $entry_text_ins->name($entry_name);
    $entry_text_ins->on('Initialize')->compile('this._visible=false;this._alpha=0;');
    $entry_text_ins->moveto(10,50);
}

sub linefeed{
    my ($self,$str,$n)=@_;
    my $linefeed = $self->conf->{linefeed} || 30;
    my @line = split "\n",$str;
    my $line;
    for my $l (@line){
        my @l = Jcode->new($l)->jfold($linefeed);
        $line .= join "\n",@l;
        $line .= "\n";
    }
    $line;
}

1;


__END__

=head1 NAME

Plagger::Plugin::Publish::SWF - Publish feeds as SWF

=head1 SYNOPSIS

- module: Publish::SWF
   config:
     dir: swf
     font: HONYA-JI.ttf
     color: ff0084
     width: 500
     height: 500
     linefeed: 30
     bgcolor: ffffff
     title_size: 32
     body_size: 24

=head1 DESCRIPTION

This plugin creates SWF files which you can be view with Flash Player.

=head1 EXAMPLE

L<http://d.hatena.ne.jp/t-akihito/20060605/ >

=head1 AUTHOR

Akihito Takeda

=head1 SEE ALSO

L<Plagger>, L<SWF::Builder>

=cut
