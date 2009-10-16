use strict;
use warnings;

package Test::Corpus::Audio::MPD;
# ABSTRACT: automate launching of fake mdp for testing purposes

use File::Basename        qw{ fileparse };
use File::Spec::Functions qw{ catdir catfile };
use Module::Util          qw{ find_installed };
use Readonly;

use base qw{ Exporter };
our @EXPORT = qw{ };

Readonly my $SHAREDIR => _find_share_dir();

# -- private subs

#
# my $path = _find_share_dir();
#
# return the absolute path where all resources will be placed.
#
sub _find_share_dir {
    my $path = find_installed(__PACKAGE__);
    my ($undef, $dirname) = fileparse($path);
    return catdir($dirname, 'MPD', 'share');
}


#
# my $was_running = _stop_user_mpd_if_needed()
#
# This sub will check if mpd is currently running. If it is, force it to
# a full stop (unless MPD_TEST_OVERRIDE is not set).
#
# In any case, it will return a boolean stating whether mpd was running
# before forcing stop.
#
sub _stop_user_mpd_if_needed {
    # check if mpd is running.
    my $is_running = grep { /\s+mpd$/ } qx{ ps -e };

    return 0 unless $is_running; # mpd does not run - nothing to do.

    # check force stop.
    die "mpd is running\n" unless $ENV{MPD_TEST_OVERRIDE};
    system( 'mpd --kill 2>/dev/null') == 0 or die "can't stop user mpd: $?\n";
    sleep 1;  # wait 1 second to free output device
    return 1;
}


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

