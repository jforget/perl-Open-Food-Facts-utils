package  ProductOpener::NutriscoreData1;
use Moose;

use Moose::Util::TypeConstraints ;

has is_beverage          => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 );
has is_cheese            => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 );
has is_water             => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 );
has is_fat               => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 ); # 2021 version, not in 2023
has is_fat_oil_nuts_seed => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 ); # 2023 version, not in 2021
has is_red_meat_product  => ( is => 'rw' , isa => 'Bool', required => 1, default => 0 ); # 2023 version, not in 2021
# Attributes for the 2021 version, begin
has energy               => ( is => 'rw' , isa => 'Int' , required => 1 );
has energy_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has energy_value         => ( is => 'rw' , isa => 'Int' , required => 0 );
has fiber                => ( is => 'rw' , isa => 'Num' , required => 1 );
has fiber_points         => ( is => 'rw' , isa => 'Int' , required => 0 );
has fiber_value          => ( is => 'rw' , isa => 'Num' , required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils   => ( is => 'rw' , isa => 'Num' , required => 1 );
has fruits_vegetables_nuts_colza_walnut_olive_oils_p => ( is => 'rw' , isa => 'Num' , required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils_v => ( is => 'rw' , isa => 'Num' , required => 0 );
has proteins             => ( is => 'rw' , isa => 'Num' , required => 1 );
has proteins_points      => ( is => 'rw' , isa => 'Int' , required => 0 );
has proteins_value       => ( is => 'rw' , isa => 'Num' , required => 0 );
has saturated_fat        => ( is => 'rw' , isa => 'Num' , required => 1 );
has saturated_fat_points => ( is => 'rw' , isa => 'Int' , required => 0 );
has saturated_fat_value  => ( is => 'rw' , isa => 'Num' , required => 0 );
has saturated_fat_ratio  => ( is => 'rw' , isa => 'Num' , required => 1 ); #  not in docs/api/ref/schema
has sodium               => ( is => 'rw' , isa => 'Num' , required => 1 );
has sodium_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has sodium_value         => ( is => 'rw' , isa => 'Num' , required => 0 );
has sugars               => ( is => 'rw' , isa => 'Num' , required => 1 );
has sugars_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has sugars_value         => ( is => 'rw' , isa => 'Num' , required => 0 );
# Attributes for the 2021 version, end
# Attributes for the 2023 version, begin
### components           => ( is => 'rw' , isa => 'Hashref', required => 0 ); # for the moment, ignore this property used only in the 2023 version
# Attributes for the 2023 version, end
has count_proteins        => ( is => 'rw' , isa => 'Num' , required => 0 ); # in 2023 version, not in 2021
has count_proteins_reason => ( is => 'rw' , isa => 'Str' , required => 0 ); # in 2023 version, not in 2021
has negative_points       => ( is => 'rw' , isa => 'Int' , required => 0 );
has positive_points       => ( is => 'rw' , isa => 'Int' , required => 0 );
has grade                 => ( is => 'rw' , isa => 'Str' , required => 0 );
has score                 => ( is => 'rw' , isa => 'Int' , required => 0 );

8_000_000;
