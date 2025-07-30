-*- encoding: utf-8; indent-tabs-mode: nil -*-

But
===

Pendant le
[hackathon du 24 mai 2025](https://forum.openfoodfacts.org/t/hackathon-perl-open-food-facts-in-paris-2025/1936),
j'ai choisi de travailler sur la sécurisation des hashmaps,
c'est à dire l'utilisation de l'orientation objet
([Moose](https://metacpan.org/pod/Moose)).
La première étape consiste à définir une structure objet pour la
variable `$nutriscore_data_ref` dans
[`ProductOpener::Nutriscore`](https://github.com/jforget/openfoodfacts-server/blob/main/lib/ProductOpener/Nutriscore.pm).

Remarquons que l'expérience ne consiste pas à comparer
[`bless`](https://perldoc.perl.org/functions/bless)
avec [`Moo`](https://metacpan.org/pod/Moo)
et [Corinna](https://curtispoe.org/articles/corinna-in-the-perl-core.html)
ou d'autres solutions  Perl de programmation orientée  objet. Le choix
technique est déjà  fait, c'est Moose, l'expérience porte  sur la mise
en œuvre de Moose.  D'autre part, même s'il y a  une réflexion au sein
d'Open Food Facts pour commencer à utiliser
[PostgreSQL](https://www.postgresql.fr/),
l'utilisation  de  Moose  est   un  sujet  différent,  concernant  des
variables éphémères et non le stockage de données permanentes.

Installation de Moose
=====================

Ce  chapitre ne  concerne  pas vraiment  OpenFoodFacts,  mais il  peut
apporter certaines informations aux éventuels lecteurs.

Sur  la machine  que j'ai  utilisé lors  du hackathon,  l'interpréteur
système `perl`  est à la  version 5.34.x, donc  il ne connaît  pas les
signatures de fonctions.  Il y a aussi un  `perl-5.38.2` activable par
`perlbrew`. Le  problème est que  j'ai installé `Moose` sur  le `perl`
système, j'ai  oublié d'activer la version  5.38 avant l'installation.
J'ai donc dû  répéter cette installation une fois que  la version 5.38
était activée.

Deuxième  problème.  J'effectue  l'installation en  deux  temps.  Tout
d'abord, je commence par m'assurer que tous les prérequis signalés dans
[MetaCPAN](https://metacpan.org/pod/Moose)
(marge gauche) sont bien installés. Ensuite je lance l'installation de
`Moose`. Néanmoins, sur la machine utilisée lors du hackathon, j'ai eu
quelques erreurs en  raison de modules nécessaires  mais qui n'étaient
pas installés. De mémoire, il y avait

* [DateTime](https://metacpan.org/pod/DateTime)

* [Params::Validate](https://metacpan.org/pod/Params::Validate)

* [Log::Any](https://metacpan.org/pod/Log::Any)

Les jours suivants,  j'ai tenté de reproduire  l'installation de Moose
sur une machine  virtuelle avec xubuntu-25.04 et Perl  5.40.1, sur une
machine  virtuelle avec  Fedora-41 et  Perl 5.40.2  et sur  ma machine
principale,  sous Devuan,  avec Perl  5.32.1 pour  le système  et Perl
5.38.2 activable par  `perlbrew`. Sur ces trois machines,  je n'ai pas
reproduit  le  problème  entièrement.  L'absence  de  `DateTime`,  par
exemple, provoque  un `SKIP`, pas une  erreur bloquant l'installation.
En  revanche,  lorsque j'ai  voulu  exécuter  le script  d'exemple  de
`Nutriscore.pm`, il manquait bel et bien `Log::Any`.

Démarche
========

Lors  de la  journée du  24 mai,  j'ai effectué  une recherche  plutôt
intuitive  et débridée.  Lors du  travail  ultérieur de  juin 2025  et
au-delà, la recherche était plus méthodique et plus lente. Je conserve
les versions différentes dans le  répertoire, de façon qu'il soit plus
facile de  les comparer entre  elles, pas  besoin de jongler  avec les
commandes `git checkout`.

Le 24 mai, j'ai utilisé un  script de test inspiré de la documentation
POD de `Nutriscrore.pm` :

```
    use ProductOpener::Nutriscore qw/:all/;

        my $nutriscore_data_ref = {
                # Nutrients
                energy =>  518, # in kJ
                sugars => 3,
                saturated_fat => 0.7,
                saturated_fat_ratio => 0.7 / 3 * 100,
                sodium => 0.61 / 2.5 * 1000,    # in mg, sodium = salt divided by 2.5
                fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
                fiber => 2.2,
                proteins => 6.7,

                # The Nutri-Score computation is different for beverages, waters, cheeses and fats
                is_beverage => 1,
                is_water => 0,
                is_cheese => 0,
                is_fat => 1, # for 2021 version
                is_fat_oil_nuts_seed => 1, # for 2023 version
        }

        my ($nutriscore_score, $nutriscore_grade) = compute_nutriscore_score_and_grade(
                $nutriscore_data_ref
        );

        print "Rounded value for sugars: " . $nutriscore_data_ref->{sugars_value} . "\n";
        print "Points for sugars: " . $nutriscore_data_ref->{sugars_points}. "\n";
```

Soit  dit   en  passant,   la  documentation  POD   devrait  remplacer
`is_fat_oil_nuts_seed` par  `is_fat_oil_nuts_seeds` avec  un "s"  à la
fin.

Script de test `nutriscore.t` ?
-------------------------------

Au mois de juin, j'y ai tenté d'ajouter le script de tests unitaires pour le nutriscrore,
[`nutriscore.t`](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/tests/unit/nutriscore.t).
Pour ce faire, j'ai dû créer un module `ProductOpener::Config` en local en recopiant le fichier
[`Config2_sample.pm`](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/lib/ProductOpener/Config2_sample.pm)
vers le répertoire local.
Également, j'ai dû initialiser une variable d'environnement

```
export  PRODUCT_OPENER_FLAVOR_SHORT=off
```

finalement, j'ai dû installer quelques modules supplémentaires :

* [`Log::Any::Adapter::TAP`](https://metacpan.org/pod/Log::Any::Adapter::TAP)

* [`Modern::Perl`](https://metacpan.org/pod/Modern::Perl)

* [`JSON::MaybeXS`](https://metacpan.org/pod/JSON::MaybeXS)

* [`URI::Escape::XS`](https://metacpan.org/pod/URI::Escape::XS)

* [`JSON::Create`](https://metacpan.org/pod/JSON::Create)

* [`File::Find::Rule`](https://metacpan.org/pod/File::Find::Rule)

* [`Locale::Maketext::Lexicon`](https://metacpan.org/pod/Locale::Maketext::Lexicon)

* [`Locale::Maketext::Lexicon::Getcontext`](https://metacpan.org/pod/Locale::Maketext::Lexicon::Getcontext)

* [`CLDR::Number`](https://metacpan.org/pod/CLDR::Number)

* [`CGI`](https://metacpan.org/pod/CGI)

Et je devais alors installer
[`Image::Magick`](https://metacpan.org/pod/Image::Magick).
C'est là que j'ai arrêté. Pourquoi les tests *unitaires* du nutriscore
ont-ils besoin de  faire du traitement d'image ? Je  me contenterai du
script inspiré de l'exemple POD.

À  la fin,  après  avoir écrit  la  version 7,  j'ai  écrit un  script
`04-integration.t` qui compare les  résultats de `Nutriscore7.pm` avec
ceux  de `Nutriscore0.pm`  pour  des valeurs  d'entrée identiques.  Ce
script de test utilise, lui, très peu de modules :

* `Test::More` parce que c'est un script de tests,

* `ProductOpener::Nutriscore0` pour calculer les données de référence,

* `ProductOpener::Nutriscore7` pour calculer les données à tester,

* `ProductOpener::NutriscoreData7` parce que c'est le module en cours de test.

J'ai incorporé rétroactivement ce script  de tests dans les versions 1
à 6.

Versions successives
--------------------

Le remplacement des _hashmaps_ par `Moose` n'est pas une action « tout
ou rien ». Au moins dans  l'étude exploratoire, on progresse étape par
étape. Pour permettre une meilleure  visualisation de ces étapes, j'ai
préféré conserver  côte à côte  les différentes versions de  la classe
`ProductOpener::NutriscoreData`,  plutôt que  de les  « empiler » dans
l'historique géré par Git.

La version de référence est la version 0, contenant :

* le module `lib/ProductOpener/Nutriscore0.pm`

* le script `example0.pl`

La première version contient :

* la classe `lib/ProductOpener/NutriscoreData1.pm`

* le module `lib/ProductOpener/Nutriscore1.pm`

* le script  `example1.pl`, servant de  test pour l'intégration  de la
classe lib/PO/ND1.pm avec le module lib/PO/N1.pm

* les  scripts `t1/*.t`,  servant de  tests unitaires  pour la  classe
lib/PO/ND1.pm et étant indépendants du module lib/PO/N1.pm

et idem pour les versions suivantes.

Pré-requis
----------

Pour faire fonctionner les scripts  de ce répertoire, vous devez avoir
un clone du présent dépôt Github, ainsi qu'un clone du dépôt
[openfoodfacts-server](https://github.com/jforget/openfoodfacts-server)
(le mien ou
[celui d'OFF](https://github.com/openfoodfacts/openfoodfacts-server)),
dans le même répertoire que le clone de perl-Open-Food-Facts-utils.

Vous devez également installer :

* [Moose](https://metacpan.org/pod/Moose) (bien sûr),

* [Log::Any](https://metacpan.org/pod/Log::Any),

* [YAML::XS](https://metacpan.org/dist/YAML-LibYAML/view/lib/YAML/XS.pod),

* [Test::Exception](https://metacpan.org/pod/Test::Exception).

```
git clone https://github.com/jforget/openfoodfacts-server.git
git clone https://github.com/jforget/perl-Open-Food-Facts-utils.git
cpan
install Moose
install Log::Any
install YAML::XS
install Test::Exception
exit
```

Version 1, objet basique
========================

Lorsque l'on lit  le programme de test `example0.pl`,  on constate que
la variable  `$nutriscore_data_ref` contient des clés  qui sont citées
dans le fichier
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore),
à la fois dans le groupe `nutriscore  / 2021 / data` et dans le groupe
`nutriscore_data`.    Les    seules    exceptions    sont    la    clé
`saturated_fat_ratio`  qui  n'apparaît  nulle  part  dans  le  fichier
décrivant le schéma et la clé `is_fat_oil_nuts_seed` qui apparaît dans
le  groupe  `nutriscore /  2023  /  data`,  ainsi  que le  suggère  le
commentaire associé.

La version 1 crée donc une classe avec toutes les propriétés scalaires
des groupes `nutriscore / 2021 /  data`, `nutriscore / 2023 / data` et
`nutriscore_data`, en  faisant l'impasse  sur la  propriété structurée
`components` et sur le champ supplémentaire `saturated_fat_ratio`.

Après   coup,    j'ai   constaté    qu'en   faisant    l'impasse   sur
`saturated_fat_ratio`,  les résultats  n'étaient pas  compatibles avec
ceux de la  référence `example0.pl`, il y avait 14  points négatifs là
on en attendait 17. La classe `NutriscoreData1` comporte donc le champ
`saturated_fat_ratio` et le calcul se fait bien.

Et  longtemps  après,  j'ai  vu  que la  description  de  la  variable
`$nutriscore_data_ref`   était   basée   sur   les   commentaires   de
`ProductOpener::Nutriscore` en lignes
[149 à 175](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L149)
et [494 à 524](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L494).
Dans cette véritable description, il  n'y a pas de données structurées
multi-niveaux comme  `components` comme  je le  croyais lorsque  je me
basais uniquement sur
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore),

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des  entiers servant de  booléens) et des  réels (contrôle
effectué lors de la création d'une instance).

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser des accesseurs pour lire une propriété et la modifier,

* contrôler la  valeur des chaînes,  des entiers, des booléens  et des
réels (contrôle à effectuer lors de la modification d'une instance).

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(comme  la  propriété  `saturated_fat_ratio_points`  et  la  propriété
`saturated_fat_ratio_value`  qui  sont  ajoutées  lors  du  calcul  du
nutriscore),

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

Remarquons que  le module `Nutriscore1.pm` est  quasiment identique au
module `Nutriscore0.pm`.

Version 2, avec accesseurs
==========================

La   classe   `NutritionData2.pm`   est    identique   à   la   classe
`NutritionData1.pm`,  à part  son numéro.  L'utilisation de  la classe
`NutritionData2.pm` dans `Nutrition2.pm`  est différente, elle utilise
les accesseurs  plutôt que la  syntaxe des _hashmaps_. Cela  dit, pour
l'instant, cela ne  fonctionne que pour la lecture  d'une propriété ou
pour la  mise à jour  de cette  propriété par l'opérateur  « `=` ». En
revanche, pour l'instant, les  opérateurs du genre « `+=` » continuent
à utiliser la syntaxe des _hashmaps_.  Cela ne fonctionne pas non plus
lorsque  le nom  de la  propriété est  calculé, par  exemple, avec  la
variable `$nutrient` concaténée avec la chaîne `'_value'`.

Problème :  le  script  de  test `example2.pl`  est  très  loin  d'une
couverture de code complète pour `NutritionData2.pm`. Il y a des accès
que j'ai modifiés mais qui n'ont pas été testés.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est modifiée par le biais d'un accesseur.

* utiliser des accesseurs pour lire une propriété dont le nom est fixe
et pour remplacer sa valeur (et la contrôler),

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser  des accesseurs  pour lire  une propriété  dont le  nom est
calculé et pour remplacer sa valeur,

* utiliser des accesseurs pour modifier  de façon incrémentale (p. ex.
`+=`) une propriété,

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(comme  la  propriété  `saturated_fat_ratio_points`  et  la  propriété
`saturated_fat_ratio_value`  qui  sont  ajoutées  lors  du  calcul  du
nutriscore),

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.

Version 3, indirection sur les noms de méthode
==============================================

Aucun changement dans  la classe `NutriscoreData3`, à  part l'ajout de
deux propriétés oubliées. Dans le module `Nutriscore3`, la syntaxe des
accesseurs est généralisée au cas où le nom de la méthode est variable
(contenu  dans une  variable  Perl  ou obtenu  avec  une formule).  En
revanche,  pour des  modifications  complexes  (« `+=` », `push`),  on
continue à utiliser la syntaxe des _hashmaps_.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est modifiée par le biais d'un accesseur.

* utiliser un accesseur  pour lire une propriété et  pour remplacer sa
valeur (après l'avoir contrôlée),

* interdire toute propriété qui n'est pas déclarée dans la classe.

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser  des  accesseurs  pour  modifier  une  propriété  de  façon
incrémentale (p. ex. `+=` ou `push`),

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.

Remarque : les deux propriétés oubliées sont
`saturated_fat_ratio_points` et `saturated_fat_ratio_value`,
correspondant à la propriété `saturated_fat_ratio` que j'ai du ajouter
dans la version 1 pour obtenir les bons résultats dans `example1.pl`.

Version 4, contrôle de valeur de la propriété `grade`
=====================================================

Juste la définition d'un `enum`, en m'inspirant de
[la documentation de `Moose`](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/Types.pod#TYPE-CREATION-HELPERS)
et, dans une moindre mesure, de
[Stack Overflow](https://stackoverflow.com/questions/473666/does-perl-have-an-enumeration-type)
et des
[bonnes pratiques](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/BestPractices.pod#Namespace-your-types)
pour les noms de type.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est modifiée par le biais d'un accesseur.

* utiliser un accesseur  pour lire une propriété et  pour remplacer sa
valeur (après l'avoir contrôlée),

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(contrôle activé lorsque la propriété est mentionnée par le biais d'un
accesseur,  contrôle ineffectif  lorsque l'on  utilise la  syntaxe des
_hashmaps_),

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser  des  accesseurs  pour  modifier  une  propriété  de  façon
incrémentale (p. ex. `+=` ou `push`),

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.

Version 5, mise à jour incrémentale
===================================

Les versions 5 à 7 proposent  quelques solutions pour les mises à jour
incrémentales  comme  « `+=` »  et  « `-=` »  (mais  pas  encore  pour
« `push` »).

La version 5 consiste à détricoter les « `+=` » pour obtenir des mises
à jour basiques  puis à encapsuler ces mises à  jour basiques avec des
accesseurs. On a successivement :

```
$nutriscore_data_ref->{negative_points} +=                                          $points;
$nutriscore_data_ref->{negative_points} = $nutriscore_data_ref->{negative_points} + $points;
$nutriscore_data_ref->negative_points(    $nutriscore_data_ref->negative_points   + $points);
```

Ce n'est  pas élégant, c'est  plus _WET_ que _DRY_  (_write everywhere
twice_ / écrire partout deux fois plutôt que _don't repeat yourself_ /
éviter les répétitions), mais cela fonctionne.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est modifiée par le biais d'un accesseur.

* utiliser un  accesseur pour  lire une  propriété, pour  remplacer sa
valeur   (après  l'avoir   contrôlée)  et   dans  certains   cas  pour
l'incrémenter,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(contrôle activé lorsque la propriété est mentionnée par le biais d'un
accesseur,  contrôle ineffectif  lorsque l'on  utilise la  syntaxe des
_hashmaps_),

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser des accesseurs pour modifier une propriété de type liste de
façon incrémentale (p. ex. `push`),

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.

Version 6, mise à jour incrémentale (avec style)
================================================

Dans la  version 6,  la mise à  jour d'une propriété  se fait  de deux
façons différentes. Pour une mise à jour en « annule et remplace », on
utilise une  méthode homonyme (standard Moose). Pour  une mise à jour  incrémentale, on
utilise une méthode dont le nom se termine par le suffixe « `_incr` »,
par exemple :

```
$nutriscore_data_ref->negative_points_incr($points);
```

Pour une décrémentation « `-=` », il suffit d'insérer un signe moins :

```
$nutriscore_data_ref->negative_points_incr( - $points );
```

Les  autres   mises  à   jour  composites   (multiplication  « `*=` »,
concaténation « .= », etc) ne sont pas prévues dans la classe exemple,
mais il est facile de s'inspirer de l'existant pour les programmer.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est  modifiée  par  le  biais  d'un  accesseur  en  mode  « annule  et
remplace ».

* utiliser un  accesseur pour  lire une  propriété, pour  remplacer sa
valeur   (après  l'avoir   contrôlée)  et   dans  certains   cas  pour
l'incrémenter,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(contrôle activé lorsque la propriété est mentionnée par le biais d'un
accesseur,  contrôle ineffectif  lorsque l'on  utilise la  syntaxe des
_hashmaps_),

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

Que reste-t-il à faire pour avoir une situation idéale ?

* le  contrôle   des  valeurs  des  chaînes,   entiers  et  flottants,
lorsqu'une propriété est incrémentée,

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* utiliser des accesseurs pour modifier une propriété de type liste de
façon incrémentale (p. ex. `push`),

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.

Version 7, incrémentation
=========================

Dans cette version, les méthodes  d'incrémentation ne sont pas codées,
elles  sont  générées. Le  fait  que  ces méthodes  proviennent  d'une
génération de code fait que l'on peut introduire des répétitions comme
dans la version 5, sans toutefois être gêné par ces répétitions. De la
sorte, le contrôle de type est effectué lors de l'incrémentation.

Une autre  nouveauté est que  la valeur incrémentale  est facultative,
avec une valeur par défaut à 1.

Pendant que je testais cette version,  je me suis aperçu qu'il fallait
déclarer deux nouvelles propriétés,  à savoir `negative_points_max` et
`positive_points_max`, qui ne sont commentées ni dans
[`Nutriscore.pm` linges 494 à 524](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L494).
ni dans
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore).
Si la couverture de code avait été plus complète, cela aurait provoqué
une  erreur de  programme  au moment  de  l'utilisation d'une  méthode
d'incrémentation pour ces deux propriétés.

Je suis surpris que la déclaration de méthodes incrémentales n'existe
pas dans Moose.
[Metacpan](https://metacpan.org/search?q=moose+increment)
ne me donne aucun résultat qui pourrait convenir et
[Qwant](https://www.qwant.com/?q=perl+moose+incr%C3%A9mentation&t=web&llm=2)
indique dans sa réponse flash

> Moose facilite la gestion des  classes Perl en permettant de définir
> des attributs avec des méthodes d'accès et des traits personnalisés,
> mais   il   ne   fournit    pas   directement   une   fonctionnalité
> d'incrémentation ;  celle-ci doit  être implémentée via  une méthode
> spécifique ou  en utilisant un  attribut avec un builder  pour gérer
> l'incrémentation automatique.

Peut-on  faire confiance  à l'intelligence  artificielle qui  alimente
cette réponse flash ? Peu importe, le résultat est que je dois générer
ces méthodes d'incrémentation dans la classe.

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels. Ce contrôle
est effectué  lorsque l'on crée  une instance, mais  aussi lorsqu'elle
est  modifiée  par  le  biais  d'un  accesseur  en  mode  « annule  et
remplace » ou en mode incrémentation.

* utiliser un  accesseur pour  lire une  propriété, pour  remplacer sa
valeur   (après  l'avoir   contrôlée)  et   dans  certains   cas  pour
l'incrémenter,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(contrôle activé lorsque la propriété est mentionnée par le biais d'un
accesseur,  contrôle ineffectif  lorsque l'on  utilise la  syntaxe des
_hashmaps_),

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

Que reste-t-il à faire pour avoir une situation idéale ?

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* idem  avec la  propriété `positive_nutrients`  qui, pour  l'instant,
admet n'importe quel _arrayref_,

* utiliser des accesseurs pour modifier une propriété de type liste de
façon incrémentale (p. ex. `push`),

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.  Ou alors,  pourrait-on alimenter  ces propriétés  avec
`undef` ?

Version 8, algorithme de 2023
=============================

La version  8 est juste une  tentative pour obtenir une  couverture de
code  un  peu meilleure,  en  testant  notamment  la version  2023  de
l'algorithme du nutriscore.

Cela  a  néanmoins  entraîné  des changements  importants  en  taille,
quoique mineurs pour l'aspect conceptuel.

* Ajout de plusieurs  attributs associés à des nutriments  qui ne sont
pas pris en compte dans la version 2021 ou qui sont appelés autrement.

* Ajout des attributs `xxx_points_max` pour tous les nutriments.

* Ajout d'une valeur par défaut pour tous les attributs obligatoires.

Je ne reprends la comparaison avec les _hashmaps_ et avec la situation
idéale, c'est identique à la version 7.

La couverture  de code est meilleure  qu'avec la version 7,  mais elle
est encore incomplète. Vous pouvez le vérifier avec

```
cover --delete
PERL5OPT=-MDevel::Cover prove t8/*
cover
firefox cover_db/coverage.html &
```

Je  ne cherche  pas à  avoir une  couverture de  code à  100%. Un  tel
objectif ouvrirait la porte aux dysfonctionnements mis en évidence par la
[loi](https://freakonometrics.hypotheses.org/61681).
de [Goodhart](https://xkcd.com/2899/).
De plus, comme je l'ai présenté lors des
[Journées Perl 2015](https://journeesperl.fr/fpw2015/talk/6309),
une couverture à 100% n'est pas  une garantie pour l'absence totale de
bugs. En revanche, comme je l'ai présenté lors des
[Journées Perl 2013](http://www.youtube.com/watch?v=eXRPWdoLBzA),
faire un  effort même incomplet  pour améliorer la couverture  de code
permet parfois  de mettre en évidence  des bugs que l'on  n'aurait pas
trouvés autrement. Voir les lignes 779, 784 et 787 de
[Nutriscore7.pm](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/8d2629f533e6bae0e1dda412da7bd4e6569e1377/Nutriscore-Moose/lib/ProductOpener/Nutriscore7.pm#L779)
et
[Nutriscore8.pm](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/8d2629f533e6bae0e1dda412da7bd4e6569e1377/Nutriscore-Moose/lib/ProductOpener/Nutriscore8.pm#L779)

Quant au
[sujet 12172](https://github.com/openfoodfacts/openfoodfacts-server/issues/12172),
au début j'ai ajouté l'appel de
`get_value_with_one_less_negative_point` et de
`get_value_with_one_more_positive_point` dans les scripts de test,
ce qui aurait implicitement assuré la couverture de
`get_value_with_one_less_negative_point_2023` et de
`get_value_with_one_more_positive_point_2023`.
Or ces fonctions plantaient. Je les ai remplacées dans les
scripts de test par les fonctions `xxx_2023` et j'ai soumis le
[sujet 12172](https://github.com/openfoodfacts/openfoodfacts-server/issues/12172).
L'équipe d'Open Food Facts a purement et simplement décidé de
[supprimer](https://github.com/openfoodfacts/openfoodfacts-server/pull/12176/commits/ec66bff057c4692ca61eb56775374be387865838)
les fonctions `get_value_with_one_less_negative_point` et
`get_value_with_one_more_positive_point`.

Version 9, tableau `positive_nutrients`
=======================================

Cette  version a  pour but  d'eliminer  la syntaxe  _hashmap_ pour  la
propriété  de  type liste  `positive_nutrients`.  Il  ne reste  qu'une
instruction  avec la  syntaxe  _hashmap_, un  `unshift`  de la  chaîne
`"proteins"`. Également, faire  un contrôle de type  pour les éléments
de la liste.

Mes sources d'inspiration pour cette adaptation sont :

* [Stack overflow](https://stackoverflow.com/questions/3487559/accessing-a-moose-array),

* [le manuel de Moose](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/Delegation.pod#NATIVE-DELEGATION).

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle de valeur des propriétés scalaires : chaînes, entiers (y
compris le cas particulier des  entiers servant de booléens) et réels.
Ce contrôle  est effectué lorsque  l'on crée une instance,  mais aussi
lorsqu'elle est modifiée par le  biais d'un accesseur en mode « annule
et remplace » ou en mode incrémentation.

* utiliser  un  accesseur  pour  lire  une  propriété  scalaire,  pour
remplacer sa  valeur (après  l'avoir contrôlée)  et dans  certains cas
pour l'incrémenter,

* le contrôle des propriétés listes, en appliquant un contrôle de type
sur chaque élément de la liste,

* utiliser un accesseur  pour lire la liste et pour  la mettre à jour,
aussi  bien en  « annule et  remplace » qu'en  mode incrémental  comme
`unshift`,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(contrôle activé lorsque la propriété est mentionnée par le biais d'un
accesseur,  contrôle ineffectif  lorsque l'on  utilise la  syntaxe des
_hashmaps_),

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

Que reste-t-il à faire pour avoir une situation idéale ?

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* imaginer  ce  que  pourrait  être   la  structure  de  la  propriété
multi-niveau   `components`,  au   lieu   d'admettre  n'importe   quel
_hashref_,

* statuer   sur   la   suppression   de   certaines   propriétés,   cf
Nutriscore0.pm  lignes  861 à  871 ;  cela  m'étonnerait que  ce  soit
possible en  programmation objet, ou  bien alors au prix  de plusieurs
complications.  Ou alors,  pourrait-on alimenter  ces propriétés  avec
`undef` ?

Licence
=======

Texte diffusé sous la licence  CC-BY-SA : Creative Commons avec clause
de paternité, partage à l'identique.
