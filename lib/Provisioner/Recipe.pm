package Provisioner::Recipe;

use strict;
use warnings FATAL => 'all';

use Text::Xslate;
use Text::Xslate::Bridge::TT2;

# Base class for provisioner recipes
# We build a big makefile for running on the guest via these templated makefile fragments.

sub new {
    my ($class, %opts) = @_;

    my ($tname) = $class =~ m/^Provisioner::Recipe::(\w+)$/;
    die "Could not extract recipe name.  Recipes must be of form Provisioner::Recipe::*" unless $tname;

    $opts{template} = "$tname.tt";

    $opts{tt} = Text::Xslate->new({
        path     => $opts{template_dirs},
        syntax   => 'TTerse',
		module   => [qw{Text::Xslate::Bridge::TT2}],
		function => {$class->formatters()},
    }) || die "Could not initialize template dir";

    return bless(\%opts, $class);
}

# STATIC METHOD
sub formatters {
	return ();
}

sub vars {
    return ();
}

sub deps {
    return ();
}

sub validate {
    shift;
    return @_;
}

# Return array of dirs to make within the DATADIR.
# This way you can shove stuff in from remote_files where you want.
sub datadirs {
	return ();
}

# Return a HASH of thing_to_fetch => where_to_store
# So that we can grab artifacts from a prior deploy and shove them in the DATA dir.
# NOTE: this will only happen if the admin user's authorized keys has the key of the person running the deploys.
# Also, we use this as a list of files to backup with the backup/backupdestination recipes
sub remote_files {
	return ();
}

# Return a HASH of template => filename within the make tarball
# Optionally making templates based on what other recipes you use
sub template_files {
    my ($self, @recipes) = @_;
	return ();
}

# Return a HASH of name => value of vars to set in the makefile before any target runs.
sub makefile_vars {
	return ();
}

# Global parameter validation
my $validate = sub {
    my %params = @_;
    return %params;
};

sub render {
    my ($self) = shift;
	return $self->render_file($self->{template}, @_);
}

sub render_file {
    my ($self, $file) = (shift, shift);
    my %vars = $self->validate(
        # Sane defaults
        $self->vars(),
        # Config overrides
        @_,
    );
    %vars = $validate->(%vars);
    return $self->{tt}->render($file, \%vars);
}


1;
