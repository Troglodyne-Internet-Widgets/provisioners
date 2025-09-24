package Provisioner::Recipe::nginxproxy;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{nginx-full};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;
	my $uri = $opts{proxy_uri};
	die "Must set proxy_uri in [nginxproxy] section of recipes.yaml" unless $uri;
	return %opts;
}

sub template_files {
	my ($self) = @_;

	return (
		'nginx.global.conf.tt' => 'nginx.global.conf',
		'nginx.domain.conf.tt' => 'nginx.domain.conf',
        'openssl.tt'           => 'openssl.conf',
	);
}

1;
