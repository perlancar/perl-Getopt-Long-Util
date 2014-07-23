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
        {opts=>['help'], normalized=>'help'});
    is_deeply(
        parse_getopt_long_opt_spec('--help|h|?'),
        {opts=>['help', 'h', '?'], normalized=>'h|help|?'});
    is_deeply(
        parse_getopt_long_opt_spec('a|b.c|d#e'),
        {opts=>['a', 'b.c', 'd#e'], normalized=>'a|b.c|d#e'});
    is_deeply(
        parse_getopt_long_opt_spec('name|alias=i'),
        {opts=>['name','alias'], type=>'i', desttype=>'', normalized=>'alias|name=i'});
    is_deeply(
        parse_getopt_long_opt_spec('bool!'),
        {opts=>['bool'], is_neg=>1, normalized=>'bool!'});
    is_deeply(
        parse_getopt_long_opt_spec('inc+'),
        {opts=>['inc'], is_inc=>1, normalized=>'inc+'});
};

subtest humanize_getopt_long_opt_spec => sub {
    is(humanize_getopt_long_opt_spec('help|h|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('h|help|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('foo!'), '--(no)foo');
    is(humanize_getopt_long_opt_spec('foo|f!'), '--(no)foo, -f');
    is(humanize_getopt_long_opt_spec('foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('--foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('foo|bar=s'), '--bar=s, --foo');
};

DONE_TESTING:
done_testing;
