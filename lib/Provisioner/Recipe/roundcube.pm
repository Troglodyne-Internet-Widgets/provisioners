package Provisioner::Recipe::roundcube;

use strict;
use warnings;

use List::Util qw{any};
use UUID ();

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::roundcube

=head2 SYNOPSIS

In recipes.yaml:

    somedomain:
        roundcube:
            version:

=head2 DESCRIPTION

Set up the skel for the admin user specified in ipmap.cfg.

Optionally add in packages for the administrator to use on the provisioned host.

=cut

sub deps {
	my ($self, %opts) = @_;
    return qw{
        dbconfig-common
        enchant-2
        libapr1t64
        libaprutil1-dbd-sqlite3
        libaprutil1-ldap
        libaprutil1t64
        libenchant-2-2
        php
        php-fpm
        php-auth-sasl
        php-common
        php-enchant
        php-gd
        php-intl
        php-mbstring
        php-sqlite3
		php-zip
        sqlite3
    };
}

# NOTE: FPM php.ini: /etc/php/8.3/fpm/php.ini

sub template_files {
    my ($class, @modules) = @_;
    my %f = (
        'roundcube.config.inc.php.tt' => 'config.inc.php',
        'roundcube.fpm.ini.tt'        => 'fpm.ini',
    );
    $f{'roundcube.nginx.tt'} = 'webmail_nginx.conf' if any { $_ eq 'nginxproxy' } @modules;
    return %f;
}

sub makefile_vars {
    return (
        PHP_VER => q{$(shell php --version | egrep -o "[0-9]+\.[0-9]" | head -n 1)},
    );
}

sub validate {
	my ($self, %opts) = @_;
    $opts{'des_key'} = 'rcube-' . UUID::uuid();

    my $ver = $opts{version};
    die "Must set version in [roundcube] section of configuration" unless $ver;

	return %opts;
}

1;
