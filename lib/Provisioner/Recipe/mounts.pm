package Provisioner::Recipe::mounts;

use strict;
use warnings;

=head1 Provisioner::Recipe::mounts

=head2 SYNOPSIS

    somedomain:
        mounts:
            disks:
                - type: "reiser2"
                  options: "noatime,noexec"
                  mountpoint: "/mountpoint_on_guest"
                  device: "device_or_file_on_HV"
            fuse:
                - type: "s3fs"
                  options: "ro"
                  mountpoint:"/mountpoint_in_installdir"
                  device:"my_bucket_name"

=head2 DESCRIPTION

Attach a disk to the provisioned VM, or fusemount something as the application's user.

This is useful in the event you have storage hardware of varying capabilities,
or if you have a mount requiring secrets to use, such as an AWS bucket.

This recipe is quite useful in conjunction with the 'backuphost' recipe.

If you want to setup a chroot-mount in the install_dir, use setup_chroot_mount in the script_dir within your application recipe.

You'll obviously want to have your application's recipe include the relevant FUSE driver (s3fs for the example above).

TODO: make this support more than 10 mounts at a time (csplit issue).

=cut

use parent qw{Provisioner::Recipe};

sub validate {
    my ($self, %opts) = @_;

    my $disks = $opts{disks};
    if ($disks) {
        die "mounts must be HASH" unless ref $disks eq 'ARRAY';
        foreach my $disk (@$disks) {
            $disk->{servicename} = $disk->{mountpoint};
            $disk->{servicename} =~ s|/|_|g;
        }
    }

    my $fuse = $opts{fuse};
    if ($fuse) {
        die "fuse must be HASH" unless ref $fuse eq 'ARRAY';
        foreach my $disk (@$fuse) {
            $disk->{servicename} = $disk->{mountpoint};
            $disk->{servicename} =~ s|/|_|g;
        }
    }

    return %opts;
}

sub template_files {
    my ($self, @recipes) = @_;

    return (
        'mounts.fuse.service.tt' => 'fusemounts.txt',
    );
}

1;
