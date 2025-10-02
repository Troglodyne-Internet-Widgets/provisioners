package Provisioner::Recipe::mail;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::mail

=head2 SYNOPSIS

    somedomain:
        mail:
            relay:
                host: "mail.somerelay.net"
                port: 25025
                to:
                    - "somesite.net"
            names:
                me:
                    gecos: "Me"
                    password: "@Test_123!"
                you:
                    gecos: "You"
                    password: "@Test_123!"
            mail_aliases:
                - Me: you
                - You: me

=head2 DESCRIPTION

Setup and configure a mailserver (postfix MUA, dovecot LDA, amavis + opendmarc + opendkim)

Supports SMTP relaying to other hosts, and in general chooses sane defaults.
Optionally restrict what hosts you use the relay for sending to.

Sets up the virtual users you specify with the provided passwords.

TODO: gather this data from something secure, such as keepass or vault.

=cut

use UUID qw{uuid};
use MIME::Base64 qw{encode_base64};
use Crypt::Digest::SHA512 qw{sha512};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{postfix postfix-pcre dovecot-imapd dovecot-pop3d dovecot-antispam dovecot-sieve dovecot-lmtpd postgrey opendmarc opendkim spamassassin clamav amavisd-new rpm2cpio 7zip bzip2 lrzip lzop unrar-free};
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
        'mail.transport_maps.tt'         => 'transport_maps',
        'mail.sdd_relay_maps.tt'         => 'sdd_relay_maps',
        'mail.recipient_access_pcre.tt'  => 'recipient_access_pcre',
        'mail.dovecot.tt'                => 'dovecot.conf',
        'mail.dovecot.domain.tt'         => 'dovecot.domain.conf',
        'mail.passwd.tt'                 => 'mailpasswd',
        'mail.opendkim.tt'               => 'opendkim.conf',
        'mail.opendkim-trustedhosts.tt'  => 'TrustedHosts',
        'mail.opendkim-signingtable.tt'  => 'SigningTable',
        'mail.opendkim-keytable.tt'      => 'KeyTable',
        'mail.opendkim-internalhosts.tt' => 'InternalHosts',
        'mail.opendmarc.tt'              => 'opendmarc.conf',
        'mail.opendmarc-ignorehosts.tt'  => 'ignore.hosts',
        'mail.postfix.master.tt'         => 'master.cf',
        'mail.amavis.tt'                 => '50-user',
		'mail.autodiscover.tt'           => 'autodiscover.xml',
		'mail.autodiscover_vhost.tt'     => 'autodiscover_vhost',
    );
}

sub formatters {
    my ($class) = shift;
    return (
        salted_sha_512 => Text::Xslate::html_builder(sub {
            my $pw = shift;
            my $salt = uuid();
            # https://doc.dovecot.org/2.3/configuration_manual/authentication/password_schemes/#salting
            my $raw = encode_base64( sha512("$pw$salt") . $salt );
            $raw =~ s/\n//g;
            return "{SSHA512}$raw";
        }),
    );
}

sub datadirs {
    return ('.mail');
}

sub remote_files {
    return (
        '/mail/keys'     => '.mail/keys',
    );
}


1;
