use inc::Module::Install;
name 'Wget-Progress';
all_from 'lib/Wget/Progress.pm';

requires 'File::Spec';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
