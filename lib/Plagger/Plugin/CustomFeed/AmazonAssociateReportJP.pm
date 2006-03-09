package Plagger::Plugin::CustomFeed::AmazonAssociateReportJP;
use strict;
use warnings;
use base qw (Plagger::Plugin);

use WWW::Mechanize;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.amazonassociate' => \&aggregate,
    );
}

sub load {
    my ($self, $context) = @_;
    my $feed = Plagger::Feed->new;
    $feed->type('amazonassociate');
    $context->subscription->add($feed);
}

sub aggregate {
    my ($self, $context, $args) = @_;
    my $mech = join('::', __PACKAGE__, "Mechanize")->new($self);
    $mech->login or $context->error('login failed');

    my $feed = Plagger::Feed->new;
    $feed->type('amazonassociate');
    $feed->title('Amazon.co.jp アソシエイト・レポート');
    $feed->link('https://associates.amazon.co.jp/gp/associates/network/reports/main.html');

    my $summary_entry = Plagger::Entry->new;
    $summary_entry->title('現四半期レポート');
    $summary_entry->link('https://associates.amazon.co.jp/gp/associates/network/reports/report.html');
    $summary_entry->date( Plagger::Date->now() );
    $summary_entry->body($mech->summary_html);
    $feed->add_entry($summary_entry);

    my $earnings_entry = Plagger::Entry->new;
    $earnings_entry->title('売上レポート');
    $earnings_entry->link('https://associates.amazon.co.jp/gp/associates/network/reports/report.html');
    $earnings_entry->date( Plagger::Date->now() );
    $earnings_entry->body( $mech->earnings_html);
    $feed->add_entry($earnings_entry);

    $context->update->add($feed);
}

package Plagger::Plugin::CustomFeed::AmazonAssociateReportJP::Mechanize;
use strict;
use warnings;
use WWW::Mechanize;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(mech email password start_url));

sub new {
    my $class = shift;
    my $plugin = shift;
    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( "Windows IE 6" );
    return bless {
	mech     => $mech,
	email    => $plugin->conf->{email},
	password => $plugin->conf->{password},
        start_url => 'http://www.amazon.co.jp/',
    }, $class;
}

sub login {
    my $self = shift;
    my $mech = $self->mech;
    my $res = $mech->get($self->start_url);
    return unless $mech->success;
    $mech->follow_link(url_regex => qr!associates/join/main\.html!);
    $mech->follow_link(url_regex => qr!associates/login/login\.html!);
    $mech->form_number(1);
    $mech->field(email => $self->email);
    $mech->field(password => $self->password);
    $mech->click;
    return if ($mech->content =~ m!<input name="email" type="text"!); # oops, login failed!
    return 1;
}

sub summary_html {
    my $self = shift;
    if ($self->mech->content =~ m!(<table class="report" id="earningsSummary">.*?</table>)!is) {
        my $html = $1;
        $html =~ s!<a [^>]+>.+?</a>!!isg;
        $html =~ s!<img [^>]+/>!!isg;
        return $html;
    }
}

sub earnings_html {
    my $self = shift;
    my $html;
    $self->mech->follow_link(url_regex => qr/report\.html.*?earningsReport/);
    my $content = $self->mech->content;
    if ($content =~ m!(<table class="report" id="earningsReport">.*?</table>)!is) {
        $html = $1;
    }
    if ($content =~ m!(<table class="earningsReportSummary">.*?</table>)!is) {
        $html .= $1;
    }
    return $html;
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::AmazonAssociateReportJP - Custom feed for
Amazon.co.jp associate central

=head1 SYNOPSIS

  - module: CustomFeed::AmazonAssociateReportJP
    config:
      email: foobar@example.com
      password: barbaz

=head1 DESCRIPTION

This plugin fetches your report for Amazon affiliate.

=head1 CONFIGRATION

=over 4

=item email, password

Credential you need to login to Amazon.co.jp associate central.

=back

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>, L<WWW::Mechanize>

=cut
