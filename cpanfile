requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Runtime', '5.80007';
requires 'Filter::Util::Call';
requires 'perl', '5.008001';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::More';
    requires 'Test::Requires';
    requires 'Test::TCP';
};
