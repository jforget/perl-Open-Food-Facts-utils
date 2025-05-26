-*- encoding: utf-8; indent-tabs-mode: nil -*-

But
===

Pendant le
[hackathon du 24 mai 2025|https://forum.openfoodfacts.org/t/hackathon-perl-open-food-facts-in-paris-2025/1936],
j'ai choisi de travailler sur la sécurisation des hashmaps,
c'est à dire l'utilisation de l'orientation objet
([Moose|https://metacpan.org/pod/Moose]).
La première étape consiste à définir une structure objet pour la
variable `$nutriscore_data_ref` dans
[`ProductOpener::Nutriscore`](https://github.com/jforget/openfoodfacts-server/blob/main/lib/ProductOpener/Nutriscore.pm).

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

* un troisième module dont j'ai oublié le nom.

Les jours suivants,  j'ai tenté de reproduire  l'installation de Moose
sur une machine  virtuelle avec xubuntu-25.04 et Perl  5.40.1, sur une
machine  virtuelle avec  Fedora-41 et  Perl 5.40.2  et sur  ma machine
principale,  sous Devuan,  avec Perl  5.32.1 pour  le système  et Perl
5.38.2 activable par  `perlbrew`. Sur ces trois machines,  je n'ai pas
reproduit le problème. L'absence  de `DateTime`, par exemple, provoque
un `SKIP`, pas une erreur bloquant l'installation.

Licence
=======

Texte diffusé sous la licence  CC-BY-SA : Creative Commons avec clause
de paternité, partage à l'identique.
