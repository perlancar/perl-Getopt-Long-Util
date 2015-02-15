package Getopt::Long::Util;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       parse_getopt_long_opt_spec
                       humanize_getopt_long_opt_spec
                       detect_getopt_long_script
               );

our %SPEC;

$SPEC{parse_getopt_long_opt_spec} = {
    v => 1.1,
    summary => 'Parse a single Getopt::Long option specification',
    description => <<'_',

Will produce a hash with some keys: `opts` (array of option names, in the order
specified in the opt spec), `type` (string, type name), `desttype` (either '',
or '@' or '%'), `is_neg` (true for `--opt!`), `is_inc` (true for `--opt+`),
`min_vals` (int, usually 0 or 1), `max_vals` (int, usually 0 or 1 except for
option that requires multiple values),

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
            result => {dash_prefix=>'', opts=>['help', 'h', '?'], type=>undef},
        },
        {
            args => {optspec=>'--foo=s'},
            result => {dash_prefix=>'--', opts=>['foo'], type=>'s', min_vals=>1, max_vals=>1},
        },
    ],
};
sub parse_getopt_long_opt_spec {
    my $optspec = shift;
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
        for (split /\|/, $res{aliases}) {
            next unless length;
            next if $_ eq $res{name};
            next if $_ ~~ @als;
            push @als, $_;
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

$SPEC{humanize_getopt_long_opt_spec} = {
    v => 1.1,
    description => <<'_',

Convert `Getopt::Long` option specification like `help|h|?` or `--foo=s` or
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
            description => <<'_',

Either `filename` or `string` must be specified.

_
        },
        string => {
            summary => 'Path to file to be checked',
            schema => 'buf*',
            description => <<'_',

Either `file` or `string` must be specified.

_
        },
        include_noexec => {
            summary => 'Include scripts that do not have +x mode bit set',
            schema  => 'bool*',
            default => 1,
        },
    },
};
sub detect_getopt_long_script {
    my %args = @_;

    (defined($args{filename}) xor defined($args{string}))
        or return [400, "Please specify either filename or string"];
    my $include_noexec  = $args{include_noexec}  // 1;

    my $yesno = 0;
    my $reason = "";

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
        if ($str =~ /^\s*(use|require)\s+Getopt::Long(\s|;)/m) {
            $yesno = 1;
            last DETECT;
        }
        $reason = "Can't find any statement requiring Getopt::Long module";
    } # DETECT

    [200, "OK", $yesno, {"func.reason"=>$reason}];
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
