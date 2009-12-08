package Catalyst::Controller::Metal;
use Moose;
extends 'Catalyst::Component';
with 'Catalyst::Component::ApplicationAttribute';

my %metals;

sub BUILD {
    my($self, $args) = @_;
    push @{$metals{$self->_application}}, $self;
}

sub metals_for {
    my($class, $application) = @_;
    @{$metals{$application} || []};
}

__PACKAGE__->meta->make_immutable;

1;
