package Provisioner::Recipe::nosnap;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub template_files {
	my ($self) = @_;

	return (
		'nosnap.tt' => 'nosnap.pref',
	);
}

1;
