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

__END__

=head1 NAME

Catalyst::Controller::Metal - Raw PSGI handling in Catalyst controllers

=head1 SYNOPSIS

  package MyApp::Controller::Metalic;
  use parent 'Catalyst::Controller::Metal';

  sub call {
      my($self, $env) = @_;
      if ($env->{PATH_INFO} =~ m!^/hello!) {
          return [ 200, [ "Content-Type" => 'text/plain' ], [ "Hello World" ] ];
      } else {
          return [ 404, [], [] ];
      }
  }

Catalyst::Controller::Metal allows you to write a raw PSGI handler in
your Catalyst application, inspired by Rails Metal that allows you to
write raw Rack application inside Ruby on Rails.

=head1 SEE ALSO

Rails Metal.

=cut
