package Provisioner::Recipe::postgres;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::postgres

=head2 SYNOPSIS

    somedomain:
        postgres:
            dump: path/to/dump/in/datadir

=head2 DESCRIPTION

Set up the latest postgres available and loads the provided dump.
It is your responsibility to make sure the dump file has CREATE DATABSE statements, etc.

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{postgresql-common};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    my $dump = $opts{dump};
    die "Must define dump in [postgres] section of recipes.yaml" unless $dump;

    return %opts;
}

1;
