use strict;
use warnings;

package Test::Corpus::Audio::MPD;
# ABSTRACT: automate launching of fake mdp for testing purposes

use File::Basename        qw{ fileparse };
use File::Spec::Functions qw{ catdir catfile };
use File::Temp            qw{ tempdir };
use Module::Util          qw{ find_installed };
use Readonly;

use base qw{ Exporter };
our @EXPORT = qw{
    customize_test_mpd_configuration
    start_test_mpd stop_test_mpd
};

Readonly my $SHAREDIR => _find_share_dir();
Readonly my $TEMPLATE => "$SHAREDIR/mpd.conf.template";
Readonly my $TMPDIR   => tempdir( CLEANUP=>1 );
Readonly my $CONFIG   => catfile( $TMPDIR, 'mpd.conf' );


{ # this will be run when module will be use-d
    my $restart = 0;
    my $stopit  = 0;

    $restart = _stop_user_mpd_if_needed();
    customize_test_mpd_configuration();
    $stopit  = start_test_mpd();

    END {
        stop_test_mpd() if $stopit;
        return unless $restart;       # no need to restart
        system 'mpd 2>/dev/null';     # restart user mpd
        sleep 1;                      # wait 1 second to let mpd start.
    }
}


# -- public subs

=method customize_test_mpd_configuration( [$port] );

Create a fake mpd configuration file, based on the file
F<mpd.conf.template> located in F<share> subdir. The string PWD will be
replaced by the real path (ie, where the tarball has been untarred),
while TMP will be replaced by a new temp directory. The string PORT will
be replaced by C<$port> if specified, 6600 otherwise (MPD's default).

=cut

sub customize_test_mpd_configuration {
    my ($port) = @_;
    $port ||= 6600;

    # open template and config.
    open my $in,  '<',  $TEMPLATE or die "can't open [$TEMPLATE]: $!";
    open my $out, '>',  $CONFIG   or die "can't open [$CONFIG]: $!";

    # replace string and fill in config file.
    while ( defined( my $line = <$in> ) ) {
        $line =~ s!PWD!$SHAREDIR!;
        $line =~ s!TMP!$TMPDIR!;
        $line =~ s!PORT!$port!;
        print $out $line;
    }

    # clean up.
    close $in;
    close $out;
}


=method start_test_mpd();

Start the fake mpd, and die if there were any error.

=cut

sub start_test_mpd {
    my $output = qx{ mpd --create-db $CONFIG 2>&1 };
    die "could not start fake mpd: $output\n" if $output;
    sleep 1;   # wait 1 second to let mpd start.
    return 1;
}


=method stop_test_mpd();

Kill the fake mpd.

=cut

sub stop_test_mpd {
    system "mpd --kill $CONFIG 2>/dev/null";
    sleep 1;   # wait 1 second to free output device.
    unlink "$TMPDIR/state", "$TMPDIR/music.db";
}


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
    stop_test_mpd();

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

=head1 SEE ALSO

You can find more information on the mpd project on its homepage at
L<http://www.musicpd.org>.wikia.com>.

Original code (2005) by Tue Abrahamsen C<< <tue.abrahamsen@gmail.com> >>,
documented in 2006 by Nicholas J. Humfrey C<< <njh@aelius.com> >>.

C<Audio::MPD> development takes place on <audio-mpd@googlegroups.com>:
feel free to join us. (use L<http://groups.google.com/group/audio-mpd>
to sign in). Our git repository is located at
L<http://github.com/jquelin/audio-mpd.git>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-MPD>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-MPD>

=back

