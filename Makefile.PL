use inc::Module::Install;

name('Plagger');
all_from('lib/Plagger.pm');

requires('Class::Accessor::Fast');
requires('File::Find::Rule');
requires('UNIVERSAL::require' => 0.10);
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
requires('HTML::Parser' => 3.48);
requires('URI::Fetch' => 0.06);
requires('Cache::Cache' => 1.04);
requires('Module::Pluggable::Fast');
requires('HTML::ResolveLink');
requires('Date::Parse');
requires('MIME::Types', 1.16);

requires('XML::Feed', 0.08);
requires('XML::LibXML');
requires('XML::Atom', 0.19);
requires('XML::RSS::LibXML', 0.20),

build_requires(Test::More => 0.42);

features(
    'Better Encoding detection' => [
        -default => 1,
        recommends('Encode::Detect'),
    ],
    'POD Testing' => [
        -default => 0,
        recommends('Test::Pod'),
        recommends('Test::Pod::Coverage'),
    ],
    'Cookie sharing with Firefox' => [
        -default => 0,
        recommends('HTTP::Cookies::Mozilla'),
    ],
    'Liberal XML parsing' => [
        -default => 1,
        recommends('XML::Liberal', 0.11),
        recommends('XML::RSS::Liberal'),
    ],
);

features(
    'Subscription::Bloglines' => [
        -default => 1,
        recommends('WebService::Bloglines', 0.11),
    ],
    'Subscription::OPML' => [
        -default => 1,
        recommends('XML::OPML'),
    ],
    'Publish::Gmail' => [
        -default => 1,
        recommends('Mail::Address'),
        recommends('MIME::Lite'),
        recommends('Net::SMTP::TLS'),
    ],
    'Aggregator::Xango' => [
        -default => 0,
        recommends('POE'),
        recommends('Xango', 1.04), # protect ourselves from my stupidity
        recommends('Cache::FastMmap'),
        recommends('POE::Component::Client::DNS'),
        recommends('POE::Component::Client::HTTP'),
    ],
    'CustomFeed::Mixi' => [
        -default => 0,
        recommends('WWW::Mixi', 0.46),
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
    'Filter::ResolveRelativeLink' => [
        -default => 0,
        recommends('HTML::ResolveLink', 0.02),
    ],
    'Publish::Planet' => [
        -default => 0,
        recommends('HTML::Tidy'),
        recommends('HTML::Scrubber'),
        recommends('File::Copy::Recursive'),
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
    'Filter::Emoticon' => [
        -default => 0,
        recommends('Text::Emoticon'),
    ],
    'Publish::Maildir' => [
        -default => 0,
        recommends('MIME::Lite'),
    ],
    'Publish::IMAP' => [
        -default => 0,
        recommends('Mail::IMAPClient'),
    ],
    'Filter::Profanity' => [
	-default => 0,
	recommends('Regexp::Common::profanity_us'),
    ],
    'Subscription::DBI' => [
	-default => 0,
	recommends('DBIx::Class::Schema'),
    ],
    'CustomFeed::SVNLog' => [
	-default => 0,
	recommends('SVN::Core'),
	recommends('SVN::Client'),
    ],
    'Filter::TTP' => [
	-default => 0,
	recommends('URI::Find'),
    ],
    'Filter::Romanize' => [
        -default => 0,
        recommends('Text::Kakasi'),
    ],
    'Rule::URLBL' => [
        -default => 0,
        recommends('Net::DNS'),
    ],
    'Subscription::LivedoorReader' => [
        -default => 0,
        recommends('JSON::Syck', 0.10),
        recommends('WWW::Mechanize'),
    ],
    'Search::Estraier' => [
        -default => 0,
        recommends('Search::Estraier'),
    ],
    'Subscription::XOXO' => [
        -default => 0,
        recommends('HTML::TreeBuilder::XPath'),
    ],
    'Publish::2chdat' => [
        -default => 0,
        recommends('DateTime::Locale'),
    ],
    'Subscription::PlanetINI' => [
        -default => 0,
        recommends('Config::INI::Simple'),
    ],
    'Notify::UpdatePing' => [
        -default => 0,
        recommends('XMLRPC::Lite'),
    ],
    'Publish::PalmDoc' => [
        -default => 0,
        recommends('Palm::PalmDoc'),
    ],
    'Subscription::FOAF' => [
        -default => 0,
        recommends('XML::FOAF'),
    ],
    'Notify::Beep' => [
        -default => 0,
        recommends('Audio::Beep'),
    ],
);

if ($^O eq 'darwin') {
    features(
        'Cookie sharing with Safari' => [
            -default => 0,
            recommends('HTTP::Cookies::Safari'),
        ],
        'Search::Spotlight' => [
            -default => 1,
            recommends('Mac::Glue'),
        ],
        'Publish::Speech' => [
            -default => 0,
            recommends('Mac::Speech'),
        ],
    );

    install_script('bin/spotlight_comment.scpt');

} elsif ($^O eq 'MSWin32') {
    features(
        'Cookie sharing with MSIE' => [
            -default => 0,
            recommends('HTTP::Cookies::Microsoft'),
        ],
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

tests 't/*.t t/*/*.t t/*/*/*.t';

auto_include;
auto_install;
install_script('plagger');
install_script('bin/plagger-ircbot');
WriteAll;
