use strict;
use Test::More tests => 1;
use Test::Exception;

use Wget::Progress qw/wget/;

dies_ok { wget() };
