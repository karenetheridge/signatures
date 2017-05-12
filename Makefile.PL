use strict;
use warnings;
use lib 'inc';
use ExtUtils::MakeMaker::Dist::Zilla::Develop;

use ExtUtils::Depends 0.302;
my $pkg = ExtUtils::Depends->new(
    'signatures',
    'B::Hooks::OP::Check',
    'B::Hooks::OP::PPAddr',
    'B::Hooks::Parser',
);
$pkg->add_xs('signatures.xs');
$pkg->add_pm('lib/signatures.pm' => '$(INST_LIB)/signatures.pm');

WriteMakefile(
    NAME => 'signatures',
    VERSION_FROM => 'lib/signatures.pm',
    INSTALLMAN1DIR => 'none',
    INSTALLMAN3DIR => 'none',
    NORECURS => 1,
    $pkg->get_makefile_vars,
);
