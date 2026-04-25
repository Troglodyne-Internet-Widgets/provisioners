package Provisioner::Recipe::adminconfig;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::adminconfig

=head2 SYNOPSIS

In recipes.yaml:

    somedomain:
        adminconfig:
            pkgs:
                - vim
                - tig
                - tmux
                - plocate
            skel: "/opt/dotfiles/foobar"

=head2 DESCRIPTION

Set up the skel for the admin user specified in ipmap.cfg.

Optionally add in packages for the administrator to use on the provisioned host.

=cut

sub deps {
    my ( $self, %opts ) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return ref $opts{pkgs} eq 'ARRAY' ? @{ $opts{pkgs} } : ();
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    my $soa = $opts{skel};
    die "Must define skel ns in [adminconfig] section of recipes.yaml" unless $soa;

    return %opts;
}

1;
