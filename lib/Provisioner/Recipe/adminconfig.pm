package Provisioner::Recipe::adminconfig;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self, %opts) = @_;
	if ($self->{target_packager} eq 'deb') {
		return @{$opts{pkgs}} if ref $opts{pkgs} eq 'ARRAY';
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;

    my $soa = $opts{skel};
    die "Must define skel ns in [adminconfig] section of recipes.yaml" unless $soa;

	return %opts;
}

1;
