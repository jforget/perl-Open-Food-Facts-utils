#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl

use v5.38;
use utf8;
use strict;
use warnings;
use lib qw{ . ../../openfoodfacts-server/lib/ };
use ProductOpener::Nutriscore0 qw/:all/;
use YAML::XS;

my $nutriscore_data_ref = {
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
};

my ($nutriscore_score, $nutriscore_grade) = compute_nutriscore_score_and_grade(
 $nutriscore_data_ref
);

print "Rounded value for sugars: " . $nutriscore_data_ref->{sugars_value} . "\n";
print "Points for sugars: " . $nutriscore_data_ref->{sugars_points}. "\n";
print YAML::XS::Dump($nutriscore_data_ref);
