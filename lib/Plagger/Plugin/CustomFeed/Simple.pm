package Plagger::Plugin::CustomFeed::Simple;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use HTML::TokeParser;
use HTML::ResolveLink;
use HTML::TreeBuilder::XPath;
use Plagger::UserAgent;
use Plagger::Util qw( decode_content extract_title );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    $args->{match} = $args->{feed}->meta->{follow_link};
    $args->{xpath} = $args->{feed}->meta->{follow_xpath};
    if ($args->{match} || $args->{xpath}) {
        return $self->aggregate($context, $args);
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res = $agent->fetch($url, $self);

    if ($res->http_response->is_error) {
        $context->log(error => "GET $url failed: " . $res->status);
        return;
    }

    my $content = decode_content($res);
    my $title   = extract_title($content);

    my $feed = Plagger::Feed->new;
    $feed->title($title);
    $feed->link($url);

    if( my $re = $args->{match} ) {
        my $resolver = HTML::ResolveLink->new(base => $url);
        $content = $resolver->resolve($content);

        my %seen;
        my $parser = HTML::TokeParser->new(\$content);
        while (my $token = $parser->get_tag('a')) {
            next unless ($token->[1]->{href} || '') =~ /$re/;

            my $text = $parser->get_trimmed_text('/a');
            next if !$text || $text eq '[IMG]';

            my $item_url = URI->new_abs($token->[1]->{href}, $url);
            next if $seen{$item_url->as_string}++;

            my $entry = Plagger::Entry->new;
            $entry->title($text);
            $entry->link($item_url);
            $feed->add_entry($entry);

            $context->log(debug => "Add $token->[1]->{href} ($text)");
        }
    } elsif (my $xpath = $args->{xpath}) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($content);
        $tree->eof;

        for my $child ( $tree->findnodes($xpath || '//a') ) {
            my $href  = $child->attr('href') or next;
            my $title = $child->attr('title') || $child->as_text;

            my $entry = Plagger::Entry->new;
            $entry->title($title);
            $entry->link(URI->new_abs($href, $url));
            $feed->add_entry($entry);

            $context->log(debug => "Add $href ($title)");
        }
    }

    $context->update->add($feed);

    return 1;
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Simple - Simple way to create title and link only custom feeds

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - url: http://sportsnavi.yahoo.co.jp/index.html
          meta:
            follow_link: /headlines/
        - url: http://d.hatena.ne.jp/antipop/20050628/1119966355
          meta:
            follow_xpath: //ul[@class="xoxo" or @class="subscriptionlist"]//a

  - module: CustomFeed::Simple

=head1 DESCRIPTION


=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut



1;
