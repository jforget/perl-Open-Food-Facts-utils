#!/usr/bin/env perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Compte les documents avec un attribut 'last_updated_t' et ceux avec un attribut 'last_modified_t'
# Count how many documents have a 'last_updated_t' attribute and how many have 'last_modified_t'
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.10;
use strict;
use warnings;
use JSON::XS;
use DateTime;

my $fname = "$ENV{HOME}/Téléchargements/openfoodfacts-products.jsonl";
#my $fname = "$ENV{HOME}/Documents/prog/perl/perl-Open-Food-Facts-utils/schema-check/examples/products-324.json";

my $json_parser = JSON::XS->new;

my $nb_mod  = 0;
my $nb_upd  = 0;
my $nb_both = 0;
my $nb_diff = 0;

say "# ", DateTime->now,  ", starting";
my $nb = 0;
my $threshold = 100_000;
open my $fh, '<', $fname
  or die "opening $fname $!";
while (my $l = <$fh>) {
  check($l);
  ++$nb;
  if ($nb % $threshold == 0) {
    say "# ", DateTime->now,  ", lines read: $nb ";
  }
}
close $fh
  or die "closing $fname $!";
say "# ", DateTime->now,  ", lines read: $nb ";

sub check {
  my ($l) = @_;
  my $rec = $json_parser->decode($l);
  if ($rec->{last_updated_t}) {
    if ($rec->{last_modified_t}) {
      ++$nb_both;
      if ($rec->{last_updated_t} ne $rec->{last_modified_t}) {
        ++$nb_diff;
      }
    }
    else {
      ++$nb_upd;
    }
  }
  elsif ($rec->{last_modified_t}) {
     ++$nb_mod;
  }
}
say "$nb_mod with 'last_modified_t' only";
say "$nb_upd with 'last_updated_t' only";
say "$nb_both with both of them";
say "including $nb_diff with different values";

=encoding utf8

=head1 NAME

updated-or-modified.pl -- count the 'last_updated_t' and 'last_modified_t' properties

=head1 VERSION

Version 0.01

=head1 USAGE

  perl updated-or-modified.pl

=head1 ARGUMENTS

None.

=head1 OPTIONS

None.

=head1 DESCRIPTION

According   to   the   data   schema,   each   document   contains   a
C<last_modified_t>   property.   Yet,   some   documents   contain   a
C<last_updated_t> property. The program counts how many documents have
each of these two properties.

The UTC time and the line counter are displayed every 100_000 lines.

=head2 Results

On 2025-03-11:

  Input  3_742_774 lines, 58_835_864_432 bytes
  result
      78 with 'last_modified_t' only
      0 with 'last_updated_t' only
      3742695 with both of them
  duration   about 16 minutes

Actually, this is a feature referenced in
L<CHANGELOG.md|https://github.com/openfoodfacts/openfoodfacts-server/blob/main/CHANGELOG.md>,
L<tag 2.26.0|https://github.com/openfoodfacts/openfoodfacts-server/compare/v2.25.0...v2.26.0>,
L<pull request 9846|https://github.com/openfoodfacts/openfoodfacts-server/pull/9646>,

=head1 CONFIGURATION AND ENVIRONMENT

The input filename is hard-coded in the program source file.

=head1 DEPENDENCIES

This Perl program requires Perl 5.10 or greater.

Modules used (outside the core):

=over 4

=item * C<DateTime>

=item * C<JSON::XS>

=back

=head1 BUGS AND LIMITATIONS

The input filename is hard-coded in the program source file.

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Jean Forget

This program is  free software: you can redistribute  it and/or modify
it  under the  terms  of  the GNU  Affero  General  Public License  as
published by  the Free  Software Foundation, either  version 3  of the
License, or (at your option) any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR  A PARTICULAR  PURPOSE.  See the  GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
