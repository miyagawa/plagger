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

    if ( my $match = $args->{feed}->meta->{follow_link} || $args->{feed}->meta->{follow_xpath} ) {
        $args->{match} = $match;
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

    my $re = $args->{match};

    if( $args->{feed}->meta->{follow_link} ) {
        my $resolver = HTML::ResolveLink->new(base => $url);
        $content = $resolver->resolve($content);

        my %seen;
        my $parser = HTML::TokeParser->new(\$content);
        while (my $token = $parser->get_tag('a')) {
            next unless ($token->[1]->{href} || '') =~ /$re/;

            my $text = $parser->get_trimmed_text('/a');
            next if !$text || $text eq '[IMG]';

            my $url = URI->new_abs($token->[1]->{href}, $url);
            next if $seen{$url->as_string}++;

            my $entry = Plagger::Entry->new;
            $entry->title($text);
            $entry->link($url);
            $feed->add_entry($entry);

            $context->log(debug => "Add $token->[1]->{href} ($text)");
        }
    }
    else {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($content);
        $tree->eof;

        for my $child ( $tree->findnodes($re || '//a') ) {
            my $href  = $child->attr('href') or next;
            my $title = $child->attr('title') || $child->as_text;

            my $entry = Plagger::Entry->new;
            $entry->title($title);
            $entry->link($href);
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
