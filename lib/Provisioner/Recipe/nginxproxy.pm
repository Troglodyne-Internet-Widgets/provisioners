package Provisioner::Recipe::nginxproxy;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::nginxproxy

=head2 SYNOPSIS

    somedomain:
        nginxproxy:
            proxy_uri: http://unix:/path/to/socket
            proxy_buffering: 0

=head2 DESCRIPTION

Sets up reverse proxy rules for the primary application to be deployed.

Optionally turn off proxy buffering (if you do things like COMET this is needed).

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{nginx-full};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;
    my $uri = $opts{proxy_uri};
    die "Must set proxy_uri in [nginxproxy] section of recipes.yaml" unless $uri;
    return %opts;
}

sub template_files {
    my ($self) = @_;

    return (
        'nginx.global.conf.tt' => 'nginx.global.conf',
        'nginx.domain.conf.tt' => 'nginx.domain.conf',

        #XXX TODO this needs to be in the MAIN target, NOT here
        'openssl.tt' => 'openssl.conf',
    );
}

1;
