package Provisioner::Recipe;

use strict;
use warnings;

use Text::Xslate;
use Config::Simple;

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
    }) || die "Could not initialize template dir";

    return bless(\%opts, $class);
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

sub render {
    my $self = shift;
    my %vars = $self->validate(
        # Sane defaults
        $self->vars(),
        # Config overrides
        @_,
    );
    return $self->{tt}->render($self->{template}, \%vars);
}

1;
