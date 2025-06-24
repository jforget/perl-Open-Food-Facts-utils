#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test unitaire des contrôles dans la classe NutriscoreData
# Unit test for checks inside class NutriscoreData
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use lib qw{ . ../../openfoodfacts-server/lib/ };
use ProductOpener::Nutriscore2 qw/:all/;
use Test::More;

BEGIN {
  eval "use Test::Exception;";
  if ($@) {
    plan skip_all => "Test::Exception needed";
    exit;
  }
}

plan(tests => 6);

dies_ok {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
} "deliberate error on missing properties 'energy' and 'fiber'";

dies_ok {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518.1,     # in kJ, should be integer
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
} "deliberate value error on 'energy' property";

dies_ok {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518,     # in kJ
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    is_beverage         => 2,                               # boolean = 2 ??!!!
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
} "deliberate value error on 'is_beverage' property";

lives_ok {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518,     # in kJ
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    grade               => 'z',                             # grade beyond 'e' ??!!!
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
} "no error in this version on property 'grade'";


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

dies_ok { $nutriscore_data_ref->sugars_points(3.1)  } "Property 'sugars_points' should be integer";
dies_ok { $nutriscore_data_ref->is_cheese(3) } "Property 'is_cheese' should be boolean";

=encoding utf8

=head1 NAME

02-error.t -- Unit tests for error checks in NutriscoreData class

=head1 USAGE

  prove t2/*.t

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
