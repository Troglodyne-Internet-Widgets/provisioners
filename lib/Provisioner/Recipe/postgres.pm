package Provisioner::Recipe::postgres;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::postgres

=head2 SYNOPSIS

    somedomain:
        postgres:
            dump_file: path/to/dump/in/datadir

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

    my $dump = $opts{dumps};
    die "Must define dumps in [postgres] section of recipes.yaml" if !$dump || ref $dump ne 'ARRAY';

    return %opts;
}

1;
