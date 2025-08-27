package Provisioner::Recipe;

use strict;
use warnings;

use Text::Xslate;

# Base class for provisioner recipes
# We build a big makefile for running on the guest via these templated makefile fragments.

sub new {
    my ($class, %opts) = @_;

    my ($tname) = $class =~ m/^Provisioner::Recipe::(\w+)$/;
    die "Could not extract recipe name.  Recipes must be of form Provisioner::Recipe::*" unless $tname;

    $opts{template} = "$tname.tt";

    $opts{tt} = Text::Xslate->new({
        path   => "templates/",
        syntax => 'TTerse',
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

# Return a HASH of template => filename within the make tarball
# Optionally making templates based on what other recipes you use
sub template_files {
    my ($self, @recipes) = @_;
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
