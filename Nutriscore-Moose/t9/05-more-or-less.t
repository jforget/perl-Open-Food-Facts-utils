#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test de l'intégration de NutriscoreData avec Nutriscore
# Testing the integration of NutriscoreData with Nutriscore
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
use ProductOpener::Nutriscore0;
use ProductOpener::Nutriscore9;
use ProductOpener::NutriscoreData9;
use Test::More;

my @test_2021 = test_data_2021();
my @test_2023 = test_data_2023();
my @nutrient_2021 = qw/ energy sugars saturated_fat                           saturated_fat_ratio sodium fruits_vegetables_nuts_colza_walnut_olive_oils fiber proteins /;
my @nutrient_2023 = qw/ energy sugars saturated_fat energy_from_saturated_fat saturated_fat_ratio salt   fruits_vegetables_legumes                      fiber proteins /;

plan(tests => 2 * @nutrient_2021 * @test_2021 + 2 * @nutrient_2023 * @test_2023);

for my $nutriscore_data_ref_old (@test_2021) {
  for my $nutrient (@nutrient_2021) {
    $nutriscore_data_ref_old->{$nutrient . "_value"} //= $nutriscore_data_ref_old->{$nutrient} // 0;
  }
  my $nutriscore_data_ref_new = ProductOpener::NutriscoreData9->new( %$nutriscore_data_ref_old );
  for my $nutrient (@nutrient_2021) {
    if (defined $nutriscore_data_ref_old->{$nutrient}) {
      my $ref  = ProductOpener::Nutriscore0::get_value_with_one_less_negative_point_2021 ($nutriscore_data_ref_old, $nutrient);
      my $test = ProductOpener::Nutriscore9::get_value_with_one_less_negative_point_2021 ($nutriscore_data_ref_new, $nutrient);
      is($test, $ref, "2021 negative point on $nutrient");
      $ref  = ProductOpener::Nutriscore0::get_value_with_one_more_positive_point_2021 ($nutriscore_data_ref_old, $nutrient);
      $test = ProductOpener::Nutriscore9::get_value_with_one_more_positive_point_2021 ($nutriscore_data_ref_new, $nutrient);
      is($test, $ref, "2021 positive point on $nutrient");
    }
    else {
      ok(1, "2021 negative $nutrient SKIPPED, missing value");
      ok(1, "2021 positive $nutrient SKIPPED, missing value");
    }
  }
}

for my $nutriscore_data_ref_old (@test_2023) {
  my $nutriscore_data_ref_new = ProductOpener::NutriscoreData9->new( %$nutriscore_data_ref_old );
  for my $nutrient (@nutrient_2023) {
    if (defined $nutriscore_data_ref_old->{$nutrient}) {
      my $ref  = ProductOpener::Nutriscore0::get_value_with_one_less_negative_point_2023 ($nutriscore_data_ref_old, $nutrient, $nutriscore_data_ref_old->{$nutrient});
      my $test = ProductOpener::Nutriscore9::get_value_with_one_less_negative_point_2023 ($nutriscore_data_ref_new, $nutrient, $nutriscore_data_ref_new->$nutrient);
      is($test, $ref, "2023 negative point on $nutrient");
      $ref  = ProductOpener::Nutriscore0::get_value_with_one_more_positive_point_2023 ($nutriscore_data_ref_old, $nutrient, $nutriscore_data_ref_old->{$nutrient});
      $test = ProductOpener::Nutriscore9::get_value_with_one_more_positive_point_2023 ($nutriscore_data_ref_new, $nutrient, $nutriscore_data_ref_new->$nutrient);
      is($test, $ref, "2023 positive point on $nutrient");
    }
    else {
      ok(1, "2023 negative $nutrient SKIPPED, missing value");
      ok(1, "2023 positive $nutrient SKIPPED, missing value");
    }
  }
}

sub test_data_2021 {
  return (
     {
      # based on "_id": "0025000044984"
      # Nutrients
        energy              => 192
      , fiber               => 0
      , sugars              => 9.5833333333333
      , saturated_fat       => 0
      , sodium              => 0
      , proteins            => 6.7
      , fruits_vegetables_nuts_colza_walnut_olive_oils => 16.14583333333333

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 1
      , is_water              => 0
      , is_cheese             => 0
      , is_fat                => 0 # for 2021 version
    }
    , {
      # based on "_id":"5410556206255"
      # Nutrients
        energy              => 3766
      , sugars              => 0
      , saturated_fat       => 11
      , saturated_fat_ratio => 11
      , sodium              => 0
      , fiber               => 0
      , proteins            => 0
      , fruits_vegetables_nuts_colza_walnut_olive_oils => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_fat                => 1 # for 2021 version
    }
  );
}

sub test_data_2023 {
  return (
      {
      # based on "_id":"5410556206255"
      # Nutrients
        energy_from_saturated_fat => 407
      , sugars                    => 0
      , saturated_fat_ratio       => 11
      , salt                      => 0
      , fiber                     => 0
      , proteins                  => 0
      , fruits_vegetables_legumes => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 0
      , is_fat_oil_nuts_seeds => 1 # for 2023 version
    }
    , {
      # based on "_id": "0078742054797",
      # Nutrients
        energy                    => 1272
      , sugars                    => 0
      , saturated_fat             => 10.71
      , salt                      => 7
      , fiber                     => 0
      , proteins                  => 0
      , fruits_vegetables_legumes => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 1
      , is_fat_oil_nuts_seeds => 0 # for 2023 version
    }
    , {
      # based on "_id": "0025000044984",
      # Nutrients
        energy                    => 192
      , sugars                    => 9.58
      , saturated_fat             => 0
      , salt                      => 0
      , fiber                     => 0
      , proteins                  => 0.83
      , non_nutritive_sweeteners  => 0
      , fruits_vegetables_legumes => 16.1

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 1
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 0
      , is_fat_oil_nuts_seeds => 0 # for 2023 version
    }
  );
}

=encoding utf8

=head1 NAME

04-more-or-less.t -- Testing the integration of NutriscoreData with Nutriscore functions get_value_with_one_less_negative_point_2023 and ..._one_more_positive_...

=head1 USAGE

  prove t9/*.t

=back

=head1 BUGS AND LIMITATIONS

The property C<components> (for version 2023) is not checked.

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
