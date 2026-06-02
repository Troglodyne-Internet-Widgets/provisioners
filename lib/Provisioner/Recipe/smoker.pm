package Provisioner::Recipe::smoker;

use strict;
use warnings FATAL => 'all';

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::smoker

=head2 SYNOPSIS

    somedomain:
        smoker:
            repos:
                - Troglodyne-Internet-Widgets/tCMS
                - Troglodyne-Internet-Widgets/tPSGI
            basedir: /opt/smoke

=head2 DESCRIPTION

Clones a list of GitHub repositories and runs the standard ExtUtils::MakeMaker
smoke-test workflow against each:

    cpanm --installdeps .
    perl Makefile.PL
    make test

Designed for CI-like smoke testing of repos from the Troglodyne-Internet-Widgets
GitHub organisation that use Makefile.PL-based distributions.

Repos may be specified as C<owner/repo> shortnames (resolved to
C<https://github.com/owner/repo>) or as full git URLs.

System deps cover all native libraries required to compile the XS modules
found in tCMS and related packages (SQLite, libmagic, libxml2, OpenSSL,
inotify, etc.).

=head3 deps

System packages required on a Debian guest to compile XS modules common
to the Troglodyne-Internet-Widgets Perl repositories.

=head3 validate

Coerces each entry in C<repos> to a full HTTPS git URL, defaulting
C<basedir> to C</opt/smoke>.  Builds a C<repo_list> AoH of
C<< { name => ..., url => ... } >> for easy iteration in the template.

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{
            git make build-essential g++
            libsqlite3-dev libmagic-dev
            libxml2-dev libexpat1-dev
            libssl-dev zlib1g-dev
            autoconf libseccomp-dev libtool libtool-bin
        };
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    my $repos = $opts{repos};
    die "Must set repos in [smoker] section — list of owner/repo shortnames or full git URLs"
        unless $repos && ref $repos eq 'ARRAY' && @$repos;

    $opts{basedir} //= '/opt/smoke';

    # Normalise to full HTTPS URLs and extract a short name for the clone dir.
    $opts{repo_list} = [
        map {
            my $url = m{^https?://} ? $_ : "https://github.com/$_";
            ( my $name = $url ) =~ s{.*/([^/]+?)(?:\.git)?$}{$1};
            { name => $name, url => $url }
        } @$repos
    ];

    return %opts;
}

1;
