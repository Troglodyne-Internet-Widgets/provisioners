package Provisioner::Recipe::postgres;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::postgres

=head2 SYNOPSIS

Minimal — just install and configure postgres:

    somedomain:
        postgres:

Load an existing dump on first provision:

    somedomain:
        postgres:
            dump_file: path/to/dump/in/datadir

=head2 DESCRIPTION

Installs the latest PostgreSQL available from the OS package manager and
configures it for local TCP access with md5 authentication.

C<dump> is optional.  When specified, the path is relative to the domain's
data directory (C<install_dir/domain>).  The dump is loaded exactly once;
subsequent provisions skip it via a state file.

The C<pg_hba.conf> entry added is:

    host all all 127.0.0.1/32 md5

This allows any local application to connect over TCP with a password
without requiring peer/ident authentication.  The entry is appended only
once (idempotent).

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{postgresql postgresql-client};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;
    # dump is optional — omit if you only need postgresql installed
    return %opts;
}

1;
