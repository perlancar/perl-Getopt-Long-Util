#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Util qw(
                             parse_getopt_long_opt_spec
                             humanize_getopt_long_opt_spec
                     );
use Test::More 0.98;

# TODO: more extensive tests

subtest parse_getopt_long_opt_spec => sub {
    ok(!parse_getopt_long_opt_spec('?'));
    ok(!parse_getopt_long_opt_spec('a|-b'));

    is_deeply(
        parse_getopt_long_opt_spec('help'),
        {opts=>['help']});
    is_deeply(
        parse_getopt_long_opt_spec('--help|h|?'),
        {opts=>['help', 'h', '?']});
    is_deeply(
        parse_getopt_long_opt_spec('a|b.c|d#e'),
        {opts=>['a', 'b.c', 'd#e']});
    is_deeply(
        parse_getopt_long_opt_spec('name|alias=i'),
        {opts=>['name','alias'], type=>'i', desttype=>''});
    is_deeply(
        parse_getopt_long_opt_spec('bool!'),
        {opts=>['bool'], is_neg=>1});
    is_deeply(
        parse_getopt_long_opt_spec('inc+'),
        {opts=>['inc'], is_inc=>1});
};

subtest humanize_getopt_long_opt_spec => sub {
    is(humanize_getopt_long_opt_spec('help|h|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('h|help|?'), '-h, --help, -?');
    is(humanize_getopt_long_opt_spec('foo!'), '--(no)foo');
    is(humanize_getopt_long_opt_spec('foo|f!'), '--(no)foo, -f');
    is(humanize_getopt_long_opt_spec('foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('--foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('foo|bar=s'), '--foo=s, --bar');
};

DONE_TESTING:
done_testing;
