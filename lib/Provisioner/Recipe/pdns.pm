package Provisioner::Recipe::pdns;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

use Text::Xslate;
use Net::IP;
use File::Slurper;

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{pdns-server pdns-tools pdns-backend-sqlite3 sqlite3 libconfig-simple-perl};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;

    my $soa = $opts{soa};
    die "Must define soa ns in [pdns] section of recipes.yaml" unless $soa;

    my $extras = $opts{extra_records};
    die "extra_records defined in [pdns] must be a readable text file" if $extras && ! -f $extras;
    $opts{extra_records} = File::Slurper::read_text($extras);

    $opts{serial} = time;
	return %opts;
}

sub template_files {
	my ($self) = @_;

	return (
		'pdns.zone.tt'    => 'zonefile',
        'pdns.domain.tt'  => 'pdns-domain.conf',
		'pdns.rsyslog.tt' => '10-powerdns.conf',
	);
}

sub formatters {
    my ($class) = shift;
    return (
        reverse_ip => Text::Xslate::html_builder(sub {
            my $ip = shift;
            return Net::IP->new($ip)->reverse_ip();
        }),
        email_for_dns => Text::Xslate::html_builder(sub {
            my $email = shift;
            $email =~ tr/@/./;
            return $email;
        }),
    );
}

1;
