use strict;
use Test::More tests => 5;
use Test::Exception;

use Wget::Progress;

my $wget = Wget::Progress->new;

isa_ok $wget, 'Wget::Progress';

# agent
ok $wget->agent('hoge agent');
is $wget->agent, 'hoge agent';

dies_ok { $wget->get() };
dies_ok { $wget->get('http://example.com/big.iso') or die $wget->error };
