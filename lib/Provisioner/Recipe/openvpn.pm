package Provisioner::Recipe::openvpn;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::openvpn

=head2 SYNOPSIS

In recipes.yaml:

    somedomain:
        openvpn:
            port: 1194
            proto: udp
            subnet: 10.8.0.0
            netmask: 255.255.255.0
            dns:
                - 1.1.1.1
                - 1.0.0.1
            cipher: AES-256-GCM
            interface: eth0

=head2 DESCRIPTION

Sets up an OpenVPN server using easy-rsa for PKI management.

Generates a server CA, server certificate/key, and DH parameters under
/etc/openvpn/easy-rsa/. The server listens on the configured port/proto and
pushes a route for the VPN subnet to clients.

If the ufw recipe is also enabled, a UFW application rule for OpenVPN will be
installed automatically.

The interface option is used to set up NAT (masquerade) so VPN clients can
reach the internet. If omitted, NAT is not configured.

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{openvpn easy-rsa};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    $opts{port}    //= 1194;
    $opts{proto}   //= 'udp';
    $opts{subnet}  //= '10.8.0.0';
    $opts{netmask} //= '255.255.255.0';
    $opts{cipher}  //= 'AES-256-GCM';
    $opts{dns}     //= [ '1.1.1.1', '1.0.0.1' ];

    die "proto must be 'udp' or 'tcp'" unless $opts{proto} =~ /^(udp|tcp)$/;
    die "port must be numeric"         unless $opts{port}  =~ /^\d+$/;
    die "dns must be an ARRAY"         unless ref $opts{dns} eq 'ARRAY';

    return %opts;
}

sub template_files {
    my ($self) = @_;

    return (
        'openvpn.server.conf.tt' => 'server.conf',
    );
}

1;
