package Getopt::Long::Util;

use 5.010;
use strict;
use warnings;

# VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       humanize_getopt_long_opt_spec
                       gospec2human
               );

# old name, kept for backward-compat
sub gospec2human { goto &humanize_getopt_long_opt_spec }

sub humanize_getopt_long_opt_spec {
    my $optspec = shift;

    $optspec =~ s/\A--?//;

    my $type = 'flag';
    if ($optspec =~ s/!$//) {
        $type = 'bool';
    } elsif ($optspec =~ s/(=\w)$//) {
        $type = $1;
    } elsif ($optspec =~ s/\+$//) {
        # also a flag, increment by one like --more --more --more
    } elsif ($optspec !~ /[A-Za-z0-9?]\z/) {
        die "Sorry, can't parse opt spec '$optspec' yet (probably invalid?)";
    }

    my $res = "";
    for (split /\|/, $optspec) {
        $res .= ", " if length($res);
        s/^--?//;
        if ($type eq 'bool') {
            $res .= "--(no)$_";
        } else {
            if (length($_) > 1) {
                $res .= "--$_" . ($type =~ /^=/ ? $type : "");
            } else {
                $res .= "-$_" . ($type =~ /^=/ ? $type : "");
            }
        }
    }
    $res;
}

#ABSTRACT: Utilities for Getopt::Long

=head1 FUNCTIONS

=head2 humanize_getopt_long_opt_spec($gospec) => STR

Convert Getopt::Long option specification like C<help|h|?> or <--foo=s> or
C<debug!> into, respectively, C<--help, -h, -?> or C<--foo=s> or C<--(no)debug>.
The output is suitable for including in help/usage text.


=head1 SEE ALSO

L<Getopt::Long>

=cut
