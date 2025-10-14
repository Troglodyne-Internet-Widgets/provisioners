package Provisioner::Recipe::roundcube;

use strict;
use warnings;

use UUID ();

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::roundcube

=head2 SYNOPSIS

In recipes.yaml:

    somedomain:
        roundcubeconfig:
            package_url: https://github.com/roundcube/roundcubemail/releases/download/1.6.11/roundcubemail-1.6.11-complete.tar.gz
            pkgs: 
            skel: "/var/www/roundcube"

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
        sqlite3
    };
}

# NOTE: FPM php.ini: /etc/php/8.3/fpm/php.ini

sub template_files {
    return (
        'roundcube.config.inc.php.tt' => 'config.inc.php',
        'roundcube.fpm.ini.tt'        => 'fpm.ini',
    );
}

sub makefile_vars {
    return (
        PHP_VER => q{$(shell(php --version | egrep -o '[0-9]+\.[0-9]' | head -n 1))},
    );
}

sub validate {
	my ($self, %opts) = @_;
    $opts{'des_key'} = 'rcube-' . UUID::uuid();

	return %opts;
}

1;
