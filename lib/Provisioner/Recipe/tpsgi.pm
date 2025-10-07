package Provisioner::Recipe::tpsgi;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::tpsgi

=head2 SYNOPSIS

    somedomain:
        tpsgi:

=head2 DESCRIPTION

Sets up TPSGI inside of the install_dir, so it can run your application schlepped over by the data recipe.

TODO: allow specification of specific SHA to check out.

=cut

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{git};
	}
	die "Unsupported packager";
}

sub template_files {
	return (
		'tpsgi.tt' => 'tpsgi.ini',
	);
}

1;
