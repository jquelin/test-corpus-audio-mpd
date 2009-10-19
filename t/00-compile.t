#!perl

use Test::More tests => 1;

eval "use Test::Corpus::Audio::MPD";
SKIP: {
    skip "module is expected to fail under some circumstance", 1
        if $@ =~ /mpd not installed|installed mpd is not music player daemon|mpd is running/;
    is( $@, '', "module loads ok" );
}
