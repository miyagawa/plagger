package Plagger::Plugin::Subscription::DBI;
use strict;
use base qw( Plagger::Plugin Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/schema/);

sub register {
    my ( $self, $context ) = @_;

    unless ( $self->conf->{schema_class} and $self->conf->{connect_info} ) {
        $context->error('schema_class and connect_info are required');
    }

    $self->conf->{schema_class}->require
        or $context->error(
        qq/Can't load schema class "@{[ $self->conf->{schema_class} ]}", $!/);

    $self->schema( $self->conf->{schema_class}
            ->connect( @{ $self->conf->{connect_info} } ) );

    $context->register_hook( $self, 'subscription.load' => \&load, );
}

sub load {
    my ( $self, $context ) = @_;

    my $rs = $self->schema->resultset('Feed')->search();

    while ( my $rs_feed = $rs->next ) {
        my $feed = Plagger::Feed->new;
        $feed->url( $rs_feed->url ) or $context->error("Feed URL is missing");
        $feed->link( $rs_feed->link )   if $rs_feed->link;
        $feed->title( $rs_feed->title ) if $rs_feed->title;

        my $rs_tag = $self->schema->resultset('Tag')->search(
            { 'feed_tag_map.feed' => $rs_feed->id },
            { join                => [qw/feed_tag_map/], }
        );
        while ( my $tag = $rs_tag->next ) {
            $feed->tags( [ $tag->name ] );
        }

        $context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::DBI - Subscription in database

=head1 SYNOPSIS

    - module: Subscription::DBI
      config:
        schema_class: 'My::Schema'
        connect_info: ['dbi:SQLite:/path/to/plagger.db']

=head1 DESCRIPTION

This plugin allows you to configure your subscription in
a database.

You will need the following:

=head2 SQL

    CREATE TABLE feed (
        id INTEGER NOT NULL PRIMARY KEY,
        url TEXT,
        link TEXT,
        title TEXT
    );
    
    CREATE TABLE tag (
        id INTEGER NOT NULL PRIMARY KEY,
        name TEXT NOT NULL
    );
    
    CREATE TABLE feed_tag_map (
        feed INTEGER NOT NULL,
        tag INTEGER NOT NULL,
        PRIMARY KEY (feed, tag)
    );

and the following DBIx::Class::Schema

=head2 My::Schema

    package My::Schema;
    use strict;
    use warnings;
    use base qw/DBIx::Class::Schema/;
    
    __PACKAGE__->load_classes();
    
    1;

=head2 My::Schema::Feed

    package My::Schema::Feed;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components(qw/Core/);
    
    __PACKAGE__->table('feed');
    __PACKAGE__->add_columns(qw(
            id
            url
            link
            title
    ));
    __PACKAGE__->set_primary_key(qw/id/);
    
    1;

=head2 My::Schema::FeedTagMap

    package My::Schema::FeedTagMap;
    
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components(qw/Core/);
    
    __PACKAGE__->table('feed_tag_map');
    __PACKAGE__->add_columns(qw(
            feed
            tag
    ));
    
    __PACKAGE__->set_primary_key(qw/feed tag/);
    
    __PACKAGE__->belongs_to( feed => 'TEST::Schema::Feed' );
    __PACKAGE__->belongs_to( tag  => 'TEST::Schema::Tag' );
    
    1;

=head2 My::Schema::Tag

    package TEST::Schema::Tag;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components(qw/Core/);
    
    __PACKAGE__->table('tag');
    __PACKAGE__->add_columns(qw(
            id
            name
    ));
    __PACKAGE__->set_primary_key(qw/id/);
    
    __PACKAGE__->has_many( feed_tag_map => 'TEST::Schema::FeedTagMap', 'tag' );
    __PACKAGE__->many_to_many( feeds => feed_tag_map => 'feed' );
    
    1;

=head1 AUTHOR

Franck Cuny

Based on the plugin Plagger::Plugin::Subscription::Config by Tatsuhiko Miyagawa

The schema is inspired by the work of Daisuke Murase for Plagger::Plugin::Store::DBIC

=head1 SEE ALSO

L<Plagger>

=cut
