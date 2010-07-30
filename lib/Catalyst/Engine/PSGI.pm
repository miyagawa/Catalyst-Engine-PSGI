package Catalyst::Engine::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.11';

use Moose;
extends 'Catalyst::Engine';

{
    # Temporary hack to see if there are better ways like TraitFor,
    # but without requiring downstream changes.
    sub Catalyst::Request::env {
        my $req = shift;
        $req->{_psgi_env} = shift if @_;
        $req->{_psgi_env};
    }
}

use Scalar::Util qw(blessed);
use URI;
use Catalyst::Controller::Metal;

# This is what Catalyst does to decode path. Not compatible to CGI RFC 3875
my %reserved = map { sprintf('%02x', ord($_)) => 1 } split //, $URI::reserved;
sub _uri_safe_unescape {
    my ($s) = @_;
    $s =~ s/%([a-fA-F0-9]{2})/$reserved{lc($1)} ? "%$1" : pack('C', hex($1))/ge;
    $s
}

sub prepare_connection {
    my ( $self, $c ) = @_;

    my $request = $c->request;
    my $env = $self->env;

    $request->env($env);
    $request->address( $env->{REMOTE_ADDR} );
    $request->hostname( $env->{REMOTE_HOST} ) if exists $env->{REMOTE_HOST};
    $request->protocol( $env->{SERVER_PROTOCOL} );
    $request->user( $env->{REMOTE_USER} );  # XXX: Deprecated. See Catalyst::Request for removal information
    $request->remote_user( $env->{REMOTE_USER} );
    $request->method( $env->{REQUEST_METHOD} );

    $request->secure( $env->{'psgi.url_scheme'} eq 'https' );
}

sub prepare_headers {
    my ( $self, $c ) = @_;

    my $env = $c->request->env;
    my $headers = $c->request->headers;
    foreach my $header ( keys %$env ) {
        next unless $header =~ /^(HTTP|CONTENT|COOKIE)/i;
        ( my $field = $header ) =~ s/^HTTPS?_//;
        $field =~ tr/_/-/;
        $headers->header( $field => $env->{$header} );
    }
}

sub prepare_path {
    my ( $self, $c ) = @_;

    my $env = $c->request->env;

    my $scheme = $c->request->secure ? 'https' : 'http';
    my $host      = $env->{HTTP_HOST} || $env->{SERVER_NAME};
    my $port      = $env->{SERVER_PORT} || 80;
    my $base_path = $env->{SCRIPT_NAME} || "/";

    # set the request URI
    my $req_uri = $env->{REQUEST_URI};
       $req_uri =~ s/\?.*$//;
    my $path = _uri_safe_unescape($req_uri);
    if ($path eq $base_path) {
        $path .= "/"; # To fool catalyst a bit
    }
    $path =~ s{^/+}{};

    # Using URI directly is way too slow, so we construct the URLs manually
    my $uri_class = "URI::$scheme";

    # HTTP_HOST will include the port even if it's 80/443
    $host =~ s/:(?:80|443)$//;

    if ( $port !~ /^(?:80|443)$/ && $host !~ /:/ ) {
        $host .= ":$port";
    }

    # Escape the path
    $path =~ s/([^$URI::uric])/$URI::Escape::escapes{$1}/go;
    $path =~ s/\?/%3F/g; # STUPID STUPID SPECIAL CASE

    my $query = $env->{QUERY_STRING} ? '?' . $env->{QUERY_STRING} : '';
    my $uri   = $scheme . '://' . $host . '/' . $path . $query;

    $c->request->uri( bless \$uri, $uri_class );

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ m{/$};

    my $base_uri = $scheme . '://' . $host . $base_path;

    $c->request->base( bless \$base_uri, $uri_class );
}

around prepare_query_parameters => sub {
    my $orig = shift;
    my ( $self, $c ) = @_;

    if ( my $qs = $c->request->env->{QUERY_STRING} ) {
        $self->$orig( $c, $qs );
    }
};

sub prepare_request {
    my ( $self, $c, %args ) = @_;

    if ( $args{env} ) {
        $self->env( $args{env} );
    }

    $self->{buffer} = '';
}

sub write {
    my($self, $c, $buffer) = @_;
    $self->{buffer} .= $buffer if defined $buffer;
}

sub finalize_body {
    # do nothing since we serve content
}

sub read_chunk {
    my($self, $c) = (shift, shift);
    $self->env->{'psgi.input'}->read(@_);
}

sub run {
    my($self, $class, $env) = @_;

    # short circuit with Metal
    for my $metal (Catalyst::Controller::Metal->metals_for($class)) {
        my $res = $metal->call($env);
        if (defined $res && !(ref $res eq 'ARRAY' && $res->[0] == 404)) {
            return $res;
        }
    }

    # what Catalyst->handle_request does
    my $status = -1;
    my $c;
    eval {
        $c = $class->prepare(env => $env);
        $c->dispatch;
        $status = $c->finalize;
    };

    # clear the $env ref to avoid leaks
    $self->env(undef);

    if (my $error = $@) {
        chomp $error;
        $class->log->error(qq/Caught exception in engine "$error"/);
    }

    if (my $coderef = $class->log->can('_flush')){
        $class->log->$coderef();
    }

    return [ 500, [ 'Content-Type' => 'text/plain', 'Content-Length' => 11 ], [ 'Bad request' ] ]
        unless $c;

    my $body = $c->res->body;
    if (!ref $body && $body eq '' && $self->{buffer}) {
        $body = [ $self->{buffer} ];
    } elsif (ref($body) eq 'GLOB' || (Scalar::Util::blessed($body) && $body->can('getline'))) {
        # $body is FH
    } elsif (ref($body) eq 'CODE') {
        return $body;
    } else {
        $body = [ $body ];
    }

    my $headers = [];
    $c->res->headers->scan(sub { push @$headers, @_ });
    return [ $c->res->status, $headers, $body ];
}

no Moose;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Catalyst::Engine::PSGI - PSGI engine for Catalyst

=head1 SYNOPSIS

  # app.psgi
  use strict;
  use MyApp;

  MyApp->setup_engine('PSGI');
  my $app = sub { MyApp->run(@_) };

=head1 DESCRIPTION

Catalyst::Engine::PSGI is a Catalyst Engine that adapts Catalyst into the PSGI gateway protocol.

=head1 COMPATIBLITY

=over 4

=item *

Currently this engine works with Catlayst 5.8 (Catamoose) or over.

=item *

Your application is supposed to work with any PSGI servers without any
code modifications, but if your application uses C<< $c->res->write >>
to do streamin write, this engine would buffer the ouput until your
app finishes.

To do real streaming with this engine, you should implement an
IO::Handle-like object that responds to C<getline> method that returns
chunk or undef when done, and set that object to C<< $c->res->body >>.

Alternatively, it is possible to set the body to a code reference,
which will be used to steam content as documented in the
L<PSGI/Delayed_Reponse_and_Streaming_Body|PSGI spec>.

=item *

When your application runs behind the frontend proxy like nginx or
lighttpd, this Catalyst engine doesn't automatically recognize the
incoming headers like C<X-Forwarded-For>, because respecting these
headers by default causes a potential security issue.

You have to enable L<Plack::Middleware::ReverseProxy> or
L<Plack::Middleware::ForwardedHeaders> to automatically promote those
forwarded headers into C<REMOTE_ADDR> hence IP address of the request.

ReverseProxy middleware is pretty simple and has no configuration
while ForwardedHeaders allows you to configure which upstream host to
trust, etc.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Most of the code is taken and modified from Catalyst::Engine::CGI.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

I<Catalyst::Engine> L<PSGI> I<Plack>

=cut
