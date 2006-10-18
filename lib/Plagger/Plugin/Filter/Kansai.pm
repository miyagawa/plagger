package Plagger::Plugin::Filter::Kansai;
use strict;
use base qw( Plagger::Plugin::Filter::Base );

use utf8;

sub filter {
    my($self, $text) = @_;

    my $n = 0;

    local $_ = $text;
    $n += s/なぜ(?:なんだ|でしょうか?|ですか?)/なんでやねん/g;
    $n += s/ありがとう(?:ございま(?:す|した))?/おおきに/g;
    $n += s/(の?)でしょう/($1?'ん':'').'やろ'/ge;
    $n += s/になられる/してくれはる/g;
    $n += s/([てで])(いる|います)/
	{'て'=>'と','で'=>'ど'}->{$1}.
	{'いる'=>'る','います'=>'ります'}->{$2}/ge;
    $n += s/(?<=まし)た\b/てん/g;
    $n += s/りますが/るけど/g;
    $n += s/いです([よがね])/
    {'よ'=>'いでっしゃろ','が'=>'いねんけど','ね'=>'いわな'}->{$1}/ge;
    $n += s/((い)?[のん])?(?:だ|です)([よがとね])/
	($2 ? 'いねん' : $1 ? 'んや' : 'や').
	    {'よ'=>'で','が'=>'けど','と'=>'と','ね'=>'な'}->{$3}/ge;
    $n += s/(?<=[^幸][いた])です\b/で/g;
    $n += s/(?:です|である)\b/や/g;
    $n += s/しない(で)/'せえへん'.($1?'といて':'')/ge;
    $n += s/てください/とくんなはれ/g;
    $n += s/てしまう/てまう/g;
    $n += s/ていません/てまへん/g;
    $n += s/ございません/ありまへん/g;
    $n += s/すみません/すんまへん/g;
    $n += s/すいません/すんまへん/g;
    $n += s/(いけ?)?ません/
    {'い'=>'おり','いけ'=>'あき',''=>''}->{$1}.'まへん'/ge;
    $n += s/(?<=[てで])いない/ない/g;
    $n += s/(?<=もう|しか)ない/あらへん/g;
    $n += s/(?<=[が、])ない/あらへん/g;
    $n += s/(?<!で)はない/はあらへん/g;
    $n += s/(?<=[かさなまらわきちりえけせてねめれ])ない/へん/g;
    $n += s/だ(?=と|った|けど)/や/g;
    $n += s/いる/おる/g;
    $n += s/いない/おらん/g;
    $n += s/いい(?=です|こと|[なのよ]|\b)/ええ/g;
    $n += s/という/ちゅう/g;
    $n += s/なぜ(?=[だでな])/なんで/g;
    $n += s/(<?=[なた])んだ/んや/g;
    $n += s/いただいて/もろうて/g;
    $n += s/[私俺]は/わしは/g;
    $n += s/よろしく/よろしゅう/g;
    $n += s/あなた/あんた/g;
    $n += s/だろう/やろ/g;
    $n += s/かな？/かいな？/g;
    $n += s/ってる/っとる/g;
    $n += s/んでる/んどる/g;

    return ($n, $_);
}

1;
__END__

=for stopwords Mishima-san Kansai Kansai-ben Kansai.pm

=head1 NAME

Plagger::Plugin::Filter::Kansai - Filer text to Kansai-ben

=head1 SYNOPSIS

  - module: Filter::Kansai

=head1 DESCRIPTION

This plugin filters entry body to Kansai dialect.

=head1 AUTHOR

Tatsuhiko Miyagawa

Kansai.pm is originally written by Mishima-san.

=head1 SEE ALSO

L<Plagger>, L<http://kansai.pm.org/Kansai.pm/src/Kansai.pm>

=cut
