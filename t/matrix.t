use Test::More tests => 10;

use strict;
use warnings;

use Math::Matlab::Engine;

my $ep = Math::Matlab::Engine->new;
ok(defined $ep->PutArray('N',[2,3],[1,2,3,4,5,6]));

ok(defined $ep->PutArray('E1',[3,1],[1,0,0]));
ok(defined $ep->PutArray('E2',[3,1],[0,1,0]));
ok(defined $ep->PutArray('E3',[3,1],[0,0,1]));

ok(defined $ep->EvalString("N1=N*E1"));
ok(defined $ep->EvalString("N2=N*E2"));
ok(defined $ep->EvalString("N3=N*E3"));

my $n1 = $ep->GetArray('N1');
is($n1->[0][0], 1);
is($n1->[0][1], 0);
is($n1->[1][0], 4);

done_testing;
