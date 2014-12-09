package Getopt::Long::Util;

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

# DATE
# VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       parse_getopt_long_opt_spec
                       humanize_getopt_long_opt_spec
               );

sub parse_getopt_long_opt_spec {
    my $optspec = shift;
    $optspec =~ qr/\A
               (?:--)?
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

#ABSTRACT: Utilities for Getopt::Long

=head1 FUNCTIONS

=head2 parse_getopt_long_opt_spec($str) => hash

Parse Getopt::Long option specification. Will produce a hash with some keys:
C<opts> (array of option names, in the order specified in the opt spec), C<type>
(string, type name), C<desttype> (either '', or '@' or '%'), C<is_neg> (true for
C<--opt!>), C<is_inc> (true for C<--opt+>), C<min_vals> (int, usually 0 or 1),
C<max_vals> (int, usually 0 or 1 except for option that requires multiple
values),

Will return undef if it can't parse C<$str>.

Examples:

 $res = parse_getopt_long_opt_spec('help|h|?'); # {opts=>['help', 'h', '?'], type=>undef}
 $res = parse_getopt_long_opt_spec('--foo=s');  # {opts=>['foo'], type=>'s', min_vals=>1, max_vals=>1}

=head2 humanize_getopt_long_opt_spec($str) => str

Convert L<Getopt::Long> option specification like C<help|h|?> or <--foo=s> or
C<debug!> into, respectively, C<--help, -h, -?> or C<--foo=s> or C<--(no)debug>.
Will die if can't parse C<$str>. The output is suitable for including in
help/usage text.

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
