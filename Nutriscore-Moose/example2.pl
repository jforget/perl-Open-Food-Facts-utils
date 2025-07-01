#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test unitaire de calcul du nutriscore
# Unit test for Nutriscore computation
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use lib qw{ lib ../../openfoodfacts-server/lib/ };
use ProductOpener::Nutriscore2 qw/:all/;
use YAML::XS;

my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
  # Nutrients
  energy =>  518,     # in kJ
  sugars => 3,
  saturated_fat => 0.7,
  saturated_fat_ratio => 0.7 / 3 * 100,
  sodium => 0.61 / 2.5 * 1000,                            # in mg, sodium = salt divided by 2.5
  fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  fiber => 2.2,
  proteins => 6.7,

  # The Nutri-Score computation is different for beverages, waters, cheeses and fats
  is_beverage => 1,
  is_water => 0,
  is_cheese => 0,
  is_fat => 1, # for 2021 version
  is_fat_oil_nuts_seed => 1, # for 2023 version
);

my ($nutriscore_score, $nutriscore_grade) = compute_nutriscore_score_and_grade(
 $nutriscore_data_ref
);

print "Rounded value for sugars: " . $nutriscore_data_ref->sugars_value . "\n";
print "Points for sugars: " . $nutriscore_data_ref->sugars_points . "\n";
print YAML::XS::Dump($nutriscore_data_ref);

=encoding utf8

=head1 NAME

example2.pl -- Unit test for Nutriscore computation

=head1 USAGE

  perl example2.pl

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Jean Forget

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
