package Getopt::Long::Util;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       parse_getopt_long_opt_spec
                       humanize_getopt_long_opt_spec
                       detect_getopt_long_script
                       gen_getopt_long_spec_from_getopt_std_spec
               );

our %SPEC;

$SPEC{parse_getopt_long_opt_spec} = {
    v => 1.1,
    summary => 'Parse a single Getopt::Long option specification',
    description => <<'_',

Will produce a hash with some keys:

* `is_arg` (if true, then option specification is the special `<>` for argument
  callback)
* `opts` (array of option names, in the order specified in the opt spec)
* `type` (string, type name)
* `desttype` (either '', or '@' or '%'),
* `is_neg` (true for `--opt!`)
* `is_inc` (true for `--opt+`)
* `min_vals` (int, usually 0 or 1)
* `max_vals` (int, usually 0 or 1 except for option that requires multiple
  values)

Will return undef if it can't parse the string.

_
    args => {
        optspec => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
    result => {
        schema => 'hash*',
    },
    examples => [
        {
            args => {optspec => 'help|h|?'},
            result => {dash_prefix=>'', opts=>['help', 'h', '?']},
        },
        {
            args => {optspec=>'--foo=s'},
            result => {dash_prefix=>'--', opts=>['foo'], type=>'s', desttype=>''},
        },
    ],
};
# BEGIN_BLOCK: parse_getopt_long_opt_spec
sub parse_getopt_long_opt_spec {
    my $optspec = shift;
    return {is_arg=>1, dash_prefix=>'', opts=>[]}
        if $optspec eq '<>';
    $optspec =~ qr/\A
               (?P<dash_prefix>-{0,2})
               (?P<name>[A-Za-z0-9_][A-Za-z0-9_-]*)
               (?P<aliases> (?: \| (?:[^:|!+=:-][^:|!+=:]*) )*)?
               (?:
                   (?P<is_neg>!) |
                   (?P<is_inc>\+) |
                   (?:
                       =
                       (?P<type>[siof])
                       (?P<desttype>|[%@])?
                       (?:
                           \{
                           (?: (?P<min_vals>\d+), )?
                           (?P<max_vals>\d+)
                           \}
                       )?
                   ) |
                   (?:
                       :
                       (?P<opttype>[siof])
                       (?P<desttype>|[%@])
                   ) |
                   (?:
                       :
                       (?P<optnum>\d+)
                       (?P<desttype>|[%@])
                   )
                   (?:
                       :
                       (?P<optplus>\+)
                       (?P<desttype>|[%@])
                   )
               )?
               \z/x
                   or return undef;
    my %res = %+;

    if ($res{aliases}) {
        my @als;
        for my $al (split /\|/, $res{aliases}) {
            next unless length $al;
            next if $al eq $res{name};
            next if grep {$_ eq $al} @als;
            push @als, $al;
        }
        $res{opts} = [$res{name}, @als];
    } else {
        $res{opts} = [$res{name}];
    }
    delete $res{name};
    delete $res{aliases};

    $res{is_neg} = 1 if $res{is_neg};
    $res{is_inc} = 1 if $res{is_inc};

    \%res;
}
# END_BLOCK: parse_getopt_long_opt_spec

$SPEC{humanize_getopt_long_opt_spec} = {
    v => 1.1,
    description => <<'_',

Convert <pm:Getopt::Long> option specification like `help|h|?` or `--foo=s` or
`debug!` into, respectively, `--help, -h, -?` or `--foo=s` or `--(no)debug`.
Will die if can't parse the string. The output is suitable for including in
help/usage text.

_
    args => {
        optspec => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
    result => {
        schema => 'str*',
    },
};
sub humanize_getopt_long_opt_spec {
    my $optspec = shift;

    my $parse = parse_getopt_long_opt_spec($optspec)
        or die "Can't parse opt spec $optspec";

    return "argument" if $parse->{is_arg};

    my $res = '';
    my $i = 0;
    for (@{ $parse->{opts} }) {
        $i++;
        $res .= ", " if length($res);
        if ($parse->{is_neg} && length($_) > 1) {
            $res .= "--(no)$_";
        } else {
            if (length($_) > 1) {
                $res .= "--$_";
            } else {
                $res .= "-$_";
            }
            $res .= "=$parse->{type}" if $i==1 && $parse->{type};
        }
    }
    $res;
}

$SPEC{detect_getopt_long_script} = {
    v => 1.1,
    summary => 'Detect whether a file is a Getopt::Long-based CLI script',
    description => <<'_',

The criteria are:

* the file must exist and readable;

* (optional, if `include_noexec` is false) file must have its executable mode
  bit set;

* content must start with a shebang C<#!>;

* either: must be perl script (shebang line contains 'perl') and must contain
  something like `use Getopt::Long`;

_
    args => {
        filename => {
            summary => 'Path to file to be checked',
            schema => 'str*',
            pos => 0,
            cmdline_aliases => {f=>{}},
        },
        string => {
            summary => 'String to be checked',
            schema => 'buf*',
        },
        include_noexec => {
            summary => 'Include scripts that do not have +x mode bit set',
            schema  => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        'req_one' => ['filename', 'string'],
    },
};
sub detect_getopt_long_script {
    my %args = @_;

    (defined($args{filename}) xor defined($args{string}))
        or return [400, "Please specify either filename or string"];
    my $include_noexec  = $args{include_noexec}  // 1;

    my $yesno = 0;
    my $reason = "";
    my %extrameta;

    my $str = $args{string};
  DETECT:
    {
        if (defined $args{filename}) {
            my $fn = $args{filename};
            unless (-f $fn) {
                $reason = "'$fn' is not a file";
                last;
            };
            if (!$include_noexec && !(-x _)) {
                $reason = "'$fn' is not an executable";
                last;
            }
            my $fh;
            unless (open $fh, "<", $fn) {
                $reason = "Can't be read";
                last;
            }
            # for efficiency, we read a bit only here
            read $fh, $str, 2;
            unless ($str eq '#!') {
                $reason = "Does not start with a shebang (#!) sequence";
                last;
            }
            my $shebang = <$fh>;
            unless ($shebang =~ /perl/) {
                $reason = "Does not have 'perl' in the shebang line";
                last;
            }
            seek $fh, 0, 0;
            {
                local $/;
                $str = <$fh>;
            }
        }
        unless ($str =~ /\A#!/) {
            $reason = "Does not start with a shebang (#!) sequence";
            last;
        }
        unless ($str =~ /\A#!.*perl/) {
            $reason = "Does not have 'perl' in the shebang line";
            last;
        }

        # NOTE: the presence of \s* pattern after ^ causes massive slowdown of
        # the regex when we reach many thousands of lines, so we use split()

        #if ($str =~ /^\s*(use|require)\s+(Getopt::Long(?:::Complete)?)(\s|;)/m) {
        #    $yesno = 1;
        #    $extrameta{'func.module'} = $2;
        #    last DETECT;
        #}

        for (split /^/, $str) {
            if (/^\s*(use|require)\s+(Getopt::Long(?:::Complete)?)(\s|;|$)/) {
                $yesno = 1;
                $extrameta{'func.module'} = $2;
                last DETECT;
            }
        }

        $reason = "Can't find any statement requiring Getopt::Long(?::Complete)? module";
    } # DETECT

    [200, "OK", $yesno, {"func.reason"=>$reason, %extrameta}];
}

$SPEC{gen_getopt_long_spec_from_getopt_std_spec} = {
    v => 1.1,
    summary => 'Generate Getopt::Long spec from Getopt::Std spec',
    args => {
        spec => {
            summary => 'Getopt::Std spec string',
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        is_getopt => {
            summary => 'Whether to assume spec is for getopt() or getopts()',
            description => <<'_',

By default spec is assumed to be for getopts() instead of getopt(). This means
that for a spec like `abc:`, `a` and `b` don't take argument while `c` does. But
if `is_getopt` is true, the meaning of `:` is reversed: `a` and `b` take
arguments while `c` doesn't.

_
            schema => 'bool',
        },
    },
    result_naked => 1,
    result => {
        schema => 'hash*',
    },
};
sub gen_getopt_long_spec_from_getopt_std_spec {
    my %args = @_;

    my $is_getopt = $args{is_getopt};
    my $spec = {};

    while ($args{spec} =~ /(.)(:?)/g) {
        $spec->{$1 . ($is_getopt ? ($2 ? "" : "=s") : ($2 ? "=s" : ""))} =
            sub {};
    }

    $spec;
}

#ABSTRACT: Utilities for Getopt::Long

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::Long::Spec>, which can also parse Getopt::Long spec into hash as well
as transform back the hash to Getopt::Long spec. OO interface. I should've found
this module first before writing my own C<parse_getopt_long_opt_spec()>. But at
least currently C<parse_getopt_long_opt_spec()> is at least about 30-100+%
faster than Getopt::Long::Spec::Parser, has a much simpler implementation (a
single regex match), and can handle valid Getopt::Long specs that
Getopt::Long::Spec::Parser fails to parse, e.g. C<foo|f=s@>.

=cut
