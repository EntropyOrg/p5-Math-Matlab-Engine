use Test::More tests => 10;

use strict;
use warnings;

use Math::Matlab::Engine;

my $ep = Math::Matlab::Engine->new;
ok($ep->PutArray('N',[3,2],[1,2,3,4,5,6]));

ok($ep->PutArray('E1',[1,3],[1,0,0]));
ok($ep->PutArray('E2',[1,3],[0,1,0]));
ok($ep->PutArray('E3',[1,3],[0,0,1]));

ok($ep->EvalString("N1=N*E1"));
ok($ep->EvalString("N2=N*E2"));
ok($ep->EvalString("N3=N*E3"));

my $n1 = $ep->GetArray('N1');
ok($n1->[0]->[0],1);
ok(!defined($n1->[0]->[1]));
ok($n1->[1]->[0],4);

done_testing;
