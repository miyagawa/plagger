package Plagger::Crypt::Base64;
use strict;
use MIME::Base64 ();

sub id { 'base64' }

sub decrypt {
    my($self, $text) = @_;
    MIME::Base64::decode($text);
}

sub encrypt {
    my($self, $text) = @_;
    MIME::Base64::encode($text, '');
}

1;

