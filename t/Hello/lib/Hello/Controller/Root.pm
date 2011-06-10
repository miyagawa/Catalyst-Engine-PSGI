package Hello::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Hello::Controller::Root - Root Controller for Hello

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub welcome :Local {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->res->content_type('text/plain');
    $c->res->body("Hello " . $c->req->param('name'));
}

sub headers :Local {
    my( $self, $c ) = @_;
    $c->res->header("X-Foo" => "bar\r\n\r\nbaz");
    $c->res->body("blah");
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

miyagawa

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
