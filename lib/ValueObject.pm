package ValueObject;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util qw(blessed looks_like_number);

use overload
    '<=>' => '__UFO__',
    'cmp' => '__CMP__',
    '""' => '__FORMAT__',
    fallback => 1;

our $VERSION = '0.001';

my $PREFIX = __PACKAGE__ . '::';
my $PREFIXL = length $PREFIX;

my $IDENTIFY = sub {
    my $ref = ref $_[0] or return qq'"$_[0]"';

    blessed $_[0] ?
        index($ref, $PREFIX) == 0 ?
            substr($ref, $PREFIXL) . ' ValueObject' :
            $ref . ' object' :
                $ref . ' reference';
};

my $TYPE_CHECK = sub {
    my $code = shift;
    my ($self, $other) = @_;

    ref($self) eq ref($other)
        or croak 'Cannot compare ' . $IDENTIFY->($self) . ' and ' . $IDENTIFY->($other);

    $code->(@_);
};

my $METHOD_NAME = sub {
    for ($_[0]) {
        croak 'ValueObject requires a name' unless defined;
        croak 'Invalid ValueObject name' if ref or not /^[A-Za-z]\w*$/;
        return $_;
    }
};

my $UFO = sub {
    my ($self, $other, $args) = @_;
    my $cmp;

    no warnings 'uninitialized';

    for (0 .. $#$self) {
        if (looks_like_number $self->[$_] and looks_like_number $other->[$_]) {
            $cmp = $self->[$_] <=> $other->[$_] and return $cmp;
        }
        else {
            $cmp = $self->[$_] cmp $other->[$_]
                and croak 'Cannot compare ' . $IDENTIFY->($self) .
                        's with different ' . $args->[$_] . ' properties';
        }
    }

    return $cmp;
};

my $CMP = sub {
    no warnings 'uninitialized';

    return join("\0", @{$_[0]}) cmp join("\0", @{$_[1]});
};

my $FORMAT = sub { no warnings 'uninitialized'; "@{$_[0]}" };

sub import {
    ref shift
        and croak 'import() is a private ValueObject function';
    my $name = $METHOD_NAME->(shift);

    croak 'ValueObject without properties' unless @_;

    my ($fields, $format, %coderef);

    if (ref($_[0]) eq 'HASH') {
        my $args = shift;

        ref($fields = $args->{fields}) eq 'ARRAY'
            or croak 'ValueObject without properties';

        for (qw(convert validate <=> cmp)) {
            $coderef{$_} = $args->{$_};
            croak "ValueObject attribute '$_' must be a CODE ref"
                if defined $coderef{$_} and ref $coderef{$_} ne 'CODE';
        }

        my $f = $args->{format};
        if (defined $f) {
            my $fref = ref $f;
            if ($fref eq '') {
                $format = sub {
                    no warnings 'uninitialized';
                    sprintf $f, @{$_[0]};
                };
            }
            elsif ($fref eq 'CODE') {
                $format = sub { $f->(@{$_[0]}) };
            }
            else {
                croak q"ValueObject attribute 'format' must be a CODE ref or a string";
            }
        }
        else {
            $format = $FORMAT;
        }
    }
    else {
        $fields = \@_;
        $format = $FORMAT;
    }


    my $caller = caller;
    my %subs;

    $coderef{'<=>'} ||= $UFO;
    $coderef{'cmp'} ||= $CMP;

    for (0 .. $#$fields) {
        my $idx = $_;
        $subs{$fields->[$idx]} = sub {shift->[$idx]};
    }

    my $pkg = join('::', __PACKAGE__, $caller, $name);

    no strict 'refs';

    *{$pkg . '::' . $_} = $subs{$_} for keys %subs;
    *{$pkg . '::__UFO__'} = sub { $TYPE_CHECK->($coderef{'<=>'}, @_[0, 1], $fields) };
    *{$pkg . '::__CMP__'} = sub { $TYPE_CHECK->($coderef{'cmp'}, @_[0, 1], $fields) };
    *{$pkg . '::__FORMAT__'} = $format;
    @{$pkg . '::ISA'} = __PACKAGE__;
    *{$caller . '::' . $name} = sub {
        croak "ValueObject '$name' has wrong number of properties"
            if @_ != @$fields;
        local $Carp::CarpLevel;
        $Carp::CarpLevel++;
        my $fields = [@_];
        $coderef{convert} and $coderef{convert}->(@$fields);
        $coderef{validate} and $coderef{validate}->(@$fields);
        bless $fields, $pkg;
    };
}

1;

__END__

=head1 NAME

ValueObject - Half-Baked Value Objects

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

  use ValueObject Money => qw(currency amount);
  my $balance = Money('$', 100);
  printf "Balance is %s %d\n", $p->currency, $p->amount;

=head1 ACKNOWLEDGEMENTS

L<http://c2.com/cgi/wiki?ValueObject>,
L<Class::Value>,
L<http://leonerds-code.blogspot.com/2011/11/perl-tiny-lightweight-structures-module.html>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

