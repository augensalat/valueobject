#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Carp 'croak';
use Scalar::Util 'looks_like_number';

# use ValueObject Date => qw(year month day);
use ValueObject JulianDate => qw(year month day);
use ValueObject ACL => qw(r w x path user);

use ValueObject Date => {
    fields   => [qw(year month day)],
    convert  => sub {
        state $montab = {
            jan =>  1, feb =>  2, mar =>  3, apr =>  4, may =>  5, jun =>  6,
            jul =>  7, aug =>  8, sep =>  9, oct => 10, nov => 11, dec => 12,
        };
        my $mon = $_[1];
        return if not defined $mon or $mon =~ /^\d+$/;
        $_[1] = $montab->{lc($mon)}
            or croak q"Date property 'month' must be number of month abbrevation";
    },
    validate => sub {
        state $last_day = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        state $is_leap_year = sub {
            return 0 if $_[0] % 4;
            return 1 if $_[0] % 100;
            return 0 if $_[0] % 400;
            return 1;
        };
        for (@_) {
            defined or croak 'Undefined Date property';
            /\D+/ and croak "Invalid Date property '$_'";
        }
        $_[1] >= 1 && $_[1] <= 12
            or croak "Month '$_[1]' out of range 1..12";
        my $md = $last_day->[$_[1]];
        ++$md if $_[1] == 2 and $is_leap_year->($_[0]);
        croak "Day '$_[2]' out of range 1..$md"
            if $_[2] > $md or $_[2] < 1;
    },
    format   => '%04d-%02d-%02d',
};
use ValueObject Money => {
    fields   => [qw(currency amount)],
    validate => sub {
        looks_like_number $_[0]
            and croak "Invalid currency '$_[0]'";
        looks_like_number $_[1]
            or croak "Amount '$_[1]' is not numeric";
    },
    format => sub { join('', @_) },
    # in an ideal world all currencies are equal
    '<=>' => sub { $_[0]->amount <=> $_[1]->amount },
};

my $balance1 = Money('$', 1000.01);
my $balance2 = Money('€', 1000.01);
my $acl = ACL(qw(1 0 0 root/public doe));

my $date1 = Date(2000, 'Feb', 29);
my $date2 = JulianDate(2011, 11, 29);
my $obj = bless [42], 'The::Answer';
my $ref = {answer => 42};
my $val = 42;

# say $date1 != $val ? "equal" : "not equal";
say $balance1 == $balance2 ? "equal" : "not equal";


say $date1->day, '.', $date1->month, '.', $date1->year;
say $balance1;
say $balance2;
say $balance2->currency . $balance2->amount;
say $acl;
say $date1;
