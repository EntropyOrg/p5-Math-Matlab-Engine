use Test::More tests => 2;

use strict;
use warnings;

BEGIN { use_ok('Math::Matlab::Engine') }

my $ep = Math::Matlab::Engine->new();
ok(ref($ep),"Math::Matlab::Engine");
