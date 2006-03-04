use inc::Module::Install;

name('Plagger');
all_from('lib/Plagger.pm');

requires('Class::Accessor::Fast' => 0);
requires('File::Find::Rule' => 0);
requires('UNIVERSAL::require' => 0);
requires('Template' => 0);
requires('Template::Provider::Encoding' => 0.04);
requires('YAML' => 0.39);
requires('Text::Tags' => 0);
requires('DateTime' => 0.29);
requires('DateTime::Format::Mail' => 0);
requires('DateTime::Format::W3CDTF' => 0);
requires('DateTime::Format::Strptime' => 0);
requires('Digest::MD5' => 0);
requires('LWP' => 0);
requires('HTML::Parser' => 3.40);
requires('URI::Fetch' => 0.04);

build_requires(Test::More => 0.42);

features(
    'Subscription::Bloglines' => [
        -default => 1,
        recommends('WebService::Bloglines', 0.10),
    ],
    'Subscription::OPML' => [
        -default => 1,
        recommends('XML::OPML'),
    ],
    'Aggregator::Simple' => [
        -default => 1,
        recommends('XML::Feed', 0.08),
        recommends('XML::Atom'),
        recommends('XML::RSS::LibXML', 0.16),
    ],
    'Publish::Gmail' => [
        -default => 1,
        recommends('MIME::Lite'),
    ],
    'Aggregator::Xango' => [
        -default => 0,
        recommends('POE'),
        recommends('Xango'),
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
    'Publish::IRC' => [
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
        recommends('XML::RSS::LibXML', 0.16),
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
);

if ($^O eq 'Darwin') {
    features(
        'Publish::Spotlight' => [
            -default => 1,
            recommends('Mac::Glue'),
        ],
    );
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
WriteAll;
