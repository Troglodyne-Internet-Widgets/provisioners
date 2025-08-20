package Provisioner::Recipe::data;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{openssh-server openssh-client rsync};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;
	my $dir = $opts{from};
	die "Must set from in [data] section of recipes.yaml" unless $dir;

	return %opts;
}

1;
