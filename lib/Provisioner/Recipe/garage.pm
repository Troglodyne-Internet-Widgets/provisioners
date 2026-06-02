package Provisioner::Recipe::garage;

use strict;
use warnings FATAL => 'all';

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::garage

=head2 SYNOPSIS

    somedomain:
        garage:
            rpc_secret: "your-64-hex-char-secret-here"
            version: v1.0.1
            data_dir: /var/lib/garage/data
            metadata_dir: /var/lib/garage/meta
            replication_factor: 1
            s3_region: garage
            api_port: 3900
            rpc_port: 3901
            web_port: 3902
            admin_port: 3903
            zone: dc1
            capacity: 1G
            buckets:
                - my-bucket
                - another-bucket

=head2 DESCRIPTION

Installs and configures L<Garage|https://garagehq.deuxfleurs.fr/>, a lightweight
S3-compatible distributed object-storage server.

Downloads the statically-linked garage binary from GitHub releases, installs a
systemd service, writes C</etc/garage.toml>, and runs C<garage_init.sh> to
apply a single-node layout and create any requested S3 buckets.

=head3 deps

Requires C<curl> to download the Garage binary.

=head3 validate

Validates the recipe configuration:

=over 4

=item C<rpc_secret> (required) — 64-character hex string used as the shared
RPC secret between cluster nodes.  Generate with C<openssl rand -hex 32>.

=item C<version> (optional, default C<v1.0.1>) — Garage release tag to download.

=item C<data_dir> (optional, default C</var/lib/garage/data>)

=item C<metadata_dir> (optional, default C</var/lib/garage/meta>)

=item C<replication_factor> (optional, default C<1>) — 1 for single-node.

=item C<s3_region> (optional, default C<garage>)

=item C<api_port> (optional, default C<3900>) — S3 API listen port.

=item C<rpc_port> (optional, default C<3901>) — Inter-node RPC port.

=item C<web_port> (optional, default C<3902>) — S3 static-web serve port.

=item C<admin_port> (optional, default C<3903>) — Admin API port.

=item C<zone> (optional, default C<dc1>) — Zone name for the layout assignment.

=item C<capacity> (optional, default C<1G>) — Storage capacity hint for layout.

=item C<buckets> (optional) — List of bucket names to create after startup.

=back

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{curl};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    die "Must set rpc_secret in [garage] section of recipes.yaml (generate with: openssl rand -hex 32)"
        unless $opts{rpc_secret};

    $opts{version}            //= 'v1.0.1';
    $opts{data_dir}           //= '/var/lib/garage/data';
    $opts{metadata_dir}       //= '/var/lib/garage/meta';
    $opts{replication_factor} //= 1;
    $opts{s3_region}          //= 'garage';
    $opts{api_port}           //= 3900;
    $opts{rpc_port}           //= 3901;
    $opts{web_port}           //= 3902;
    $opts{admin_port}         //= 3903;
    $opts{zone}               //= 'dc1';
    $opts{capacity}           //= '1G';
    $opts{buckets}            //= [];

    $opts{buckets} = [ $opts{buckets} ]
        if $opts{buckets} && ref $opts{buckets} ne 'ARRAY';

    return %opts;
}

sub template_files {
    return (
        'garage.toml.tt'    => 'garage.toml',
        'garage.service.tt' => 'garage.service',
        'garage_init.sh.tt' => 'garage_init.sh',
    );
}

1;
