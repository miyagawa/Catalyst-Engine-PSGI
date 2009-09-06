use strict;
use Test::More;
use lib "t/Hello/lib";

BEGIN { $ENV{CATALYST_ENGINE} = 'PSGI' }
use Hello;

my $app = sub {
    my $env = shift;
    Hello->run($env);
};

my $impl = $ENV{PSGI_IMPL};
if ($impl eq 'ServerSimple') {
    require PSGIRef::Impl::ServerSimple;
    my $server = PSGIRef::Impl::ServerSimple->new(8080);
    $server->psgi_app($app);
    $server->run;
} elsif ($impl eq 'Mojo') {
    require PSGIRef::Impl::Mojo;
    require Mojo::Server::Daemon;
    my $daemon = Mojo::Server::Daemon->new;
    $daemon->port(8080);
    PSGIRef::Impl::Mojo->start($daemon, $app);
} elsif ($impl eq 'AnyEvent') {
    require PSGIRef::Impl::AnyEvent;
    my $server = PSGIRef::Impl::AnyEvent->new(port => 8080);
    $server->psgi_app($app);
    $server->run;
    AnyEvent->condvar->recv;
}




