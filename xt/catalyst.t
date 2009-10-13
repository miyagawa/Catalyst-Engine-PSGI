use lib "t/catalyst/lib";
use Plack::Test::Adopt::Catalyst qw(TestApp);
runtests glob 't/catalyst/aggregate/*.t';

