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
    is_deeply(
        parse_getopt_long_opt_spec('help'),
        {opts=>['help'], normalized=>'help'});
    is_deeply(
        parse_getopt_long_opt_spec('--help|h|?'),
        {opts=>['help', 'h', '?'], normalized=>'?|h|help'});
    is_deeply(
        parse_getopt_long_opt_spec('name|alias=i'),
        {opts=>['name','alias'], type=>'i', desttype=>'', normalized=>'alias|name=i'});
};

subtest humanize_getopt_long_opt_spec => sub {
    is(humanize_getopt_long_opt_spec('help|h|?'), '--help, -h, -?');
    is(humanize_getopt_long_opt_spec('foo!'), '--(no)foo');
    is(humanize_getopt_long_opt_spec('foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('--foo=s'), '--foo=s');
    is(humanize_getopt_long_opt_spec('foo|bar=s'), '--foo=s, --bar');
};

DONE_TESTING:
done_testing;
