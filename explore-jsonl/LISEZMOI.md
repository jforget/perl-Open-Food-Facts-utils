-*- encoding: utf-8; indent-tabs-mode: nil -*-

explore-jsonl
=============

Cet répertoire contient des programmes lisant un fichier JSONL pour en
extraire  les  documents  OFF  qui vérifient  certains  critères.  Ces
programmes   sont    écrits   en    complément   à    l'exécution   de
`schema-check.pl`, pour en savoir plus sur tel ou tel cas de figure.

updated-or-modified.pl
----------------------

Examine  les  documents  Open  Food  Facts pour  tester  si  le  champ
`last_updated_t` existe  et si  sa valeur coïncide  avec la  valeur du
champ `last_modified_t`

Voir également
==============

Le [blog d'Open Food Facts](https://blog.openfoodfacts.org/)
contient un
[article](https://blog.openfoodfacts.org/en/news/food-transparency-in-the-palm-of-your-hand-explore-the-largest-open-food-database-using-duckdb-%f0%9f%a6%86x%f0%9f%8d%8a)
sur l'utilisation de
[DuckDB](https://duckdb.org/)
pour écrire des requêtes similaires.


COPYRIGHT ET LICENCE
====================

Copyright (c) 2025 Jean Forget

Cette   bibliothèque  contient   du   logiciel   libre.  Vous   pouvez
redistribuer les programmes  de cette bibliothèque et  vous pouvez les
modifier selon  les termes  de la licence  _GNU Affero  General Public
License_ version  3 ou  ultérieure, comme pour  le dépôt  principal de
Open Food Facts. Voir
[le site de la FSF](https://www.gnu.org/licenses/agpl-3.0.fr.html).
ou le fichier `LICENSE` présent dans le répertoire principal de ce dépôt.
