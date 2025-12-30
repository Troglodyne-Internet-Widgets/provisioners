package Provisioner::Recipe::backup;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::backup

=head2 SYNOPSIS

In recipes.yaml:

    somedomain:
        backup:
            targets:
                database: "/var/lib/mysql"
                mail: "/mail"
                ...
            key_file: "path/to/key_file_in_datadir"

=head2 DESCRIPTION

When you have files on the host which need backing up, but aren't already covered by the provisioning process itself.

Pair with a VM using L<Provisioner::Recipe::backupdestination> to fully automate backups.

Backups are implemented via SSH authorized key read-only restricted execution of an ephemeral & chrooted instance of rsyncd as root on port 40404.

=cut

sub deps {
	my ($self, %opts) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{rsync openssh-server};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;

    my $targets = $opts{targets};
    die "Must define targets ns in [backup] section of recipes.yaml" unless $targets;
    die "targets in [backup] must be HASH" unless ref $targets eq 'HASH';

    my $key_file = $opts{key_file};
    die "Must define key_file in [backupdestination] section of recipes.yaml" unless $key_file;
    my $kf = "$opts{data_source}/$opts{domain}/$key_file";
    die "key_file defined in [backupdestination] must exist in $kf" unless -f $kf;

    # Extract the pubkey so we don't have to schlep the pkey over to the host
    # XXX support non rsa keys ig?
    $opts{pubkey} = `ssh-keygen -yf "$kf"`;
    chomp $opts{pubkey};
    die "Could not extract pubkey!" unless $opts{pubkey};

	return %opts;
}

sub template_files {
    return (
        "backup.rsyncd.conf.tt" => "rsyncd.conf",
    );
}

1;
