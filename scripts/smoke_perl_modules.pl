#!/usr/bin/env perl

use strict;
use warnings;

use Cwd          qw{getcwd};
use File::Basename qw{basename};

my $REPO_BASEDIR = $ARGV[0];
my $CPANM_PATH   = $ARGV[1];

die "Must pass repo basedir as first arg" unless $REPO_BASEDIR;
die "Must pass path to cpanm to use as second arg" unless $CPANM_PATH;

opendir( my $dh, $REPO_BASEDIR ) or die "Cannot open $REPO_BASEDIR: $!";
my @subdirs = grep { -d "$REPO_BASEDIR/$_" && !m/^\.+$/ } readdir($dh);
closedir $dh;

my $had_failures = 0;
my $orig_dir     = getcwd();

foreach my $REPO_DIR (@subdirs) {
    my $repo_dirname = "$REPO_BASEDIR/" . basename($REPO_DIR);

    next unless -d $repo_dirname;

    # TODO understand deps for dzil/MB
    next unless -f "$repo_dirname/Makefile.PL";

    # Install declared CPAN dependencies before attempting to build.
    system( $CPANM_PATH, '--installdeps', $repo_dirname );
    my $rc = $? >> 8;
    if ($rc) {
        warn "cpanm --installdeps failed for $repo_dirname (exit $rc)\n";
        $had_failures++;
        next;
    }

    chdir $repo_dirname or do {
        warn "Cannot chdir to $repo_dirname: $!\n";
        $had_failures++;
        next;
    };

    # Generate the Makefile from Makefile.PL.
    system(qw{perl Makefile.PL});
    $rc = $? >> 8;
    if ($rc) {
        warn "perl Makefile.PL failed for $repo_dirname (exit $rc)\n";
        chdir $orig_dir;
        $had_failures++;
        next;
    }

    # Run the distribution's own test suite via the generated Makefile.
    system(qw{make test});
    $rc = $? >> 8;
    if ($rc) {
        warn "make test failed for $repo_dirname (exit $rc)\n";
        $had_failures++;
    }

    chdir $orig_dir;
}

exit $had_failures ? 1 : 0;
