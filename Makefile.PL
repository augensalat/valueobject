use inc::Module::Install;

name     'ValueObject';
all_from 'lib/ValueObject.pm';
author   q{Bernhard Graf <graf@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Carp';
requires 'Scalar::Util';

auto_install;

WriteAll;

