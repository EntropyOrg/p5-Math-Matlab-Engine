use Test::More tests => 12;

use strict;
use warnings;

use Math::Matlab::Engine;

my $ep = Math::Matlab::Engine->new;
ok($ep->PutMatrix('N',2,3,[1,2,3,4,5,6]));
my $n;
ok($n=$ep->GetMatrix('N'));
is_deeply($n, [ [1, 3, 5],
                [2, 4, 6] ] );

ok($ep->PutMatrix('E1',3,1,[1,0,0]));
ok($ep->PutMatrix('E2',3,1,[0,1,0]));
ok($ep->PutMatrix('E3',3,1,[0,0,1]));

ok($ep->EvalString("N1=N*E1"));
ok($ep->EvalString("N2=N*E2"));
ok($ep->EvalString("N3=N*E3"));

my $n1 = $ep->GetMatrix('N1');
is_deeply( $n1, [ [1], [2] ] );

my $n2 = $ep->GetMatrix('N2');
is_deeply( $n2, [ [3], [4] ]);

my $n3 = $ep->GetMatrix('N3');
is_deeply( $n3, [ [5], [6] ]);

$ep->Close;

done_testing;
