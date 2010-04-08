package Catalyst::Helper::PSGI;
use strict;
use warnings;
use File::Spec;

sub mk_stuff {
    my($self, $helper, @args) = @_;

    my $base = $helper->{base};
    my $app  = lc $helper->{app};

    $app =~ s/::/_/g;

    my $script = File::Spec->catfile($base, 'script', "$app.psgi");

    $helper->render_file('psgi_app', $script);
    chmod 0755, $script;
}

=head1 NAME

Catalyst::Helper::PSGI - PSGI helper to create a .psgi application script

=head1 SYNOPSIS

  > script/myapp_create.pl PSGI

=head1 DESCRIPTION

This helper module creates a C<myapp.psgi> application script so you
can run your Catalyst with PSGI servers using L<plackup> or L<Plack::Loader>.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Catalyst::Engine::PSGI>

=cut

1;

__DATA__

__psgi_app__
#!/usr/bin/env perl
use strict;
use warnings;
use [% app %];

[% app %]->setup_engine('PSGI');
my $app = sub { [% app %]->run(@_) };

