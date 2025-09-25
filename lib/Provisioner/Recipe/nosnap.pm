package Provisioner::Recipe::nosnap;

use strict;
use warnings;

=head1 Provisioner::Recipe::nosnap

=head2 SYNOPSIS

    somedomain:
        nosnap:

=head2 DESCRIPTION

Rip out snap root and branch from the system, and disallow installation of anything requiring it.

For those of you who consider it an unacceptable risk to your deployed systems.

=cut

use parent qw{Provisioner::Recipe};

sub template_files {
	my ($self) = @_;

	return (
		'nosnap.tt' => 'nosnap.pref',
	);
}

1;
