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
en œuvre de Moose.

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

Qu'a-t-on gagné par rapport aux _hashmaps_ traditionnels ?

* le contrôle  de valeur des  chaînes, des  entiers (y compris  le cas
particulier des entiers servant de booléens) et des réels.

Que reste-t-il à faire pour avoir une situation idéale ?

* utiliser des accesseurs pour lire une propriété et la modifier,

* encapsulation : interdire  les accès  de syntaxe _hashmap_  pour les
propriétés, seuls les accesseurs sont autorisés,

* contrôle plus fin sur la  propriété `grade`, qui devrait prendre les
valeurs « `a` »,  « `b` », « `c` », « `d` » et  « `e` », à l'exclusion
de toute autre valeur,

* interdire  toute propriété  qui n'est  pas déclarée  dans la  classe
(comme  la  propriété  `saturated_fat_ratio_points`  et  la  propriété
`saturated_fat_ratio_value`  qui  sont  ajoutées  lors  du  calcul  du
nutriscore),

* définir  la   structure  de  la  propriété   `components`,  au  lieu
d'admettre n'importe quel _hashref_,

Remarquons que  le module `Nutriscore1.pm` est  quasiment identique au
module `Nutriscore0.pm`.

Licence
=======

Texte diffusé sous la licence  CC-BY-SA : Creative Commons avec clause
de paternité, partage à l'identique.
