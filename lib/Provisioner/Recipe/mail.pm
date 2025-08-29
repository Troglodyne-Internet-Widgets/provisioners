package Provisioner::Recipe::mail;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

use UUID qw{uuid};
use MIME::Base64 qw{encode_base64};
use Crypt::Digest::SHA512 qw{sha512};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{postfix dovecot-imapd dovecot-pop3d dovecot-antispam dovecot-sieve postgrey opendmarc opendkim spamassassin clamav amavisd-new};
	}
	die "Unsupported packager";
}

sub validate {
    my ($self, %vars) = @_;

    if ( $vars{forwarders} ) {
        die "aliases must be ARRAY" unless ref $vars{aliases} eq 'ARRAY';
    }

    if ( $vars{names} ) {
        die "names must be HASH" unless ref $vars{names} eq 'HASH';
        foreach my $name (keys %{$vars{names}}) {
            my $passwd = $vars{names}{$name};
            die "Each name must be a HASH" unless ref $passwd eq 'HASH';
            die "names must have a password & gecos" unless $passwd->{password} && $passwd->{gecos}
        }
    }

    if ( $vars{mail_aliases} ) {
        die "mail_aliases must be ARRAY" unless ref $vars{mail_aliases} eq 'ARRAY';
        foreach my $alias (@{$vars{mail_aliases}}) {
            die "Each alias must be a HASH" unless ref $alias eq 'HASH';
            die "mail_aliases must have a from & to" unless $alias->{from} && $alias->{to}
        }
    }

    return %vars;
}

sub template_files {
	my ($self, @recipes) = @_;

    return (
        'mail.aliases.tt'                => 'aliases',
        'mail.header_checks.tt'          => 'header_checks',
        'mail.virtual_maps.tt'           => 'virtual_maps',
        'mail.virtual_aliases.tt'        => 'virtual_aliases',
        'mail.dovecot.tt'                => 'dovecot.conf',
        'mail.passwd.tt'                 => 'mailpasswd',
        'mail.opendkim.tt'               => 'opendkim.conf',
        'mail.opendkim-trustedhosts.tt'  => 'TrustedHosts',
        'mail.opendkim-signingtable.tt'  => 'SigningTable',
        'mail.opendkim-keytable.tt'      => 'KeyTable',
        'mail.opendkim-internalhosts.tt' => 'InternalHosts',
        'mail.opendmarc.tt'              => 'opendmarc.conf',
        'mail.opendmarc-ignorehosts.tt'  => 'ignore.hosts',
    );
}

sub formatters {
    my ($class) = shift;
    return (
        salted_sha_256 => Text::Xslate::html_builder(sub {
            my $pw = shift;
            my $salt = uuid();
            # XXX dovecot documentation is unclear whether I need to separate these via a \$ or what.
            # https://doc.dovecot.org/2.3/configuration_manual/authentication/password_schemes/#salting
            my $raw = encode_base64(sha512("$pw$salt") . "$salt" );
            $raw =~ s/\n//g;
            return "{SSHA512}$raw";
        }),
    );
}

1;
