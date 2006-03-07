use inc::Module::Install;

name('Plagger');
all_from('lib/Plagger.pm');

requires('Class::Accessor::Fast');
requires('File::Find::Rule');
requires('UNIVERSAL::require');
requires('Template');
requires('Template::Provider::Encoding' => 0.04);
requires('YAML' => 0.39);
requires('Text::Tags');
requires('DateTime' => 0.29);
requires('DateTime::Format::Mail');
requires('DateTime::Format::W3CDTF');
requires('DateTime::Format::Strptime');
requires('Digest::MD5');
requires('LWP');
requires('HTML::Parser' => 3.40);
requires('URI::Fetch' => 0.05);
requires('Cache::Cache' => 1.04);

build_requires(Test::More => 0.42);

features(
    'POD Testing' => [
        -default => 0,
        recommends('Test::Pod'),
        recommends('Test::Pod::Coverage'),
    ],
    'Subscription::Bloglines' => [
        -default => 1,
        recommends('WebService::Bloglines', 0.11),
        recommends('XML::Liberal', 0.06),
    ],
    'Subscription::OPML' => [
        -default => 1,
        recommends('XML::OPML'),
    ],
    'Aggregator::Simple' => [
        -default => 1,
        recommends('XML::Feed', 0.08),
        recommends('XML::Atom'),
        recommends('XML::RSS::LibXML', 0.18),
        recommends('XML::RSS::Liberal'),
    ],
    'Publish::Gmail' => [
        -default => 1,
        recommends('MIME::Lite'),
    ],
    'Aggregator::Xango' => [
        -default => 0,
        recommends('POE'),
        recommends('Xango', 1.02), # avoid prep_request bug
        recommends('XML::Feed', 0.08),
        recommends('Cache::FastMmap'),
        recommends('POE::Component::Client::DNS'),
        recommends('POE::Component::Client::HTTP'),
    ],
    'SmartFeed::Mixi' => [
        -default => 0,
        recommends('WWW::Mixi'),
    ],
    'Publish::PDF' => [
        -default => 0,
        recommends('PDF::FromHTML'),
    ],
    'Publish::Delicious' => [
        -default => 0,
        recommends('Net::Delicious'),
    ],
    'Notify::IRC' => [
        -default => 0,
        recommends('POE::Component::IRC'),
        recommends('POE::Component::IKC::Client'),
    ],
    'Filter::URLBL' => [
        -default => 0,
        recommends('Net::DNS'),
    ],
    'Publish::JavaScript' => [
        -default => 0,
        recommends('Template::Plugin::JavaScript'),
    ],
    'Subscription::HatenaRSS' => [
        -default => 0,
        recommends('WWW::Mechanize'),
    ],
    'Filter::HatenaBookmarkUsersCount' => [
        -default => 0,
        recommends('XMLRPC::Lite'),
    ],
    'Filter::HatenaDiaryKeywordLink' => [
        -default => 0,
        recommends('XMLRPC::Lite'),
    ],
    'Publish::Feed' => [
        -default => 1,
        recommends('XML::Feed', 0.08),
        recommends('XML::RSS::LibXML', 0.18),
    ],
    'Filter::ResolveRelativeLink' => [
        -default => 0,
        recommends('HTML::ResolveLink', 0.02),
    ],
    'Filter::BulkfeedsTerms' => [
        -default => 0,
        recommends('XML::Simple'),
    ],
    'Publish::HatenaBookmark' => [
        -default => 0,
        recommends('XML::Atom'),
    ],
    'Publish::Playlog' => [
        -default => 0,
        recommends('XML::Atom', 0.13),
    ],
    'Publish::Planet' => [
        -default => 0,
        recommends('HTML::Tidy'),
        recommends('HTML::Scrubber'),
    ],
    'Publish::CSV' => [
        -default => 0,
        recommends('Text::CSV_PP'),
    ],
    'Filter::HatenaFormat' => [
        -default => 0,
        recommends('Text::Hatena'),
    ],
    'Publish::MT' => [
        -default => 0,
        recommends('Net::MovableType'),
    ],
    'CustomFeed::FlickrSearch' => [
        -default => 0,
        recommends('XML::LibXML'),
        recommends('Flickr::API'),
        recommends('DateTime::Format::Epoch'),
    ],
    'Filter::ImageInfo' => [
        -default => 0,
        recommends('Image::Info'),
    ],
    'Filter::Pipe' => [
        -default => 0,
        recommends('IPC::Run'),
    ],
    'Filter::RSSLiberalDateTime' => [
        -default => 0,
        recommends('Date::Parse'),
    ],
);

if ($^O eq 'Darwin') {
    features(
        'Publish::Spotlight' => [
            -default => 1,
            recommends('Mac::Glue'),
        ],
    );

install_script('bin/spotlight_comment.scpt');

} elsif ($^O eq 'MSWin32') {
    features(
        'Publish::Speech' => [
            -default => 0,
            recommends('Win32::OLE'),
            recommends('Win32::SAPI4'),
            recommends('Locale::Country'),
            recommends('Locale::Language'),
        ],
        'Notify::Eject' => [
            -default => 0,
            recommends('Win32::MCI::Basic'),
        ],
    );
}

auto_include;
auto_install;
install_script('plagger');
install_script('bin/plagger-ircbot');
WriteAll;
