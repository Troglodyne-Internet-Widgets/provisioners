package Provisioner::Recipe::nostubresolver;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub template_files {
	my ($self) = @_;

	return (
		'nostubresolver.tt' => '10-disable-stub-resolver.conf',
	);
}

1;
