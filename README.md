# NAME

signatures - Subroutine signatures with no source filter

# VERSION

version 0.09

# SYNOPSIS

    use signatures;

    sub foo ($bar, $baz) {
        return $bar + $baz;
    }

# DESCRIPTION

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
module are not to be confused with the prototypes described in [perlsub](https://metacpan.org/pod/perlsub). All
this module does is extracting items of @\_ and assigning them to the variables
in the parameter list. No argument validation is done at runtime.

The signature definition needs to be on a single line only.

If you want to combine sub signatures with regular prototypes a `proto`
attribute exists:

    sub foo ($bar, $baz) : proto($$) { ... }

# METHODS

If you want subroutine signatures doing something that this module doesn't
provide, like argument validation, typechecking and similar, you can subclass
it and override the following methods.

## proto\_unwrap ($prototype)

Turns the extracted `$prototype` into code.

The default implementation returns `my (${prototype}) = @_;` or an empty
string, if no prototype is given.

## inject ($offset, $code)

Inserts a `$code` string into the line perl currently parses at the given
`$offset`. This is only called by the `callback` method.

## callback ($offset, $prototype)

This gets called as soon as a sub definition with a prototype is
encountered. Arguments are the `$offset` within the current line perl
is parsing and extracted `$prototype`.

The default implementation calls `proto_unwrap` with the prototype and passes
the returned value and the offset to `inject`.

# BUGS

- prototypes aren't checked for validity yet

    You won't get a warning for invalid prototypes using the `proto` attribute,
    like you normally would with warnings enabled.

- you shouldn't alter $SIG{\_\_WARN\_\_} at compile time

    After this module is loaded you shouldn't make any changes to `$SIG{__WARN__}`
    during compile time. Changing it before the module is loaded or at runtime is
    fine.

# SEE ALSO

[Method::Signatures](https://metacpan.org/pod/Method::Signatures)

[MooseX::Method::Signatures](https://metacpan.org/pod/MooseX::Method::Signatures)

[Sub::Signatures](https://metacpan.org/pod/Sub::Signatures)

[Attribute::Signature](https://metacpan.org/pod/Attribute::Signature)

[Perl6::Subs](https://metacpan.org/pod/Perl6::Subs)

[Perl6::Parameters](https://metacpan.org/pod/Perl6::Parameters)

# THANKS

Moritz Lenz and Steffen Schwigon for documentation review and
improvement.

# AUTHOR

Florian Ragwitz <rafl@debian.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

- Alex Kapranoff <alex@kapranoff.ru>
- Alexandr Ciornii <alexchorny@gmail.com>
- Karen Etheridge <ether@cpan.org>
- Peter Martini <PeterCMartini@GMail.com>
- Steffen Schwigon <ss5@renormalist.net>
