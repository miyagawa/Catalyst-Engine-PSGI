#!/usr/bin/env perl
use strict;
use warnings;
use Hello;

Hello->setup_engine('PSGI');
my $app = sub { Hello->run(@_) };

