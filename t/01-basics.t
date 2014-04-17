#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Util qw(
                             humanize_getopt_long_opt_spec
                     );
use Test::More 0.98;

subtest humanize_getopt_long_opt_spec => sub {
    is(humanize_getopt_long_opt_spec('help|h|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('--foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('foo|bar=s'), '--foo=s, --bar=s');
};

DONE_TESTING:
done_testing;
