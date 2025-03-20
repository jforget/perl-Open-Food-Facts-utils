#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Compte les documents contenant une propriété 'packaging_material_tags' ou approchant
# Count the OFF documents which contain a 'packaging_material_tags' property or similar
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
use Getopt::Long;

my $full  = "$ENV{HOME}/Téléchargements/openfoodfacts-products.jsonl";
my $f324  = "$ENV{HOME}/Documents/prog/perl/perl-Open-Food-Facts-utils/schema-check/examples/products-324.json";
my $select_full = 0;
my $detail      = 1; # to print each product ID with some data within the properties
GetOptions("full" => \$select_full)
    or die "Problem in the options";
my $fname;
if ($select_full) {
  $fname  = $full;
  $detail = 0;
}
else {
  $fname  = $f324;
  $detail = 1;
}


my @prop = qw /packaging_materials_tags packaging_recycling_tags packaging_shapes_tags packagings_materials/;
my %ctr;
my %ctr1;

my $json_parser = JSON::XS->new;

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
for my $prop (@prop) {
  printf("%8d %8d %s\n", $ctr{$prop}, $ctr1{$prop}, $prop);
}

sub check {
  my ($l) = @_;
  my @prop_with_data = ();
  my $rec = $json_parser->decode($l);
  for my $prop (@prop) {
    if ($rec->{$prop}) {
       ++$ctr{$prop};
      if (ref($rec->{$prop}) eq 'ARRAY' && 0 != @{$rec->{$prop}}) {
         ++$ctr1{$prop};
         push @prop_with_data, $prop;
      }
      if (ref($rec->{$prop}) eq 'HASH' && 0 != keys %{$rec->{$prop}}) {
         ++$ctr1{$prop};
         push @prop_with_data, $prop;
      }
    }
  }
  if ($detail && @prop_with_data) {
    say join ' ', sprintf("%-20s", $rec->{_id}), @prop_with_data;
  }
}

=encoding utf8

=head1 NAME

find-packaging.pl -- count documents which contain a 'packaging_.*' property

=head1 VERSION

Version 0.01

=head1 USAGE

  perl find-packaging.pl

=head1 ARGUMENTS

None.

=head1 OPTIONS

C<--full> :  select the  full JSONL  file with  about 5  million lines
instead of the shorter 324-line file.

=head1 DESCRIPTION

The program reads  a JSONL file containing Open  Food Facts documents,
one  per line.  For  each  document, the  program  checks whether  the
following properties exist:

=over 4

=item * packaging_materials_tags

=item * packaging_recycling_tags

=item * packaging_shapes_tags

=item * packagings_materials

=back

The UTC time and the line counter are displayed every 100_000 lines.

=head2 Results

The first  number is the number  of lines where the  property appears,
either as an empty array or as an array with values. The second number
is the number of lines where the  property appears as an array with at
least one value.

On 2025-03-20 (file from 2025-03-11):

Input  3_742_774 lines, 58_835_864_432 bytes

  3718837   323828 packaging_materials_tags
  3718837    59083 packaging_recycling_tags
  3718837   277337 packaging_shapes_tags
  3718656   381352 packagings_materials

duration   about 14 minutes

=head1 CONFIGURATION AND ENVIRONMENT

The input filenames are hard-coded in the program source file.

=head1 DEPENDENCIES

This Perl program requires Perl 5.10 or greater.

Modules used (outside the core):

=over 4

=item * C<DateTime>

=item * C<JSON::XS>

=back

=head1 BUGS AND LIMITATIONS

The input filenames are hard-coded in the program source file.

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Jean Forget

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
