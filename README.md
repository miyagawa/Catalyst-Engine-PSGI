# NAME

Catalyst::Engine::PSGI - PSGI engine for Catalyst

# WARNINGS

**Catalyst 5.9000 or later has a built-in PSGI support and this module is deprecated.**

# SYNOPSIS

    # app.psgi
    use strict;
    use MyApp;

    MyApp->setup_engine('PSGI');
    my $app = sub { MyApp->run(@_) };

# DESCRIPTION

Catalyst::Engine::PSGI is a Catalyst Engine that adapts Catalyst into the PSGI gateway protocol.

# COMPATIBILITY

- Currently this engine works with Catalyst 5.8 (Catamoose) or newer.
- Your application is supposed to work with any PSGI servers without any
code modifications, but if your application uses `$c->res->write`
to do streaming write, this engine will buffer the ouput until your
app finishes.

    To do real streaming with this engine, you should implement an
    IO::Handle-like object that responds to `getline` method that returns
    chunk or undef when done, and set that object to `$c->res->body`.

    Alternatively, it is possible to set the body to a code reference,
    which will be used to stream content as documented in the
    [PSGI spec](https://metacpan.org/pod/PSGI#Delayed_Reponse_and_Streaming_Body).

- When your application runs behind the frontend proxy like nginx or
lighttpd, this Catalyst engine doesn't automatically recognize the
incoming headers like `X-Forwarded-For`, because respecting these
headers by default causes a potential security issue.

    You have to enable [Plack::Middleware::ReverseProxy](https://metacpan.org/pod/Plack::Middleware::ReverseProxy) or
    [Plack::Middleware::ForwardedHeaders](https://metacpan.org/pod/Plack::Middleware::ForwardedHeaders) to automatically promote those
    forwarded headers into `REMOTE_ADDR` hence IP address of the request.

    ReverseProxy middleware is pretty simple and has no configuration
    while ForwardedHeaders allows you to configure which upstream host to
    trust, etc.

# AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

Most of the code is taken and modified from Catalyst::Engine::CGI.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

_Catalyst::Engine_ [PSGI](https://metacpan.org/pod/PSGI) _Plack_
