use inc::Module::Install;

name('Plagger');
all_from('lib/Plagger.pm');

requires('Class::Accessor::Fast' => 0);
requires('File::Find::Rule' => 0);
requires('UNIVERSAL::require' => 0);
requires('Template' => 0);
requires('Template::Provider::Encoding' => 0);
requires('YAML' => 0.39);
requires('Text::Tags' => 0);
requires('DateTime' => 0.29);
requires('DateTime::Format::Mail' => 0);
requires('DateTime::Format::W3CDTF' => 0);
requires('DateTime::Format::Strptime' => 0);
requires('Digest::MD5' => 0);
requires('LWP' => 0);

build_requires(Test::More => 0.42);

features(
    'Subscription::Bloglines' => [
        -default => 1,
        recommends('WebService::Bloglines', 0.06),
    ],
    'Subscription::OPML' => [
        -default => 1,
        recommends('XML::OPML', 0),
    ],
    'Aggregator::Simple' => [
        -default => 1,
        recommends('XML::Feed', 0),
    ],
    'Aggregator::Xango' => [
        -default => 1,
        recommends('POE', 0),
        recommends('Xango', 0),
        recommends('XML::Feed', 0),
        recommends('Cache::FastMmap', 0),
        recommends('HTTP::Component::Client::DNS', 0),
        recommends('HTTP::Component::Client::HTTP', 0),
    ],
    'Publish::Gmail' => [
        -default => 1,
        recommends('MIME::Lite', 0),
    ],
    'SmartFeed::Mixi' => [
        -default => 0,
        recommends('WWW::Mixi', 0),
    ],
);

auto_include;
auto_install;
WriteAll;
