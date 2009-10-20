use inc::Module::Install;
name 'Catalyst-Engine-PSGI';
all_from 'lib/Catalyst/Engine/PSGI.pm';

requires 'Catalyst::Runtime', '5.80';
test_requires 'Test::TCP';
test_requires 'Test::Requires';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
