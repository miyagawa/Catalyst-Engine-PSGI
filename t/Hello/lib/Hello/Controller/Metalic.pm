package Hello::Controller::Metalic;
use strict;
use warnings;
use parent qw(Catalyst::Controller::Metal);

sub call {
    my($self, $env) = @_;

    if ($env->{PATH_INFO} =~ m!^/metal!) {
        return [ 200, [ "Content-Type" => 'text/plain' ], [ "Hello Metal" ] ];
    } else {
        return [ 404, [], [] ];
    }
}

1;
