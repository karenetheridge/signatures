use strict;
use warnings;

package signatures;

use XSLoader;
use B::Hooks::Parser;
use B::Hooks::OP::Check;
use B::Hooks::OP::PPAddr;
use B::Hooks::EndOfScope;

our $VERSION = '0.07';

XSLoader::load(__PACKAGE__, $VERSION);

{
    my %pkgs;

    sub import {
        my ($class) = @_;
        my $caller = caller();
        $pkgs{$caller} = $class->setup_for($caller);
        return;
    }

    sub unimport {
        my ($class) = @_;
        my $caller = caller();
        $class->teardown_for(delete $pkgs{$caller});
        return;
    }
}

sub setup_for {
    my ($class, $caller) = @_;
    my $ret = $class->setup($caller);

    $^H{"${class}::enabled"} = 1;

    my $old_warn = $SIG{__WARN__};
    $SIG{__WARN__} = sub {
        if ($_[0] !~ /^(?:(?:Illegal character in prototype)|(?:Prototype after '.')) for /) {
            $old_warn ? $old_warn->(@_) : warn @_;
        }
    };

    my $unregister;
    {
        my $called = 0;
        $unregister = sub {
            return if $called++;
            $class->teardown_for([$ret, $unregister]);
            $SIG{__WARN__} = $old_warn;
        };
    }

    &on_scope_end($unregister);

    return [$ret, $unregister];
}

sub teardown_for {
    my ($class, $data) = @_;
    delete $^H{"${class}::enabled"};
    $class->teardown($data->[0]);
    $data->[1]->();
    return;
}

sub callback {
    my ($class, $offset, $proto) = @_;
    my $inject = $class->proto_unwrap($proto);
    $class->inject($offset, $inject);
    return;
}

sub proto_unwrap {
    my ($class, $proto) = @_;
    return '' unless length $proto;
    return "my ($proto) = \@_;";
}

sub inject {
    my ($class, $offset, $inject) = @_;
    my $linestr = B::Hooks::Parser::get_linestr();
    substr($linestr, $offset + 1, 0) = $inject;
    B::Hooks::Parser::set_linestr($linestr);
    return;
}

1;
__END__
=pod

=head1 NAME

signatures - subroutine signatures with no source filter

=head1 SYNOPSIS

    use signatures;

    sub foo ($bar, $baz) {
        return $bar + $baz;
    }

=head1 DESCRIPTION

With this module, we can specify subroutine signatures and have variables
automatically defined within the subroutine.

For example, you can write

    sub square ($num) {
        return $num * $num;
    }

and it will be automatically turned into the following at compile time:

    sub square {
        my ($num) = @_;
        return $num * $num;
    }

Note that, although the syntax is very similar, the signatures provided by this
module are not to be confused with the prototypes described in L<perlsub>. All
this module does is extracting items of @_ and assigning them to the variables
in the parameter list. No argument validation is done at runtime.

The signature definition needs to be on a single line only.

If you want to combine sub signatures with regular prototypes a C<proto>
attribute exists:

    sub foo ($bar, $baz) : proto($$) { ... }

=head1 API

See L<signatures::API> for the underlying interfaces, e.g. if you want to
alter some default behaviour.

B<ACHTUNG!> The underlying implementation will be soon changing. When this
occurs, the previous implementation will still be available through a separate
namespace (perhaps C<signatures::Classic>, to be determined).  For more
information, please see this thread:
L<http://www.nntp.perl.org/group/perl.perl5.porters/2013/02/msg198382.html>

=head1 BUGS

See L<signatures::API/BUGS>.

=head1 SEE ALSO

L<Method::Signatures>

L<MooseX::Method::Signatures>

L<Sub::Signatures>

L<Attribute::Signature>

L<Perl6::Subs>

L<Perl6::Parameters>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 THANKS

Moritz Lenz and Steffen Schwigon for documentation review and
improvement.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  Florian Ragwitz

This module is free software.

You may distribute it under the same license as Perl itself.

=cut
