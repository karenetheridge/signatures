use strict;
use warnings;
package # hide from PAUSE
    inc::ExtUtilsDepends;

use Moose;
with
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::InstallTool',
;
use List::Util 'first';

sub register_prereqs {
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            phase => $_,
            type  => 'requires',
        },
        # minimum version that works on Win32+gcc
        'ExtUtils::Depends' => '0.302',
        'B::Hooks::OP::Check' => '0.17',
        # minimum version that depends on ExtUtils::Depends 0.302
        'B::Hooks::OP::PPAddr' => '0.03',
        # minimum version that depends on ExtUtils::Depends 0.302
        'B::Hooks::Parser' => '0.12',
    # this is a workaround for a bug in [MakeMaker], where configure requires
    # prereqs are not added to the fallback hash
    ) foreach qw(configure build);
}

sub setup_installer {
    my $self = shift;

    my $file = first { $_->name eq 'Makefile.PL' } @{$self->zilla->files};
    $self->log_fatal('No Makefile.PL found!') if not $file;

    my $extra_content = <<'CONTENT';
use ExtUtils::Depends 0.302;
my $pkg = ExtUtils::Depends->new(
    'signatures',
    'B::Hooks::OP::Check',
    'B::Hooks::OP::PPAddr',
    'B::Hooks::Parser',
);
$pkg->add_xs('signatures.xs');
$pkg->add_pm('lib/signatures.pm' => '$(INST_LIB)/signatures.pm');
%WriteMakefileArgs = ( %WriteMakefileArgs, $pkg->get_makefile_vars );
CONTENT

    my $content = $file->content;
    $self->log_debug('Inserting extra content into Makefile.PL...');

    # this is a vicious hack -- maybe someday [MakeMaker::Awesome] will give
    # us a hook to add this content into the right spot.
    $self->log_fatal('failed to find position in Makefile.PL to munge!')
        if $content !~ m'^my %WriteMakefileArgs = \(\n(?:[^;]+)^\);$'mg;

    my $pos = pos($content);

    $content = substr($content, 0, $pos)
        . "\n\n"
        . $extra_content
        . "\n" . substr($content, $pos, -1);

    $file->content($content);
    return;
}

1;
