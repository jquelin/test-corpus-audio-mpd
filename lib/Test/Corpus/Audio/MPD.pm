use strict;
use warnings;

package Test::Corpus::Audio::MPD;
# ABSTRACT: automate launching of fake mdp for testing purposes

use base qw{ Exporter };
our @EXPORT = qw{ };

1;
__END__

=head1 SYNOPSIS

    use Test::Corpus::Audio::MPD; # die if error
    [...]

=head1 DESCRIPTION

This module will try to launch a new mpd server for testing purposes.
This mpd server will then be used during L<POE::Component::Client::MPD>
or L<Audio::MPD> tests.

In order to achieve this, the module will create a fake F<mpd.conf> file
with the correct pathes (ie, where you untarred the module tarball). It
will then check if some mpd server is already running, and stop it if
the C<MPD_TEST_OVERRIDE> environment variable is true (die otherwise).
Last it will run the test mpd with its newly created configuration file.

Everything described above is done automatically when the module
is C<use>-d.

Once the tests are run, the mpd server will be shut down, and the
original one will be relaunched (if there was one).

Note that the test mpd will listen to C<localhost>, so you are on the safe
side. Note also that the test suite comes with its own ogg files - and yes,
we can redistribute them since it's only some random voice recordings :-)

In case you want more control on the test mpd server, you can use the
supplied public methods. This might be useful when trying to test
connections with mpd server.

