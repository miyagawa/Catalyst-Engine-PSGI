package Catalyst::Engine::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Moose;
extends 'Catalyst::Engine';

use Scalar::Util qw(blessed);

sub prepare_connection {
    my ( $self, $c ) = @_;

    my $env = $self->env;
    my $request = $c->request;
    $request->address( $self->env->{REMOTE_ADDR} );

    $request->hostname( $env->{REMOTE_HOST} ) if exists $env->{REMOTE_HOST};
    $request->protocol( $env->{SERVER_PROTOCOL} );
    $request->user( $env->{REMOTE_USER} );  # XXX: Deprecated. See Catalyst::Request for removal information
    $request->remote_user( $env->{REMOTE_USER} );
    $request->method( $env->{REQUEST_METHOD} );

    $request->secure( $env->{'psgi.url_scheme'} eq 'https' );
}

sub prepare_headers {
    my ( $self, $c ) = @_;

    my $env = $self->env;
    my $headers = $c->request->headers;
    foreach my $header ( keys %$env ) {
        next unless $header =~ /^HTTPS?_/;
        ( my $field = $header ) =~ s/^HTTPS?_//;
        $field =~ tr/_/-/;
        $headers->header( $field => $env->{$header} );
    }
}

sub prepare_path {
    my ( $self, $c ) = @_;

    my $env = $self->env;

    my $scheme = $c->request->secure ? 'https' : 'http';
    my $host      = $env->{HTTP_HOST} || $env->{SERVER_NAME};
    my $port      = $env->{SERVER_PORT} || 80;
    my $base_path = $env->{SCRIPT_NAME} || "/";

    # set the request URI
    my $path = $base_path . ( $env->{PATH_INFO} || '' );
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

    if ( $self->env->{QUERY_STRING} ) {
        $self->$orig( $c, $self->env->{QUERY_STRING} );
    }
};

sub prepare_request {
    my ( $self, $c, %args ) = @_;

    if ( $args{env} ) {
        $self->env( $args{env} );
    }
}

sub write {
    # shouldn't be called
}

sub finalize_body {
    # do nothing since we serve content
}

sub read_chunk {
    my($self, $c) = (shift, shift);
    $c->env->{'psgi.input'}->read(@_);
}

sub run {
    my($self, $class, $env) = @_;

    # what Catalyst->handle_request does
    my $status = -1;
    my $c;
    eval {
        $c = $class->prepare(env => $env);
        $c->dispatch;
#        $status = $c->finalize;
    };

    if (my $error = $@) {
        chomp $error;
        $class->log->error(qq/Caught exception in engine "$error"/);
    }

    if (my $coderef = $class->log->can('_flush')){
        $class->log->$coderef();
    }

    my $body = $c->res->body;
    unless (blessed($body) && $body->can('read') or ref($body) eq 'GLOB' ) {
        $body = [ $body ];
    }

    return [ $c->res->status, $c->res->headers, $body ];
}

no Moose;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Catalyst::Engine::PSGI - PSGI engine for Catalyst

=head1 SYNOPSIS

  use strict;
  use MyApp;

  my $app = sub {
      my $env = shift;
      MyApp->run($env);
  };

  # run $app with PSGI implementation

=head1 DESCRIPTION

Catalyst::Engine::PSGI is a Catalyst Engin that uses PSGI implementation.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Most of the code is taken and modified from Catalyst::Engine::CGI.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

I<Catalyst::Engine> L<PSGIRef> I<Plack>

=cut
