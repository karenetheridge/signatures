use strict;
use warnings;

package signatures::API;

1;
__END__
=pod

=head1 NAME

signatures::API - underlying implementation for L<signatures>

=head1 METHODS

If you want subroutine signatures doing something that this module doesn't
provide, like argument validation, typechecking and similar, you can subclass
it and override the following methods.

=head2 proto_unwrap ($prototype)

Turns the extracted C<$prototype> into code.

The default implementation returns C<< my (${prototype}) = @_; >> or an empty
string, if no prototype is given.

=head2 inject ($offset, $code)

Inserts a C<$code> string into the line perl currently parses at the given
C<$offset>. This is only called by the C<callback> method.

=head2 callback ($offset, $prototype)

This gets called as soon as a sub definition with a prototype is
encountered. Arguments are the C<$offset> within the current line perl
is parsing and extracted C<$prototype>.

The default implementation calls C<proto_unwrap> with the prototype and passes
the returned value and the offset to C<inject>.

=head1 BUGS

=over 4

=item prototypes aren't checked for validity yet

You won't get a warning for invalid prototypes using the C<proto> attribute,
like you normally would with warnings enabled.

=item you shouldn't alter $SIG{__WARN__} at compile time

After this module is loaded you shouldn't make any changes to C<$SIG{__WARN__}>
during compile time. Changing it before the module is loaded or at runtime is
fine.

=back

=cut
