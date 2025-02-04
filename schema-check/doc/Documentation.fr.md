-*- encoding: utf-8; indent-tabs-mode: nil -*-

But
===

La base de données pour Open Food  Facts est une base MongoDB, dans la
grande famille  des bases no-SQL.  Une particularité des  bases no-SQL
est que les  données insérées dans la base ne  sont pas contrôlées par
rapport  à un  schéma pré-défini.  On peut  ainsi avoir  une structure
différente  pour  deux  enregistrements   d'une  même  collection  (ou
« table » si l'on préfère la terminologie  SQL). Cela ne veut pas dire
pour autant  que l'on peut  stocker n'importe quoi dans  les documents
d'une collection.  Il n'y a pas  de discipline imposée par  la base de
données, mais il y a une auto-discipline adoptée par les programmeurs.

Pour Open Food Facts, cette auto-discipline est matérialisée par un
schéma qui peut être visualisé à
[cette adresse](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas),
ou sous la forme de
[fichiers YAML](https://github.com/jforget/openfoodfacts-server/tree/main/docs/api/ref/schemas)
dans la copie locale du dépôt Github.

Néanmoins,  il peut  y avoir  des entorses  à cette  auto-discipline :
traces d'un débugage,  évolution du schéma qui n'a  pas été répercutée
sur  les  documents pré-existants,  par  exemple.  Le but  du  présent
utilitaire  est  de  vérifier  si   les  documents  de  la  collection
`products` obéissent  bien au schéma  défini pour l'application  et de
répertorier les différences, essentiellement les  clés qui ne sont pas
déclarées dans le schéma.

Les  documents à  contrôler  sont  au format  JSON.  Ils peuvent  être
extraits  par  une  requête  sous  le  client  `mongosh`  ou  `mongo`,
récupérés en masse avec `mongoexport`, ou autre méthode.

Mode d'emploi
=============

Installation
------------

Il y a besoin de Perl 5.38, ainsi que des modules
[`YAML`](https://metacpan.org/dist/YAML/view/lib/YAML.pod),
[`YAML::XS`](https://metacpan.org/dist/YAML-LibYAML/view/lib/YAML/XS.pod),
[`YAML::Node`](https://metacpan.org/dist/YAML/view/lib/YAML/Node.pod)
et [`JSON::PP`](https://metacpan.org/pod/JSON::PP).
J'ai eu l'intention  de prendre `YAML::Any`, mais comme l'explique la
[documentation](https://metacpan.org/dist/YAML/view/lib/YAML/Any.pod),
ce module est destiné à être remplacé par
`YAML` qui, à terme, fonctionnera comme un module `xxx::Any`.

Votre machine doit contenir une copie locale du dépôt
[`openfoodfacts-server`](https://github.com/openfoodfacts/openfoodfacts-server)
ou d'un clone ce de dépôt.

Dans le programme `schema-check.pl`,  il faut changer l'initialisation
de la  variable `$dir_sch`  pour y  mettre le  répertoire de  la copie
locale  du dépôt  `openfoodfacts-server` contenant  les fichiers  YAML
décrivant le schéma des données.

Utilisation
-----------

Si la  version de Perl  utilisée par  votre système est  trop ancienne
(avant 5.38),  il faut sélectionner  une version récente,  par exemple
avec
[`perlbrew`](https://metacpan.org/dist/App-perlbrew/view/script/perlbrew).

Pour analyser les documents JSON contenus dans le fichier `exemple.txt`,
taper :

```
perl schema-check.pl exemple.txt
```

Supposons que le fichier `exemple.txt` contienne :

```
ligne bidon
{ "_id": "abcdef", "erreur_volontaire": 1 }
nouvelle ligne bidon
{
  "code": "ghijkl",
  "nutriments" : {
    "nouvelle_erreur_volontaire": 2
  }
}
dernière ligne bidon
```

Le résultat de la vérification est :

```
--------------------------------------------------
exemple.txt abcdef
--------------------------------------------------
invalid property erreur_volontaire (top)
--------------------------------------------------
exemple.txt ghijkl
--------------------------------------------------
invalid property nouvelle_erreur_volontaire (top nutriments)

```

Voici ce qui s'est passé. Le programme commence par charger en mémoire
le schéma de données. Puis le  programme  ouvre le  fichier
`exemple.txt` et en extrait les  documents JSON, ou plus exactement ce
qui pourrait ressembler à un document JSON. Cela peut être  :

* un  objet mono-ligne,  commençant par  une accolade  ouvrante et  se
terminant par une accolade fermante, comme

```
        { "_id": "abcdef", "erreur_volontaire": 1 }
```

* un objet formatté sur plusieurs lignes, la première étant réduite
à une accolade ouvrante et la dernière à une accolade fermante, comme

```
        {
          "code": "ghijkl",
          "nutriments" : {
            "nouvelle_erreur_volontaire": 2
          }
        }
```

* un  tableau d'objets,  formatté  sur plusieurs  lignes, la  première
ligne étant  un crochet ouvrant  (et rien d'autre), la  dernière ligne
étant un crochet  fermant (et rien d'autre). Le  formattage des objets
JSON à l'intérieur de ce tableau n'a pas d'importance.

```
        [
          {
            "code": "ghijkl",
            "nutriments" : {
              "nouvelle_erreur_volontaire": 2
            }
          },
          { "_id": "abcdef", "erreur_volontaire": 1 }
        ]
```

Tout le reste  est ignoré. Remarquons que le  programme ne reconnaîtra
pas  les documents  JSON qui  sont  formattés autrement  que les trois
possibilités ci-dessus. Par exemple, il ne reconnaîtra pas :

```
        { "code": "ghijkl",
          "nutriments" : {
            "nouvelle_erreur_volontaire": 2
          }
        }
```

et il extraira un document tronqué avec :

```
        { "code": "ghijkl", "nutriments" : { "nouvelle_erreur_volontaire": 2 }
        }
```

car il partira du principe  que l'accolade terminant la première ligne
est  l'accolade  fermant le  document  JSON,  alors qu'elle  ferme  un
sous-document.

Pour chaque objet JSON, la sortie standard contient :

1. une ligne de séparation,
2. une ligne d'entête, avec le nom de fichier et le code du produit,
3. une deuxième ligne de séparation,
4. les erreurs rencontrées.

Le code du produit est extrait soit de la propriété `code`, soit de la
propriété  `_id`. Si  un  objet contient  les  deux propriétés,  en
général elles ont la même valeur. Ce n'est pas vérifié.

Dans une ligne  d'erreur, on a bien entendu le  libellé de l'erreur et
la  valeur erronée  en  cause.  On a  également  entre parenthèses  la
localisation  de l'erreur,  en  fonction de  la  hiérarchie des  clés.
Ainsi, pour l'erreur de l'objet  `abcdef`, la localisation est `(top)`
pour indiquer  que l'erreur  se situe  à la  racine du  document. Pour
l'objet  `ghijkl`,  la  localisation   est  `(top  nutriments)`,  pour
indiquer que l'erreur se trouve dans le sous-objet `nutriments`.

Si vous voulez avoir  la description du schéma de données (dans
les 2000 lignes), précisez-le sur la ligne de commade :

```
perl schema-check.pl --list-schema exemple.txt
```

Dans ce cas, vous n'êtes pas obligés de fournir le nom d'un fichier de
données JSON. Le programme se contentera alors de charger le schéma et de
l'afficher.

Utilisation d'un autre schéma
-----------------------------

Lorsque vous utilisez le schéma de  données provenant du dépôt `openfoodfacts-server`, il
se peut que vous obteniez une erreur YAML du genre :

```
YAML Error: Expected separator '---'
   Code: YAML_PARSE_ERR_NO_SEPARATOR
   Line: 24
   Document: 2
 at /home/jf/perl5/lib/perl5/YAML/Loader.pm line 88.
```

Dans ce  cas, il  faut corriger  l'erreur de  syntaxe YAML  dans votre
copie locale,  la valider, créer  une _pull request_, la  soumettre et
attendre qu'elle soit prise en compte par l'équipe OFF.

Ou  alors,  vous  pouvez  copier  les  fichiers  YAML  vers  un  autre
répertoire, les corriger, puis utiliser  ces nouveaux fichiers pour le
schéma  de données.  C'est ce  que j'ai  fait avec  le sous-répertoire
`schemas` du présent dépôt. Pour  lancer la vérification des documents
JSON, la ligne de commande devient alors :

```
perl schema-check.pl --schema=schemas/schemas/product.yaml exemple.txt
```

ou bien

```
perl schema-check.pl --list-schema --schema=schemas/schemas/product.yaml exemple.txt
```

Ne pas oublier  de vérifier de temps  à autre si le  schéma de données
provenant du dépôt `openfoodfacts-server` a évolué.

Une autre  utilisation de cette option  consiste à créer un  schéma de
données délibérément réduit, pour tester un cas particulier sans avoir
à  se coltiner  le schéma  complet.  C'est ce  que j'ai  fait dans  le
sous-répertoire `reduced-schema` de ce dépôt. La ligne de commande
est :

```
perl schema-check.pl --schema=reduced-schema/product_meta.yaml reduced-schema/off1
```

Pour des raisons
[expliquées ultérieurement](#user-content-champs-implicites),
il est possible de fusionner plusieurs schémas.

```
perl schema-check.pl --schema=schemas/schemas/product.yaml --schema=schemas/schemas/product_hidden.yaml exemple.txt
```

Où trouver des données de test ?
--------------------------------

Vous pouvez toujours  les taper directement en JSON sous  Vi, Emacs ou
tout autre  éditeur de source à  votre convenance. Mais c'est  long et
sujet à erreurs.

Vous  pouvez  charger une  archive  représentant  la base  de  données
complète. Voir les explications
[sur le site web d'OFF](https://world.openfoodfacts.org/data)
et notamment le paragraphe « JSONL data export ». Le fichier au format
JSONL peut  être traité  directement par  `schema-check.pl`. Attention
toutefois, il contient plus de 3 millions de lignes pour une taille de
53 Go (été 2024).

Puisque vous  avez une  copie locale du  dépôt `openfoodfacts-server`,
vous avez  une base de  tests et vous  pouvez extraire des  données de
cette  base  pour les  soumettre  à  `schema-check.pl`. Voici  comment
faire.

Pour initialiser la base de données de tests, lancer l'une de ces deux
commandes (je n'ai  pas cherché quelles étaient  les différences entre
les deux) :

```
  make dev
  make import_sample_data
```

Ensuite, vous  pouvez utiliser le  site web  de tests pour  ajouter de
nouveaux produits, si vous le souhaitez.

### Avant le 21 juin 2024

Avant le  21 juin 2024,  il existait  un service Docker  pour MongoDB.
Voici la  méthode utilisée à  l'époque, qui  a entre autres  permis de
créer le  fichier de test  `examples/multiligne`. Comme j'ai  pris des
notes plutôt lacunaires et comme je  ne suis pas un expert sur Docker,
il peut y avoir des erreurs.

Pour extraire quelques  documents de la base de données,  je passe par
une fenêtre  shell dans Emacs.

1. ouverture d'une fenêtre shell

```
        M-x shell
```

2. ouverture d'une session sur le conteneur de la base de données (l'étape
qui ne fonctionne plus depuis le 21 juin)

```
        docker compose exec mongodb mongo
```

3. extraction de  quelques documents de la  collection `products`, par
exemple le produit `00187251` et les fromages

```
        use off
        db.products.findOne( { '_id': '00187251' } );
        db.products.find( { 'food_groups' : 'en:cheese' } )
```

4. fin de la session sur le conteneur

```
        exit
```

5. sauvegarde du  contenu de la fenêtre shell dans  un fichier appelé,
par exemple, `resultat`

```
        C-x C-w resultat
```

6. fin de la session shell dans la fenêtre Emacs

```
        exit
        C-x C-k
```

Le  fichier de  tests  `examples/multiligne` a  été  constitué sur  ce
principe.

Si vous voulez extraire la totalité de la collection `products`, voici
comment procéder.  Contrairement à la  procédure précédente, il  n'y a
pas d'avantage  à utiliser une  fenêtre shell dans Emacs,  vous pouvez
utiliser une fenêtre xterm.

1. extraction dans le répertoire `/tmp` du conteneur

```
      docker compose exec mongodb bash
      cd tmp
      mongoexport -doff -cproducts --type=json -o/tmp/products.json
      exit
```

2. liste des processus Docker, pour récupérer l'ID du conteneur. Voici la commande et sa sortie standard

```
      $ docker ps
      CONTAINER ID   IMAGE                                   COMMAND                  CREATED         STATUS         PORTS                        NAMES
      12345678       openfoodfacts-server/frontend:dev       "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   127.0.0.1:80->80/tcp         po_off-frontend-1
      89abcdef       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-backend-1
      87654321       openfoodfacts-server/dynamicfront:dev   "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes                                po_off-dynamicfront-1
      fedcba98       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-minion-1
      babeb1b0       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-incron-1
      cacec1c0       postgres:12-alpine                      "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes   5432/tcp                     po_off-postgres-1
      daded1d0       memcached:1.6-alpine                    "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   11211/tcp                    po_off-memcached-1
      cafebabe       redis:7.2-alpine                        "docker-entrypoint.s…"   2 days ago      Up 5 minutes   127.0.0.1:6379->6379/tcp     off_shared-redis-1
      deadbeef       mongo:4.4                               "docker-entrypoint.s…"   2 days ago      Up 5 minutes   127.0.0.1:27017->27017/tcp   off_shared-mongodb-1
```

3. transfert du fichier

```
      docker cp deadbeef:/tmp/products.json /home/jf/tmp
```

_Attention_. Avec l'une de ces deux procédures, ou peut-être les deux,
certains nombres sont extraits dans le fichier JSON sous la forme :

```
NumberLong(123456789)
```

Voir la propriété `popularity_key`  dans le document `"04148623"` dans
le fichier `multiligne`.

### Après le 21 juin 2024

Depuis le  21 juin  2024, le  service Docker  pour MongoDB  n'est plus
accessible.  Également, j'ai  mis  à  jour mon  poste  de travail,  en
désactivant l'instance  locale de MongoDB. Du  coup, il n'y a  plus de
conflit de  port TCP entre  l'instance locale et l'instance  Docker de
MongoDB.

Pour extraire la  totalité du contenu de la  collection `products`, il
suffit maintenant d'une seule ligne de commande :

```
      mongoexport -doff -cproducts --type=json -o/tmp/products.json
```

Pour l'extraction de quelques documents, la procédure devient :

1. ouverture d'une fenêtre shell dans Emacs

```
        M-x shell
```

2. ouverture d'une session sur la base de données

```
        mongosh
```

3. extraction de  quelques documents de la  collection `products`, par
exemple le produit `00187251` et les fromages

```
        use off
        db.products.findOne( { '_id': '00187251' } );
        db.products.find( { 'food_groups' : 'en:cheese' } )
```

4. fin de la session sur la base de données

```
        exit
```

5. sauvegarde du  contenu de la fenêtre shell dans  un fichier appelé,
par exemple, `resultat`

```
        C-x C-w resultat
```

6. fin de la session shell dans la fenêtre Emacs

```
        exit
        C-x C-k
```

Le  fichier de  tests `examples/multiline-1`  a été  constitué sur  ce
principe. Remarquons qu'il ne contient pas de `NumberLong(123456789)`.
Sans doute  est-ce parce que  le client MongoDB utilisé  est `mongosh`
dans la nouvelle version et `mongo` dans l'ancienne.

En  revanche, ainsi que c'est précisé dans
[la documentation de mongosh](https://www.mongodb.com/docs/mongodb-shell/reference/compatibility/#object-quoting-behavior),
les clés  des   paires  clé-valeur  ont  rarement  des
délimiteurs (doubles  quotes) et les  valeurs de ces paires  sont très
souvent délimitées par  des simples quotes au lieu  de doubles quotes.
C'est un pas dans la direction de
[JSON5](https://json5.org/).
Par exemple :

```
    _id: '0052833225082',
```

au lieu de

```
    "_id": "0052833225082",
```

La  solution  proposée  par  la  documentation  de  MongoDB,  apliquer
`EJSON.stringify()` à toutes  les requêtes, est peu  ergonomique. À la
place, _a priori_,  on peut s'en sortir avec les  bons paramètres pour
l'analyseur  JSON fourni  par `JSON::PP`.  Sauf que  certaines valeurs
contiennent des doubles quotes et  `JSON::PP` n'aime pas. Par exemple,
dans  la   propriété  `ingredients_text_with_allergens`   du  document
`"5000169107829"` du fichier `multiline-1` :

```
    ingredients_text_with_allergens: 'Cheddar cheese (<span class="allergen">milk</span>), potato starch.',
                                                                  ..........
```

La solution consiste à supprimer ces doubles quotes, même si ce n'est
plus du HTML bien formatté. Voir le résultat dans
`examples/multiline-2`.

```
    ingredients_text_with_allergens: 'Cheddar cheese (<span class=allergen>milk</span>), potato starch.',
                                                                  ........
```

Cette correction  n'est pas  faite par  `schema-check.pl`, il  faut la
faire en amont.

Description du schéma
=====================

Avertissement
-------------

Ci-dessous,  vous  lirez la  description  _progressive_  du schéma  de
données. Comme cette description est progressive, les premières étapes
de la  description pourront  être incomplètes  et contredites  par les
étapes  suivantes.  Néanmoins,  cette   progression  permet  de  mieux
comprendre comment le schéma est défini.

D'autre part, dans  ce chapitre de la documentation,  je n'utilise pas
la description la plus récente du schéma. Le 21 octobre 2024 a eu lieu
une
[refonte des fichiers sources](https://github.com/openfoodfacts/openfoodfacts-server/commit/8cb187340e912f21565c2b752c70e226a6b31ac0)
décrivant le schéma de données. Cette
refonte  devait  avoir  pour  but   d'augmenter  la  puissance  et  la
maintenabilité  du schéma  de données,  aux dépens  de sa  simplicité.
Donc, pour des raisons pédagogiques,  la description fait référence au
schéma tel  qu'il était avant le  21 octobre 2024 et  dupliqué dans le
sous-répertoire  `old-schema`  de  ce  dépôt  Git.  Pour  des  raisons
pratiques en plus des raisons  pédagogiques, j'ai choisi la version du
4 octobre, avant l'intégration le  11 octobre d'une
[_pull request_](https://github.com/openfoodfacts/openfoodfacts-server/pull/10875)
que j'ai soumise.

Première étape
--------------

Le schéma est défini dans le fichier `product.yaml` du sous-répertoire
`docs/api/ref/schemas`  du dépôt  Git  du serveur.  Le  contenu de  ce
sous-répertoire  pour  le  2024-10-04  a été  recopié,  avec  quelques
corrections, dans le sous-répertoire `old-schema` du présent dépôt (la
version à jour  étant recopiée dans le  sous-répertoire `schemas`). En
enlevant le libellé documentaire, le fichier contient :

```
type: object
allOf:
  - $ref: './product_base.yaml'
  - $ref: './product_misc.yaml'
  - $ref: './product_tags.yaml'
  - $ref: './product_images.yaml'
  - $ref: './product_ecoscore.yaml'
  - $ref: './product_ingredients.yaml'
  - $ref: './product_nutrition.yaml'
  - $ref: './product_quality.yaml'
  - $ref: './product_extended.yaml'
  - $ref: './product_meta.yaml'
  - $ref: './product_knowledge_panels.yaml'
```

La première ligne (`type: object`)  nous apprend qu'un document est un
objet JSON, commençant  par une accolade ouvrante,  se poursuivant par
des paires clé-valeur et se  terminant par une accolade fermante. Mais
quelles sont les paires clé-valeur  autorisées ? Comme on le devine en
lisant le  contenu du fichier YAML,  il faut aller voir  dans d'autres
fichiers, le mot-clé `$ref` fonctionnant  ici comme un `#include` en C
ou un `require` en Perl.

Le mot-clé `$ref` est utilisé  12 fois dans le fichier `product.yaml`,
mais il est  utilisé également dans les autres fichiers.  Au total, il
est utilisé  52 fois, 49  fois pour  importer un fichier  extérieur, 3
fois pour un autre mécanisme (décrit
[ultérieurement](#user-content-les-clés-ref-restantes)).

Paires clé-valeur
-----------------

Voici un extrait du fichier `product_base.yaml`.

```
type: object
description: |
  Base product data
properties:
  abbreviated_product_name:
    type: string
    description: Abbreviated name in requested language
  code:
    type: string
    description: |
      barcode of the product (can be EAN-13 or internal codes for some food stores),
      for products without a barcode,
      Open Food Facts assigns a number starting with the 200 reserved prefix
  nova_group:
    type: integer
    description: |
      Nova group as an integer from 1 to 4. See https://world.openfoodfacts.org/nova
  product_name:
    type: string
    description: |
      The name of the product
  product_name_en:
    type: string
    description: |
      The name of the product can also
      be in many other languages like
      product_name_fr (for French).
  product_quantity:
    type: string
    description: |
      The size in g or ml for the whole product.
      It's a normalized version of the quantity field.
    example: "500"
```

Cela correspond à ce document :

```
{
        "code" : "00187251",
        "product_name_en" : "choclatey cats",
        "nova_group" : 4,
        "product_name" : "choclatey cats",
        "product_quantity" : 453.59237
}
```

Ainsi  qu'on  peut le  voir,  les  clés  sont facultatives,  comme  en
témoigne la clé `abbreviated_product_name` absente du document servant
d'exemple. D'autre part, l'ordre des clés n'a pas d'importance. La clé
`product_name_en` arrive après `nova_group`  et `product_name` dans le
schéma, elle arrive avant dans le document.

La question  que je  me pose  d'après cet exemple  est le  contrôle de
format des  valeurs. Pour l'information `product_quantity`,  le format
attendu est une chaîne de caractères,  alors que la valeur stockée est
un nombre décimal.  Suis-je tombé sur un cas d'erreur  à signaler ? Ou
bien  l'indication  du  schéma  est-elle  juste  une  indication  sans
importance ?

Clés génériques
---------------

Prenons maintenant un extrait du fichier `product_ingredients.yaml`.

```
type: object
description: Fields about ingredients of a product
properties:
  ingredients_text:
    type: string
  ingredients_text_with_allergens:
    type: string
patternProperties:
  'ingredients_text_(?<language_code>\w\w)':
    type: string
    description: |
      Raw list of ingredients in language given by 'language_code'.

      See `ingredients_text`
  'ingredients_text_with_allergens_(?<language_code>\w\w)':
    description: |
      Like `ingredients_text_with_allergens` for a particular language
    type: string
```

Cela correspond au document ci-dessous (extrait du document `00187251`) :

```
{
        "ingredients_text_en" : "unbleached enriched flour ( wheat  flour, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, soy lecithin (an emulsifier), contain  wheat , soy, may contain traces of peanuts and tree nuts,",
        "ingredients_text_with_allergens_en" : "unbleached enriched flour ( <span class=\"allergen\">wheat  flour</span>, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, <span class=\"allergen\">soy lecithin</span> (an emulsifier), contain  wheat , <span class=\"allergen\">soy</span>, may contain traces of <span class=\"allergen\">peanuts</span> and <span class=\"allergen\">tree nuts</span>,",
        "ingredients_text_with_allergens" : "unbleached enriched flour ( <span class=\"allergen\">wheat  flour</span>, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, <span class=\"allergen\">soy lecithin</span> (an emulsifier), contain  wheat , <span class=\"allergen\">soy</span>, may contain traces of <span class=\"allergen\">peanuts</span> and <span class=\"allergen\">tree nuts</span>,",
        "ingredients_text" : "unbleached enriched flour ( wheat  flour, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, soy lecithin (an emulsifier), contain  wheat , soy, may contain traces of peanuts and tree nuts,"
}

```

On retrouve les clés spécifiques `ingredients_text` et
`ingredients_text_with_allergens`, mais on trouve aussi les clés
`ingredients_text_en` et `ingredients_text_with_allergens_en` qui ne
figurent pas directement dans le schéma. Elles y figurent
indirectement, avec les expressions rationnelles
`ingredients_text_(?<language_code>\w\w)` et
`ingredients_text_with_allergens_(?<language_code>\w\w)`.

Je n'ai pas  trouvé d'exemple de document JSON où  ces clés génériques
permettent  le  multi-linguisme au  sein  du  document. Néanmoins,  je
suppose qu'il  ne faut  pas faire  de contrôle  d'unicité, car  il est
parfaitement  possible   d'avoir  dans  un  même   document  plusieurs
exemplaires d'une même clé générique :

```
{
  "ingredients_text_fr": "eau",
  "ingredients_text_en": "water",
  "ingredients_text_de": "wasser"
}
```

Dans le programme de vérification, il faut bien prendre soin
d'encadrer les expressions rationnelles par des balises début-fin
`/^ ... $/`. Sinon, on pourrait trouver une clé
`"ingredients_text_(?<language_code>\w\w)"` avec un code langue
`"with_allergens"`, ou plus précisément `"wi"`. Ça ferait désordre...

Ces clés  servent donc  au multilinguisme. Cela  dit, si  vous relisez
l'exemple du
[paragraphe précédent](#user-content-paires-clé-valeur)
sur  les  paires  clé-valeur   spécifiques,  vous  trouverez  une  clé
`product_name_en`  en   plus  de   la  clé  `product_name`,   donc  un
multilinguisme partiel obtenu avec des clés spécifiques.

On   trouve  également   des   clés  génériques   dans  les   fichiers
`nutrition_search.yaml` et `product_nutrition.yaml`,  pour définir une
série  de propriétés  en combinant  un  cas d'usage  et un  nutriment.
Exemple extrait de `product_nutrition.yaml`

```
    patternProperties:
      '(?<nutrient>[\w-]+)_unit':
        description: |
          The unit in which the nutrient for 100g or per serving is measured.

          The possible values depends on the nutrient.

          * `g` for grams
          * `mg` for milligrams
          * `μg` for micrograms
          * `cl` for centiliters
          * `ml` for mililiters
          * `dv` for recommended daily intakes (aka [Dietary Reference Intake](https://en.wikipedia.org/wiki/Dietary_Reference_Intake))
          * `% vol` for alcohol vol per 100 ml
        type: string
      '(?<nutrient>[\w-]+)_100g':
        description: |
          The standardized value of a serving of 100g (or 100ml for liquids)
          for the nutrient.
        type: number
      '(?<nutrient>[\w-]+)_serving':
        description: |
          The standardized value of a serving for this product.
        type: number
```

Et dans le produit `"00187251"`, on trouve :

```
        "nutriments" : {
                "fruits-vegetables-nuts-estimate-from-ingredients_serving" : 0,
                "fiber_100g" : 3.3333333333333,
                "sugars_unit" : "g",
                "nova-group_serving" : 4,
                "salt_100g" : 0.70833333333333,
                "sodium_100g" : 0.283333333333332,
                "proteins_100g" : 6.6666666666667,
                "energy-kcal_unit" : "kcal",
                "fruits-vegetables-legumes-estimate-from-ingredients_serving" : 0,
                "proteins_unit" : "g",
                "fruits-vegetables-legumes-estimate-from-ingredients_100g" : 0,
                (etc)
        },
```

Cela permet d'identifier les cas d'usage suivants :

* `serving`,
* `100g`,
* `unit`

ainsi que les nutriments suivants :

* `fruits-vegetables-nuts-estimate-from-ingredients`,
* `fiber`,
* `sugar`,
* `salt`,
* `sodium`,
* `proteins`
* `fruits-vegetables-legumes-estimate-from-ingredients`

et même quelques pseudo-nutriments comme :

* `nova-group`,
* `energy-kcal`.

Champs implicites
-----------------

Reprenons le document du
[paragraphe sur les clés spécifiques](#user-content-paires-clé-valeur).
En réalité, ce document contient plutôt :

```
{
        "_id" : "00187251",
        "code" : "00187251",
        "product_name_en" : "choclatey cats",
        "nova_group" : 4,
        "product_name" : "choclatey cats",
        "product_quantity" : 453.59237,
        "_keywords" : [
                "cat",
                "trader",
                "joe",
                "choclatey"
        ]
}
```

J'ai  déjà entendu  parler  de la  clé `"_id"`.  C'est  dans le  livre
O'Reilly sur les  bases MongoDB, écrit par
[Kristina  Chodorow](https://www.oreilly.com/pub/au/4500).
Si l'on alimente une base MongoDB avec un document ne contenant pas de
paire   clé-valeur  avec   `"_id"`,  alors   MongoDB  en   ajoute  une
automatiquement.

Le livre de  Kristina Chodorow ne mentionne pas  la clé `"_keywords"`.
Néanmoins, à  cause du  caractère souligné  initial, je  suppose qu'il
pourrait s'agir également d'une clé implicite, même si son ajout n'est pas
systématique. Cependant, comme ce n'est pas une certitude, je continue
à déclencher un message d'erreur sur cette clé.

Dans un premier temps, j'ai décidé de :

1. insérer arbitrairement le champ `"_id"` dans le schéma,

2. procrastiner,

3. créer et soumettre une  _pull request_ demandant d'insérer le champ
`"_keywords"` dans le fichier `product_meta.yaml`.

Pendant que je procrastinais, je suis  tombé par hasard sur le fichier
`product_hidden.yaml`, qui décrit les champs `"_id"` et `"_keywords"`,
ainsi que de nombreux autres champs  auxquels je ne m'étais pas encore
intéressé. Ce  fichier n'est  pas inclus  dans `product.yaml`  par une
entrée `"$ref"`,  car il s'agit  de champs  à usage interne,  que l'on
évite donc d'ajouter à l'API publique.

L'étape 3  a consisté alors  à revenir en arrière  sur l'étape 1  et à
adapter   le  programme   `schéma-check.pl`  pour   inclure  également
`product_hidden.yaml`  dans  le  schéma. J'avais  prévu  d'ajouter  un
nouveau paramètre  appelé `--hidden-schema`. Après une  nouvelle étape
de procrastination, j'ai  trouvé qu'il était plus  simple de convertir
le paramètre scalaire `--schema` en paramètre liste.

Données multi-niveaux
---------------------

Dans une  paire clé-valeur, la  valeur n'est pas forcément  une valeur
scalaire : entier, flottant ou chaîne de caractères. Cela peut être un
objet  JSON à  part entière.  Prenons encore  une fois  un extrait  du
document `"00187251"`.

```
{
        "_id" : "00187251",
        "ecoscore_data" : {
                "status" : "unknown",
                "missing" : {
                        "origins" : 1,
                        "labels" : 1
                },
                "adjustments" : {
                        "packaging" : {
                                "score" : -79,
                                "non_recyclable_and_non_biodegradable_materials" : 1,
                                "value" : -15,
                        },
                        "production_system" : {
                                "value" : 0,
                                "warning" : "no_label"
                        },
                        "origins_of_ingredients" : {
                                "epi_score" : 0,
                                "epi_value" : -5,
                                "transportation_values" : {
                                        "no" : 0,
                                        ...
                                        "eg" : 0,
                                        "world" : 0,
                                        "ad" : 0,
                                        "se" : 0
                                },
                                "transportation_scores" : {
                                        "va" : 0,
                                        ...
                                        "it" : 0,
                                        "world" : 0,
                                        "ba" : 0,
                                        ...
                                        "at" : 0
                                },
                                "values" : {
                                        "lu" : -5,
                                        ...
                                        "it" : -5,
                                        "world" : -5,
                                        "ba" : -5,
                                        ...
                                        "ax" : -5
                                },
                                "warning" : "origins_are_100_percent_unknown"
                        },
                        "threatened_species" : {
                                "value" : -10,
                                "ingredient" : "en:palm-oil"
                        }
                }
        }
}
```

Cela   correspond    au   schéma    suivant,   extrait    du   fichier
`product_ecoscore.yaml`.   J'ai   légèrement    changé   l'ordre   des
définitions, pour mieux coller aux données ci-dessus.

```
type: object
description: |
  Fields related to Eco-Score for a product.

  See also: `ecoscore_score`, `ecoscore_grade` and `ecoscore_tags`.

properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      status:
        type: string
      missing:
        type: object
        properties:
          labels:
            type: integer
          origins:
            type: integer
          packagings:
            type: integer
      adjustments:
        type: object
        properties:
          packaging:
            type: object
            properties:
              non_recyclable_and_non_biodegradable_materials:
                type: integer
              score:
                type: integer
              value:
                type: integer
              warning:
                type: string
          production_system:
            type: object
            properties:
              value:
                type: integer
              warning:
                type: string
          origins_of_ingredients:
            type: object
            properties:
              epi_score:
                type: integer
              epi_value:
                type: integer
              transportation_values:
                type: object
                patternProperties:
                  (?<language_code>\w\w):
                    type: integer
              transportation_scores:
                type: object
                patternProperties:
                  (?<language_code>\w\w):
                    type: integer
              values:
                type: object
                patternProperties:
                  (?<language_code>\w\w):
                    type: integer
              warning:
                type: string
          threatened_species:
            type: object
            properties:
              ingredient:
                type: string
              value:
                type: integer
```

Comme on peut le voir, en plus des types `string` et `integer`, il y a
le type `object`, qui est accompagné  par la liste des `properties` ou
des `patternProperties`  (ou les deux). Et  dans ces « `properties` »,
on peut  avoir de nouveau des  types `integer` et des  types `string`,
mais aussi des types `object` avec la description associée.

Une petite  remarque en  passant. Les  clés `"transportation_scores"`,
`"transportation_values"`   et    `"values"`   admettent    des   clés
subordonnées `"(?<language_code>\w\w)"`.  Néanmoins, on trouve  la clé
`"world"` qui  n'est pas un  code langue connu et  qui ne colle  pas à
l'expression  rationnelle.  D'où  un   message  d'erreur  lors  de  la
vérification. Cette remarque a donné lieu à la
[_pull request_ intégrée le 2024-10-11](https://github.com/openfoodfacts/openfoodfacts-server/pull/10875).
dans le dépôt OFF,  donc après la version récupérée dans
le sous-répertoire `old-schema` du présent  dépôt. De plus, le fichier
`product_ecoscore.yaml`  a été  scindé le  19 novembre  pour créer  le
fichier  `ecoscore-country-code.yaml`  et  l'utilisation  d'expression
rationnelle est passée à la trappe dans ce nouveau fichier.

Chaque  niveau  d'emboîtement  du  texte JSON  contenant  les  données
correspond à deux  niveaux du texte YAML décrivant le  schéma. Si l'on
compte les  niveaux YAML à  partir de 0, les  niveaux pairs (0,  2, 4,
etc) contiennent des clés techniques :

* `description`,
* `type`,
* `properties`,
* `patternProperties`

et  d'autres que  nous  n'avons pas  encore  rencontrées. Les  niveaux
impairs contiennent des clés « métier » :

* `ecoscore_data`,
* `status`,
* `missing`,
* `labels`,
* `origins`

et ainsi de  suite. Dans la suite, j'utiliserai  le terme « attribut »
pour une clé technique et le terme « propriété » pour une clé métier.

Notons un  cas particulier.  `type` est une  clé technique,  mais dans
certains cas c'est également une  clé « métier ». Par exemple, dans le
fichier `knowledge_panels/panel.yaml` :

<pre>
<em>type:</em> object
description: Each panel contains an optional title and an optional array of elements.
properties:
  <strong>type:</strong>
    <em>type:</em> string
    description: 'Type of the panel. If set to "card", the panel and its sub-panels should be displayed in a card. If set to "inline", the panel should have its content always displayed.'
  expanded:
    <em>type:</em> boolean
    description: 'If true, the panel is to be displayed already expanded. If false, only the title should be displayed, and the user should be able to click or tap it to open the panel and display the elements.'
  expand_for:
    <em>type:</em> string
    description: 'If set to "large", the content of the panel should be expanded on large screens, but it should still be possible to unexpand it.'
</pre>

Les clés « métier » au niveau 1 sont `expanded`, `expand_for` et...
`type`. Ce qui n'empêche pas d'avoir une clé technique `type` au
niveau 0 (un exemplaire) et au niveau 2 (trois exemplaires). Le même
cas de figure se trouve dans
`knowledge_panels/elements/table_element.yaml`

<pre>
title: table_element
x-stoplight:
  id: 38zu3z4sruqo7
type: object
description: Element to display a table.
properties:
  id:
    type: string
    description: An id for the table.
  title:
    type: string
    description: |
      Title of the column.
  rows:
    type: string
  columns:
    type: array
    items:
      type: object
      properties:
        <strong>type:</strong>
          type: string
        text:
          type: string
        text_for_small_screens:
          type: string
        style:
          type: string
        column_group_id:
          type: string
        shown_by_default:
          type: boolean
</pre>

ou dans `knowledge_panels/elements/text_element.yaml`

<pre>
title: text_element
x-stoplight:
  id: vdwxlt73qnqfa
type: object
description: |-
  A text in simple HTML format to display.

  For some specific texts that correspond to a product field (e.g. a product name, the ingredients list of a product),the edit_field_* fields are used to indicate how to edit the field value.
properties:
  <strong>type:</strong>
    type: string
    description: |
      the type of text, might influence the way you display it.
    enum:
      - summary
      - warning
      - notes
  html:
    type: string
    description: Text to display in HTML format.
...
</pre>

ou encore dans `knowledge_panels/elements/title_element.yaml`

<pre>
title: title_element
x-stoplight:
  id: lox0wvl9bdgy2
type: object
description: The title of a panel.
properties:
  name:
    type: string
    description: A short name of this panel, not including any actual values
  title:
    type: string
  <strong>type:</strong>
    type: string
    enum:
      - grade
      - percentage
    description: 'Used to indicate how the value of this item is measured, such as "grade" for Nutri-Score and Eco-Score or "percentage" for Salt'
  grade:
    type: string
</pre>

Et comme on le verra
[plus tard](#user-content-attributs-propertynames-et-additionalproperties),
c'est le cas également pour le mot-clé `additionalProperties` qui peut
être soit un attribut, soit une propriété.

Tableaux
--------

Il est possible d'inclure des tableaux dans les données JSON de la base `off`.
Exemple, encore une fois tiré du produit `00187251`

```
{
        "_id" : "00187251",
        "ingredients_analysis_tags" : [
                "en:palm-oil",
                "en:vegan-status-unknown",
                "en:vegetarian-status-unknown"
        ]
}
```

Le  fichier  `product_ingredients.yaml`  contient  la  description  du
tableau :

```
  ingredients_analysis_tags:
    type: array
    items:
      type: string
```

Lorsqu'il était question  des clés techniques et des  clés métier pour
les  objets JSON,  j'ai  écrit  que les  clés  techniques étaient  aux
niveaux  pairs  et les  clés  métier  aux  niveaux impairs.  Avec  les
tableaux,   ce  n'est   plus  le   cas.  Vous   avez  la   clé  métier
`ingredients_analysis_tags` au niveau 1  et les clés techniques `type`
et `items`  au niveau  2, mais au  niveau 3 vous  avez encore  une clé
technique `type`. Tant pis, on fera attention.

Est-il possible d'avoir des tableaux d'éléments `number` ou d'éléments
`integer` ? Je pense que oui, mais je n'en ai trouvé aucun.

D'autres tableaux sont décrits ainsi (cf fichier `product_ingredients.yaml`) :

```
  ingredients_from_palm_oil_tags:
    type: array
    items:
      type: object
```

Le  problème est  que le  schéma ne  déclare pas  les clés  des objets
éléments du tableau. Pas de  `properties` ni de `patternProperties` au
niveau 3.  Est-ce une erreur  dans le  schéma, ou bien  une convention
permettant de  mettre n'importe  quoi dans  les éléments  du tableau ?
Pour  l'instant,  mon  programme  déclenche  une  erreur,  en  faisant
remarquer que  c'est une erreur du  schéma et non pas  une erreur dans
les données.

Dans certains cas,  à vrai dire moins fréquents que  le cas ci-dessus,
la  description  des  éléments  du  tableau  est  complète,  avec  des
attributs  `properties`.  Voici  une  description  à  cheval  sur  les
fichiers       `product_misc.yaml`,      `packagings/packagings.yaml`,
`packaging_component.yaml` et autres

```
  packagings:
    type: array
    items:
      type: object
      properties:
        material:
          type: object
          properties:
            id:
              type: string
            lc_name:
              type: string
        number_of_units:
          type: integer
        quantity_per_unit:
          type: string
        ...
```

Finalement,  j'ai  trouvé  un  tableau  de  tableaux.  C'est  dans  la
propriété `3` de la propriété `nova_groups_markers`, qui apparaît dans
le fichier `product_extended.yaml` :

```
  nova_groups_markers:
    type: object
    description: "Detail of ingredients or processing that makes the products having Nova 3 or 4\n"
    properties:
      3:
        type: array
        description: "Markers of level 3\n"
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
```

Les clés `$ref` restantes
-------------------------

J'ai écrit que les fichiers YAML contenaient 52 attributs `$ref`, dont
49 correspondaient à des appels de fichier similaires à `#include`. Et
les trois derniers ?

Reprenons    la    propriété    `nova_groups_markers`    du    fichier
`product_extended.yaml`. Sa description complète est :

```
type: object
properties:
  [...]
  nova_groups_markers:
    type: object
    description: |
      Detail of ingredients or processing that makes the products having Nova 3 or 4
    properties:
      "3":
        description: |
          Markers of level 3
        type: array
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
      "4":
        description: |
          Markers of level 4
        type: array
        items:
          # same as above
          $ref: "#/properties/nova_groups_markers/properties/3/items"
```

Cette  clé `$ref`  signifie  qu'il faut  recopier  la description  des
`items` de la clé  `3` dans la description des `items`  de la clé `4`.
On  reste dans  la lignée  conceptuelle des  `#include`, mais  avec un
fonctionnement concret  différent. Tout se  passe comme si  l'on avait
écrit :

```
type: object
properties:
  [...]
  nova_groups_markers:
    type: object
    description: |
      Detail of ingredients or processing that makes the products having Nova 3 or 4
    properties:
      "3":
        description: |
          Markers of level 3
        type: array
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
      "4":
        description: |
          Markers of level 4
        type: array
        items:
          # same as above
          # $ref: "#/properties/nova_groups_markers/properties/3/items"
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
```

Les deux derniers `$ref` se trouvent dans le fichier `ingredient.yaml`
et dans le  fichier `nutrients.yaml`. Voici le contenu  intégral de ce
dernier :

```
type: array
description: |
  Nutrients and sub-nutrients of a product, with their name and default unit.
items:
  type: object
  properties:
    id:
      type: string
      description: id of the nutrient
    name:
      type: string
      description: Name of the nutrient in the requested language
    important:
      type: boolean
      description: Indicates if the nutrient is always shown on the nutrition facts table
    display_in_edit_form:
      type: boolean
      description: Indicates if the nutrient should be shown in the nutrition facts edit form
    unit:
      description: Default unit of the nutrient
      $ref: "./nutrient_unit.yaml"
    nutrients:
      description: |
        Sub-nutrients (e.g. saturated-fat is a sub-nutrient of fat).
      # self recursive
      $ref: "#/"
```

Là encore,  il s'agit de  recopier un  contenu existant, ainsi  que le
fait remarquer le  commentaire. Mais ici, faute  d'avoir une sélection
sur `properties  / nova_groups_markers /  properties / 3 /  items`, le
sous-schéma sélectionné contient une référence à lui-même et il s'agit
d'une recopie récursive sans limite.  Bien sûr, dans un document JSON,
la récursion sera nécessairement limitée,  mais elle ne l'est pas dans
le  schéma  YAML.  On  utilisera  donc  une  insertion  « dynamique »,
c'est-à-dire que le  schéma sera invoqué au moment où  l'on analyse un
document JSON, il ne sera pas  copié lors de l'initialisation. Dans la
suite, je parle de « sous-schéma dynamique » pour abréger l'expression
« sous-schéma à insertion dynamique ».

Juste une petite remarque à propos de cet exemple. J'ai pris l'exemple
du fichier `nutrient.yaml`.  Or il se trouve que ce  fichier n'est pas
inclus  dans  le  schéma  principal `product.yaml`.  En  revanche,  le
fichier  `ingredient.yaml`  est  bien  utilisé  dans  le  schéma,  par
l'intermédiaire de `product_ingredients.yaml`.

Le caractère  `"#"` rappelle  les liens  hypertextes de  HTML. Peut-on
envisager de  mêler les  références à des  fichiers externes  avec les
références à une hiérarchie de clés ?  J'ai essayé de le faire dans le
fichier  `parallel-refs-1.yaml`  du sous-répertoire  `reduced-schema`.
Même si je n'ai  aucun exemple en ce sens dans  les exemples d'OFF, je
pense  que c'est  la  marche  à suivre.  (Cette  remarque est  devenue
caduque avec  la réorganisation  du 2024-10-21, il  y a  maintenant de
nombreuses  références combinant  un  nom de  fichier  externe et  une
hiérarchie de clés).

Au début, je considérais que les  clés `'$ref'` faisant référence à un
nom de fichier donneraient lieu à une insertion statique (recopie dans
la variable `$schema`) et les clés `'$ref'` constituées d'un caractère
dièse puis d'une  sélection sur clés donneraient lieu  à une insertion
dynamique. En  fait, même avec  des clés `'$ref'` faisant  référence à
des  fichiers,  on  peut  avoir  une  situation  de  poule  et  d'œuf,
nécessitant une insertion dynamique. On  peut le voir avec les schémas
`chicken.yaml`  et `egg.yaml`  du  répertoire  `reduced-schema` et  le
fichier   de   données   `chicken-and-egg.data.json`  dans   le   même
répertoire.

Donc, le programme `schema-check.pl` admet un paramètre supplémentaire
`max-depth`, avec une  valeur entière. Tant que  le niveau d'inclusion
n'a pas atteint  cette valeur `$max_depth`, le  programme effectue une
insertion statique. Si le niveau  d'inclusion dépasse cette valeur, le
programme effectue une insertion dynamique  du schéma référencé par la
clé `'$ref'`,  après avoir  vérifié qu'elle n'a  pas déjà  été insérée
dynamiquement. Ainsi, il n'y a plus de récursion infinie à craindre.

Pour  savoir si  une référence  a déjà  été insérée  dynamiquement, le
programme normalise cette référence en mettant systématiquement le nom
du fichier, un dièse et  une sélection. Si nécessaire, cette sélection
est réduite à un simple slash pour signifier que l'on prend le fichier
dans sa  totalité. Cette valeur normalisée  sert de clé à  la table de
hachage mémorisant les sous-schémas dynamiques.

Contrôle de valeur
------------------

Comme on l'a vu,  le contrôle de valeur des clés  est intrinsèque à la
description  du  schéma,  soit  par l'entrée  `properties`,  soit  par
l'entrée `patternProperties`. On  a déjà vu le cas  des codes langues,
il  y a  aussi les  tailles d'images,  ainsi que  le montre  l'extrait
suivant extrait de `image.yaml`

```
    properties:
      sizes:
        type: object
        description: |
          The available image sizes for the product (both reduced and full).
          The reduced images are the ones with numbers as the key( 100, 200 etc)
          while the full images have `full` as the key.
        patternProperties:
          (?<image_size>100|400):
            type: string
            description: |
              properties of thumbnail of size `image_size`.
              **TODO** explain how to compute name
```

Si  les  clés  sont  contrôlées,  est-ce le  cas  également  pour  les
valeurs ?  C'est   rare,  mais   cela  existe.  Voici   l'exemple  des
sous-propriétés de  la propriété `nutrient_levels` qui  se trouve dans
`product_misc.yaml`

```
  nutrient_levels:
    type: object
    description: "Traffic light indicators on main nutrients levels\n"
    properties:
      fat:
        type: string
        enum: ["low", "moderate", "high"]
      salt:
        type: string
        enum: ["low", "moderate", "high"]
      saturated-fat:
        type: string
        enum: ["low", "moderate", "high"]
      sugars:
        type: string.
        enum: ["low", "moderate", "high"]
```

Mais le  programme de  vérification n'en tient  pas compte.  On trouve
également des valeurs à titre d'exemple (attribut `example`) qui elles
non plus ne sont pas utilisées dans le programme de vérification.

Remarquons que  les tableaux sont donnés  ici avec la syntaxe  JSON au
lieu de la syntaxe YAML (des  tirets sur des lignes sucessives). C'est
valide, la spécification du langage  YAML inclut un style appelé _flow
style_ et très similaire à la syntaxe JSON.

Dans l'exemple de  tableau, vous avez pu remarquer que  les valeurs se
ressemblent,  avec un  code  langue, suivi  d'un  deux-points et  d'un
libellé.

```
                "en:palm-oil"
                "en:vegan-status-unknown"
                "en:vegetarian-status-unknown"
```

Rien dans les fichiers YAML ne permet de formaliser cette structure et
le programme de vérification ne fera rien dans ce sens non plus.

Cas particulier pour la déclaration de type
-------------------------------------------

Pour les scalaires, j'ai déjà  mentionné les types `string`, `integer`
et  `number`. Il  existe également  un  type `null`,  utilisé pour  la
propriété   `normalize`  et   la   propriété  `white_magic`   (fichier
`image_role.yaml`). Je ne sais pas à quoi cela correspond.

Parfois, certaines propriétés sont gratifiées d'une ligne :

```
        readOnly: true
```

Cela ne  concerne pas  le programme  de vérification,  qui s'intéresse
uniquement aux données de façon  statique, pas aux traitements de mise
à jour.

Il est possible d'assouplir la  vérification de type des valeurs (même
si, pour  l'instant, elle n'est  pas implémentée dans le  programme de
vérification). On  peut, par  exemple, accepter  des valeurs  de types
différents,    comme    c'est    le     cas    pour    la    propriété
`additionalProperties`  de  la  propriété  `owner_fields`  du  fichier
`product_extended.yaml`.  Il est  possible  d'utiliser  une chaîne  de
caractères, un  entier ou un  objet (dont  les propriétés ne  sont pas
précisées), mais il  est interdit d'utiliser un nombre  flottant ou un
tableau, ou un `null`.

```
  owner_fields:
    type: object
    description: |
      Those are fields provided by the producer (through producers platform),
      and the value he provided.
    properties:
      additionalProperties:
        description: |
          you can retrieve all kind of properties, the same as on the parent object (the product).
          It's not processed entries (like tags for example) but raw ones.
        oneOf:
          - type: integer
          - type: string
          - type: object
```

Dans  le   fichier  `ingredient.yaml`,   j'ai  trouvé   cette  syntaxe
également, où le  champ `type` est alimenté par une  liste.

```
        percent_estimate:
          type:
            - number
        percent_max:
          type:
            - number
```

Certes,  la liste  comporte un  seul élément,  mais on  peut envisager
qu'elle en  comporte plusieurs. Cette syntaxe  est-elle équivalente au
`oneOf`  du fichier  `product_extended.yaml`  ci-dessus ? En  d'autres
termes, peut-on avoir, par exemple, cette déclaration ?

```
        percent_estimate:
          type:
            - integer
            - number
        percent_max:
          type:
            - integer
            - number
```

Encore une curiosité,  dans le fichier `knowledge_panels  / elements /
element.yaml`, la propriété `knowledge_panels . additionalProperties .
elements[*] . type` (donc un `type` métier) n'a pas de champ technique
`type`, mais un champ technique `element_type`.

```
                type:
                  element_type: string
                  enum:
                    - text
                    - image
                    - action
                    - panel
                    - panel_group
                    - table
                  description: |
                    The type of the included element object.
                    The type also indicates which field contains the included element object.
                    e.g. if the type is "text", the included element object will be in the "text_element" field.

                    Note that in the future, new type of element may be added,
                    so your code should ignore unrecognized types, and unknown properties.

                    TODO: add Map type
```

Finalement, j'avais une interrogation sur l'attribut
`additionalProperties`, mais j'ai trouvé la
[réponse](#user-content-attributs-propertynames-et-additionalproperties),
après le 2024-10-21.

Interlude
---------

Même si j'ai encore quelques interrogations, j'arrête là l'exploration
du schéma  du 2024-10-04.  J'examine maintenant  la version  du schéma
[après le 2024-10-21](https://github.com/openfoodfacts/openfoodfacts-server/commit/8cb187340e912f21565c2b752c70e226a6b31ac0).

Entrées $ref
------------

Ainsi que  je l'avais prévu,  il existe des  entrées `$ref` avec  à la
fois un nom de fichier et une hiérarchie de clés. Quelques exemples :

```
product_ecoscore.yaml:    $ref: "./ecoscore-country-code.yaml#/components/schemas/EcoscoreCountryValues"
product_images.yaml:      $ref: "./image_role.yaml#/components/schemas/ImageRole"
product_images.yaml:      $ref: "./image.yaml#/components/schemas/Image"
product_images.yaml:      $ref: "./image_urls.yaml#/components/schemas/SelectedImage"
product_ingredients.yaml: $ref: "./ingredient.yaml#/components/schemas/Ingredients"
```

Ce  que je  n'avais  pas prévu,  c'est que  cela  apparaîtrait dès  le
premier niveau, dans `product.yaml` :

```
type: object
allOf:
  - $ref: "../api.yml#/components/schemas/Product-Base"
  - $ref: "../api.yml#/components/schemas/Product-Misc"
  - $ref: "../api.yml#/components/schemas/Product-Tags"
  - $ref: "../api.yml#/components/schemas/Product-Images"
  - $ref: "../api.yml#/components/schemas/Product-Eco-Score"
  - $ref: "../api.yml#/components/schemas/Product-Ingredients"
  - $ref: "../api.yml#/components/schemas/Product-Nutrition"
  - $ref: "../api.yml#/components/schemas/Product-Nutriscore"
  - $ref: "../api.yml#/components/schemas/Product-Data-Quality"
  - $ref: "../api.yml#/components/schemas/Product-Extended"
  - $ref: "../api.yml#/components/schemas/Product-Metadata"
  - $ref: "../api.yml#/components/schemas/Product-Knowledge-Panels"
  - $ref: "../api.yml#/components/schemas/Product-Attribute-Groups"
```

Attribut `oneOf`
----------------

J'ai   déjà  signalé   avoir   vu  cet   attribut   dans  le   fichier
`product_extended.yaml` d'avant le 2024-10-21  et j'avais décidé de ne
pas  en tenir  compte. Maintenant,  je le  rencontre également  à deux
endroits de `product_ingredients.yaml` :

```
  traces_hierarchy:
    type: array
    items:
      oneOf:
        - type: "object"
        - type: "string"
  traces_lc:
    type: string
  traces_tags:
    type: array
    items:
      oneOf:
        - type: "object"
        - type: "string"
```

La  différence avec  `product_extended.yaml`  est  qu'il s'agit  cette
fois-ci  des éléments  de deux  tableaux et  non plus  d'une propriété
définie par une clé.

Concernant la  définition des  objets, il s'agit  d'objets génériques,
pour  lesquels   aucune  propriété  n'est  déclarée,   ce  qui  arrive
fréquemment  avec  les  objets  éléments d'un  tableau  sans  attribut
`oneOf`.  Donc,  si le  programme  de  vérification tient  compte  des
entrées  `oneOf` pour  ses contrôles,  cela fait  que dans  le cas  où
l'élément du tableau  JSON est un objet et non  pas un scalaire chaîne
de caractères, le message

```
Invalid schema, no item type for top traces_hierarchy
```

disparaîtra et sera remplacé par le message

```
Invalid schema, no properties defined for top traces_hierarchy [0]
```

Mais c'est mieux ainsi. Au moins, si l'élément de tableau JSON est une
chaîne de caractères, le message aura disparu à juste titre.

On pourrait envisager que le schéma définisse des propriétés pour ces
objets, comme cela arrive avec quelques objets éléments d'un tableau
comme le tableau `packagings` décrit dans
`packagings/packagings.yaml`. Exemple imaginé :

```
  traces_hierarchy:
    type: array
    items:
      oneOf:
        - type: "object"
          properties:
            property1: string
            property2: integer
        - type: "string"
  traces_lc:
    oneOf:
      - type: string
      - type: object
        properties:
          foo: string
          bar: integer
  traces_tags:
    type: array
    items:
      oneOf:
        - type: "object"
          properties:
            some_property: string
            another_property: integer
        - type: "string"
```

Attributs `propertyNames` et `additionalProperties`
---------------------------------------------------

Revenons  à  l'exemple des  données  multi-niveaux  et à  la  remarque
mentionnant la
[_pull request_ du 2024-10-11](https://github.com/openfoodfacts/openfoodfacts-server/pull/10875).
Elle   avait  consisté   d'une  part   à  remplacer   la  dénomination
`language_code`  par  `country_code` et  d'autre  part  à ajouter  une
propriété `world` en plus de  la propriété générique à deux caractères
`country_code`. Le fichier `product_ecoscore.yaml` contenait alors :

```
              transportation_scores:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
              transportation_values:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
              values:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
```

Avec cette  définition, il n'y a  pas de contrôle de  valeur des codes
pays,  tout  code constitué  de  deux  caractères alphanumériques  est
correct. Donc, le 2024-10-19, l'équipe OFF a intégré une nouvelle
[_pull request_](https://github.com/openfoodfacts/openfoodfacts-server/pull/11009)
pour énumérer les valeurs autorisées pour les codes pays.

Ont-ils écrit quelque chose comme :

```
              transportation_scores:
                type: object
                properties:
                  world:
                    type: integer
                  be:
                    type: integer
                  de:
                    type: integer
                  fr:
                    type: integer
                  # [...]
              transportation_values:
                type: object
                properties:
                  world:
                    type: integer
                  be:
                    type: integer
                  de:
                    type: integer
                  fr:
                    type: integer
                  # [...]
              values:
                type: object
                properties:
                  world:
                    type: integer
                  be:
                    type: integer
                  de:
                    type: integer
                  fr:
                    type: integer
                  # [...]
```

Non, c'est assez peu commode, il faut écrire deux lignes par code pays
pour `transportation_scores`, deux lignes par code pays également pour
`transportation_values` et  deux lignes  par code pays  également pour
`values`.  Si ces  propriétés avaient  été des  objets plutôt  que des
scalaires, le  nombre de lignes par  code pays aurait été  encore plus
élevé, conduisant  à encore  plus de  duplication de  code et  plus de
redondance.

Ils auraient pu écrire

```
              transportation_scores:
                type: object
                patternProperties:
                  (?<country_code>world|be|de|fr):
                    type: integer
              transportation_values:
                type: object
                patternProperties:
                  (?<country_code>world|be|de|fr):
                    type: integer
              values:
                type: object
                patternProperties:
                  (?<country_code>world|be|de|fr):
                    type: integer
```

avec  63  possibilités  au  lieu   de  4  dans  les  deux  expressions
rationnelles. Cela aurait donné deux  lignes de source très longues et
peu ergonomiques.

La solution consiste à utiliser une nouvelle syntaxe.

```
              transportation_scores:
                type: object
                propertyNames:
                  type: string
                  enum:
                    ['be', 'de', 'fr', ... 'world']
                additionalProperties:
                  type: integer
              transportation_values:
                type: object
                propertyNames:
                  type: string
                  enum:
                    ['be', 'de', 'fr', ... 'world']
                additionalProperties:
                  type: integer
              values:
                type: object
                propertyNames:
                  type: string
                  enum:
                    ['be', 'de', 'fr', ... 'world']
                additionalProperties:
                  type: integer
```

C'est un raccourci  pour spécifier _n_ propriétés  identiques avec des
noms différents énumérés dans le tableau `propertyNames`. Le code YAML
pour le tableau  peut s'écrire avec des  délimiteurs `"["`...`"]"` et,
au choix, sur une seule ligne  très longue ou sur plusieurs lignes (il
s'agit du _flow style_ de YAML (ou « style au fil de l'eau »). Mais on
aurait pu  utiliser le _block style_  (ou « style en blocs »)  avec 63
lignes constituées d'un tiret et d'un seul code pays.

Pour aller plus loin, la définition du tableau `transportation_scores
/ propertyNames`, celle du tableau `transportation_values /
propertyNames` et celle du tableau `values / propertyNames` ont été
remplacées toutes trois par un appel `$ref` au composant `components /
schemas / EcoscoreCountryCode` du fichier
`ecoscore-country-code.yaml`. L'avantage supplémentaire est que l'on
sait que les valeurs autorisées pour `transportation_scores`, celles
pour `transportation_values` et celles pour `values` sont exactement
les mêmes.

Si  vous regardez,  c'est en  fait deux  appels `$ref`  successifs, le
composant  `components  /  schemas /  EcoscoreCountryValues`  puis  le
composant  `components /  schemas  /  EcoscoreCountryCode` du  fichier
`ecoscore-country-code.yaml`.

On trouve également un couple `additionalProperties / propertyNames`
dans le fichier `product_images.yaml` et dans le fichier
`product_extended.yaml`, au sein de `nova_groups_markers`.

Dans   la  propriété   `category_properties`   de   ce  même   fichier
`product_extended.yaml`,     on     voit     apparaître     l'attribut
`additionalProperties`  sans  qu'il  soit  complété  par  un  attribut
`propertyNames`.  Attention, il  s'agit bien  de `category_properties`
avec  un   « `y` »,  ne  regardez  pas   `categories_properties`  avec
« `ies` ». Puisqu'il  n'y a  pas de `propertyNames`,  faut-il accepter
toutes les valeurs possibles ?

En regardant  les exemples  de `products-324.json`,  il semble  que ce
soit le cas. Voici quelques exemples tirés de ce fichier dans lesquels
l'objet associé à `categories_properties` n'est pas un objet vide. Les
clés sont  les mêmes, d'un document  à l'autre mais on  peut envisager
d'autres. Donc oui, il faut accepter toutes les valeurs possibles.

```
{
   "_id" : "0052833225082",
   "category_properties" : {
      "ciqual_food_name:en" : "Cheddar cheese, from cow's milk",
      "ciqual_food_name:fr" : "Fromage -aliment moyen-"
   }
}
{
   "_id" : "0078742054797",
   "category_properties" : {
      "ciqual_food_name:en" : "Sausage -average-",
      "ciqual_food_name:fr" : "Saucisse -aliment moyen-"
   }
}
{
   "_id" : "0078742102047",
   "category_properties" : {
      "ciqual_food_name:en" : "Cheddar cheese, from cow's milk",
      "ciqual_food_name:fr" : "Fromage -aliment moyen-"
   }
}
```

Et comme on l'a déjà vu pour `type`, le mot-clé `additionalProperties`
peut  parfois apparaître  comme  une propriété  (c'est-à-dire une  clé
métier).  C'est   le  cas   dans  la  propriété   `owner_fields`  dans
`product_extended.yaml`. Il y a même  un commentaire pour souligner le
fait.

```
  owner_fields:
    type: object
    description: |
      Those are fields provided by the producer (through producers platform),
      and the value he provided.
    properties:
      additionalProperties: # !!! here "additionalProperties" is the name of the property
        description: |
          you can retrieve all kind of properties, the same as on the parent object (the product).
          It's not processed entries (like tags for example) but raw ones.
        oneOf:
          - type: integer
          - type: string
          - type: object
```

C'est le cas également dans le fichier `knowledge_panels/panels.yaml`,
mais sans commentaire pour souligner ce fait.

Déroulement
===========

Extraction du schéma
--------------------

Les fichiers  `product.yaml` et `product_hidden.yaml` sont  chargés et
convertis pour donner le schéma de données.

Pour chaque  fichier, le  programme traite en  boucle les  entrées des
attributs  `properties`  et  `patternProperties`, s'ils  existent.  Il
traite  également les  entrées de  l'attribut `allOf`,  également s'il
existe. Chacune de ces entrées a pour clé `$ref` et pour valeur un
nom de  fichier contenant un  schéma partiel (appelé  sous-schéma dans
cette documentation).  À chaque itération  de la boucle,  le programme
charge le  fichier désigné, le  convertit en donnée interne.  Il copie
chaque  entrée  subalterne  de  l'entrée  `properties`  vers  l'entrée
`properties` du  schéma (créée si  besoin). Le programme fait  de même
avec  les entrées  `patternProperties`  du  sous-schéma, copiées  vers
l'entrée `patternProperties` du schéma.

Avant  d'ajouter le  contenu du  sous-schéma au  schéma principal,  on
cherche si ce  sous-schéma contient des sous-sous-schémas.  Si tel est
le cas,  on insère  le sous-sous-schéma dans  le sous-schéma  avant de
l'insérer  dans  le schéma.  Et  si  besoin,  cette recherche  et  ces
insertions se font  récursivement. Avec un exemple,  c'est plus clair.

Voici un extrait du fichier `product.yaml` (version avant le 2024-10-21) :

```
type: object
description: |
  This is all the fields describing a product and how to display it on a page.
allOf:
  - $ref: './product_ecoscore.yaml'
```

Voici un extrait du fichier `product_ecoscore.yaml` :

```
type: object
properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      agribalyse:
        $ref: "./agribalyse.yaml"
      grade:
        type: string
      previous_data:
        type: object
        properties:
          grade:
            type: string
          score:
            type: integer
          agribalyse:
            $ref: "./agribalyse.yaml"
```

et un extrait du fichier `agribalyse.yaml` :

```
type: object
properties:
  agribalyse_food_code:
    type: string
  co2_agriculture:
    type: number
```

Le schéma obtenu sera une variable Perl correspondant au texte YAML suivant :

```
type: object
allOf:
  - $ref: './product_ecoscore.yaml'
properties:
  ecoscore_data:
    type: object
    properties:
      agribalyse:
        $ref: "./agribalyse.yaml"
        type: object
        properties:
          agribalyse_food_code:
            type: string
          co2_agriculture:
            type: number
      grade:
        type: string
      previous_data:
        type: object
        properties:
          grade:
            type: string
          score:
            type: integer
          agribalyse:
            $ref: "./agribalyse.yaml"
            type: object
            properties:
              agribalyse_food_code:
                type: string
              co2_agriculture:
                type: number
```

On peut remarquer  que les attributs `$ref` sont  conservés, cela peut
servir  pour le  débugage. En  revanche,  on peut  laisser tomber  les
champs `description` et `example`.

### Références récursives avant le 2024-10-21

Les    trois    `'$ref'`   spéciaux,    dans    `nova_groups_markers`,
`nutrient.yaml` et `ingredient.yaml`, sont  traités comme les `'$ref'`
qui appellent simplement un fichier,  avec une légère différence. Dans
le cas de la propriété `nova_groups_markers`, le sous-schéma dynamique
ne correspond  pas à  la totalité du  fichier `product_extended.yaml`,
mais à  une partie très réduite  de l'arborescence, en fonction  de la
sélection `properties / nova_groups_markers / properties / 3 / items`.
Avant  de charger  l'attribut  `schema` du  sous-schéma, le  programme
effectue cette sélection.

Toutefois,  on tient  compte  du niveau  d'imbrication  des appels  de
référence.   Si  ce   niveau   d'imbrication   dépasse  le   paramètre
`--max-depth`, alors on bascule du mécanisme d'insertion statique vers
le mécanisme  d'insertion dynamique.  Le programme ajoute  un attribut
`dyn_sch` (schéma  dynamique) contenant  la référence  complète. Cette
référence  complète   est  constituée   du  chemin  du   fichier  avec
l'arborescence  des répertoires,  d'un caractère  `'#'`, et  enfin des
sélections dans  l'arborescence des clés  de hachage séparées  par des
slashs. S'il  n'y a pas de  sélection dans l'arborescence des  clés de
hachage, la référence complète comportera quand même un simple slash à
la suite du dièse. En même temps que l'attribut `dyn_sch` est alimenté
dans le schéma principal, le programme ajoute une entrée dans la liste
`@dyn_sch_to_do`  avec   toutes  les  informations   nécessaires  pour
identifier et extraire le sous-schéma dynamique.

Ensuite, une fois  que le schéma principal est  entièrement chargé, le
programme  déroule la  variable `@dyn_sch_to_do`  pour charger  chaque
sous-schéma  dynamique  et  le  stocker   dans  la  table  de  hachage
`%dyn_schema`, sauf si la référence complète a déjà été traitée.

Remarquons  que   si  l'on   appelle  le  programme   avec  l'attribut
`--max-depth=1`, alors  presque tous les attributs  `'$ref'` donneront
lieu à  une insertion dynamique. Les  seuls qui se traduiront  par une
insertion  statique sont  les  12 `'$ref'`  de  l'attribut `allOf`  du
fichier   `product.yaml`.   Mais   avec    la   valeur   par   défaut,
`--max-depth=5`,  seul l'appel  récursif  de `ingredients.yaml`  donne
lieu à une insertion dynamique, après  avoir quand même donné lieu à 3
insertions statiques.

Pour  l'anecdote,  signalons que  le  parcours  de l'arborescence  des
`'$ref'`  est  un  parcours  en  profondeur  tant  que  l'on  fait  de
l'insertion statique,  mais que  cela devient  un parcours  en largeur
lorsque l'on traite les insertions dynamiques.

### Références récursives après le 2024-10-21

Avant le 21 octobre, quasiment toutes les entrées `'$ref'` dépendaient
d'une  propriété  définie  dans  le  même  fichier  YAML.  Les  seules
exceptions étaient les 12  entrées `'$ref'` du fichier `product.yaml`.
Depuis le 21  octobre, il y a aussi les  entrées `'$ref'` dépendant de
la hiérarchie  de clés  `components /  schema /  xxx` dans  le fichier
`api.yml`. Si l'on  fixe le seuil à 1 pour  les insertions dynamiques,
les entrées `'$ref'` du fichier  `api.yml` n'étaient pas stockées dans
la  table de  hachage des  sous-schémas dynamiques,  donc les  clés de
premier niveau  des documents JSON étaient  considérés comme invalides
(à part la clé `_id` chargée automatiquement).

La fonction de vérification ne  tient compte des références dynamiques
que si elles dépendent d'une propriété. Elle ne tient pas compte d'une
entrée `'$ref'`  qui concernerait la  totalité du hachage en  cours de
vérification.  J'ai   conservé  ce   principe  dans  la   fonction  de
vérification  et  j'ai  préféré   changer  la  fonction  récursive  de
chargement  du schéma.  Si une  entrée  `'$ref'` se  trouve au  niveau
principal du  fichier YAML, alors  le chargement du  fichier référencé
sera un chargement _statique_, même si l'on a dépassé le seuil pour le
niveau d'insertion.  Donc la fonction de  vérification rencontrera des
insertions  dynamiques   uniquement  dans  le  cadre   du  test  d'une
propriété.

Extraction des documents JSON
-----------------------------

Outre les  fichiers YAML du  schéma, le  programme reçoit des  noms de
fichiers. On  considère que ces  fichiers contiennent du  texte varié,
avec par moment  des documents JSON. On cherche des  documents JSON de
trois variétés. Tout d'abord, des  documents mono-lignes. Et  ce n'est
pas  grave si  l'on obtient  une ligne  de plus  de 30 000 caractères.
Ensuite,  des  documents  bien  mis en  forme,  avec  une  indentation
cohérente. Ces documents sont sur  plusieurs lignes, la première étant
constituée d'une accolade ouvrante en  début de ligne et rien d'autre,
la dernière étant constituée d'une accolade fermante en début de ligne
et rien d'autre. Et enfin des objets JSON réunis dans un tableau JSON,
délimité   par  deux  lignes  contenant chacune  un  crochet  et  rien
d'autre.

L'extraction  se fait  avec un  automate à  états finis.  Cet automate
comporte uniquement trois états, `A`, `B` et `C`. L'état initial est l'état
`A`. L'automate ne traite pas le fichier caractère par caractère, mais
ligne par ligne (pas d'utilisation de `chop` ni de `chomp`).

Dans  l'état `A`,  si  l'on tombe  sur une  ligne  commençant par  une
accolade  ouvrante  et se  terminant  par  une accolade  fermante,  le
programme appelle la  fonction de vérification du  document avec cette
ligne.

Dans l'état  `A`, si  l'on tombe  sur une  ligne constituée  d'un seul
caractère  accolade  ouvrante (plus  le  LF  ou le  CRLF),  l'automate
initialise une chaîne  de caractères avec cette  accolade ouvrante (et
la fin de ligne) et passe à l'état `B`.

Dans l'état `B`, le programme alimente la chaîne de caractères avec la
ligne lue  dans le fichier.  Si cette  ligne est constituée  d'un seul
caractère accolade fermante  (encore une fois avec un LF  ou un CRLF),
l'automate  appelle  la fonction  de  vérification  du document,  puis
transite vers l'état `A`.

Dans l'état  `A`, si  l'on tombe  sur une  ligne constituée  d'un seul
caractère crochet  ouvrant (+ LF  ou CRLF), l'automate  initialise une
chaîne de caractères  avec ce crochet ouvrant (et la  fin de ligne) et
passe à l'état `C`.

Dans l'état `C`, le programme alimente la chaîne de caractères avec la
ligne lue  dans le fichier.  Si cette  ligne est constituée  d'un seul
caractère crochet  fermant (encore une  fois avec  un LF ou  un CRLF),
l'automate  appelle  la  fonction  de vérification  de  tableau,  puis
transite vers l'état `A`.

Dans  l'état  `A`,  si  aucun  des  trois  cas  exposés  ci-dessus  ne
s'applique, le programme ignore la ligne et passe à la suivante.

Il n'y a pas de transition possible entre l'état `B` et l'état `C`.

L'état final  autorisé devrait être  l'état `A`, mais le  programme ne
contrôle pas que le fichier se  termine bien. Il se contente de fermer
le fichier et de passer au suivant s'il en reste.

Vérification du document
------------------------

Au premier  niveau, chaque  document est  une table  de hachage  ou un
tableau, ou plus précisément la référence  à une table de hachage ou à
un tableau.  Le programme  charge ce  document, du  texte JSON,  et le
convertit. Puis il appelle la  fonction de vérification d'une table de
hachage ou la fonction de vérification d'un tableau, selon le cas.

### Fonction de vérification d'une table de hachage.

La  fonction  de vérification  d'une  table  de hachage  commence  par
vérifier que la donnée est bien la référence à un hachage.

La fonction vérifie qu'il existe  bien une description pour l'objet en
cours  de vérification.  En effet,  il  arrive souvent  que le  schéma
déclare un tableau d'objets, sans préciser quelles sont les propriétés
de ces objets. Exemple dans `product_ecoscore.yaml` :

```
  environment_impact_level_tags:
    type: array
    items:
      type: object
```

Il s'agit d'une erreur sur le  schéma, pas réellement d'une erreur sur
les   données.  On   peut   remarquer  que   dans   le  même   fichier
`product_ecoscore.yaml`, on trouve  des tableaux d'objets complètement
décrits :

```
              aggregated_origins:
                type: array
                items:
                  type: object
                  properties:
                    origin:
                      type: string
                    percent:
                      type: integer
[...]
              packagings:
                type: array
                items:
                  type: object
                  properties:
                    ecoscore_material_score:
                      type: integer
                    ecoscore_shape_ratio:
                      type: integer
                    material:
                      type: string
                    shape:
                      type: string
```

Ensuite,  la fonction  déroule toutes  les  clés de  ce hachage.  Pour
chacune, la fonction teste si la  clé figure au niveau 2 dans l'entrée
`properties` du schéma. Si oui, tant mieux. Sinon, la fonction déroule
les entrées de niveau 2 dans l'entrée `patternProperties` du schéma et
compare la clé  cherchée à l'expression régulière obtenue.  Dès que la
correspondance  se  fait,  la  fonction   quitte  la  boucle  sur  les
expressions régulières.

Si  l'on  n'a trouvé  la  clé  en cours  de  traitement  ni parmi  les
`properties` ni parmi les `patternProperties`, alors c'est une erreur.

Si  le `type`  de la  propriété est  `string`, `integer`  ou `number`,
comme  dans les  exemples ci-dessous,

```
properties:
  abbreviated_product_name:
    type: string
    description: Abbreviated name in requested language
  nova_group:
    type: integer
    description: |
      Nova group as an integer from 1 to 4. See https://world.openfoodfacts.org/nova
  completeness:
    type: number
patternProperties:
  abbreviated_product_name_(?<language_code>\w\w):
    type: string
    description: Abbreviated name in language `language_code`.
```

on ne fait pas de vérification complémentaire, la paire clé-valeur est
valide (peut-être  faudrait-il vérifier quand même  la numéricité dans
le cas d'un `integer` ou d'un `number` ?).

Si  le `type`  de  la  propriété est  `object`,  comme dans  l'exemple
ci-dessous,

```
properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      adjustments:
        type: object
        properties:
          origins_of_ingredients:
            type: object
            properties:
              epi_score:
                type: integer
```

la  fonction  s'appelle  récursivement,   en  descendant  d'un  niveau
logique, c'est-à-dire de deux  niveaux physiques (`properties` puis la
valeur de la propriété).

Si le `type` de la propriété est `array`, la fonction de contrôle d'un
objet appelle récursivement la fonction de contrôle d'un tableau.

S'il  n'y a  pas d'attribut  `type`,  mais un  attribut `dyn_sch`,  le
programme récupère  le sous-schéma dynamique correspondant,  teste son
attribut `type` et, selon le  cas, appelle la vérification d'une table
de hachage ou la vérification d'un tableau.

Et si l'on n'a trouvé ni `type`, ni `dyn_sch`, alors c'est une erreur.
C'est une erreur  également si l'on a un attribut  `dyn_sch` qui donne
un sous-schéma, mais  que ce sous-schéma n'a pas  d'attribut `type` au
niveau 0.

### Fonction de vérification d'un tableau

De  façon  analogue à  la  vérification  d'un  objet, la  fonction  de
vérification d'un  tableau s'assure qu'elle  a bien reçu un  tableau à
contrôler.

La fonction de vérification d'un objet contrôle que le schéma contient
au moins une entrée `patternProperties` ou une entrée `properties`. De
la même manière, la fonction de vérification d'un tableau contrôle que
le schéma contient une entrée `items`.

Si  les éléments  du  tableau  sont censés  être  des  chaînes ou  des
numériques, pas de  contrôle supplémentaire. Si le  schéma indique que
ce sont des  objets, la fonction appelle récursivement  la fonction de
contrôle des  objets. Si d'après  le schéma  ce sont des  tableaux, la
fonction   de   vérification    d'un   tableau   s'appelle   elle-même
récursivement.

Comme pour  la vérification  d'une table  de hachage,  la vérification
d'un  tableau  peut  aller  chercher  un  sous-schéma  dynamique  avec
l'attribut `dyn_sch` pour trouver ensuite le bon attribut `type`.

Commentaires après réalisation
------------------------------

###  Fonction `find_ref_rec`

La fonction `find_ref_rec`  est destinée à la  recherche récursive des
attributs `$ref`. Au début, l'appel récursif se faisait avec :

```
  for my $key (keys %{$schema->{properties}}) {
    find_ref_rec( $schema->{properties}{$key}, $dir );
  }
```

Dans ces conditions, le schéma  généré comportait un hachage vide pour
chaque propriété de type `string`, `integer` ou `number`, et même pour
les propriétés de type `array`. Par exemple :

```
properties:
  abbreviated_product_name:
    description: Abbreviated name in requested language
    properties: {}
    type: string
  added_countries_tags:
    items:
      type: object
    properties: {}
    type: array
  additives_n:
    description: "Number of food additives.\n"
    properties: {}
    type: integer
```

La raison est  que même si la  boucle n'a aucune itération,  elle a un
effet  secondaire,   l'auto-vivification  du  hachage   référencé  par
`$schema->{properties}`.  Pour éviter  cette  auto-vivification, il  a
fallu écrire :

```
  if ($schema->{properties}) {
    for my $key (keys %{$schema->{properties}}) {
      find_ref_rec( $schema->{properties}{$key}, $dir );
    }
  }
```

Un autre point est que la  fonction `find_ref_rec` nécessite un nom de
répertoire. En effet,

* `product.yaml` inclut `./product_knowledge_panels.yaml`,

* `product_knowledge_panels.yaml` inclut `./knowledge_panels/panels.yaml`

* `panels.yaml` inclut `./panel.yaml`

mais  ce  dernier fichier  doit  se  trouver dans  le  sous-répértoire
`knowledge_panels`  du  répertoire   `$dir_sch`,  pas  dans `$dir_sch`
directement.

Un dernier point  concernant `find_ref_rec` est la mise  en cache puis
la récupération des sous-schémas invoqués  par `$ref`. Dans un premier
temps, j'ai codé :

```
    if ($ref_cache{$schema->{'$ref'}}) {
      $subschema = $ref_cache{$schema->{'$ref'}};
    }
    else {
```

Dans  l'affichage de  contrôle du  schéma, il  y avait  des références
arrières :

```
    [...]
            properties:
              full:
                $ref: ./image_size.yaml
                description: |
                  properties of fullsize image
                  **TODO** explain how to compute name
                properties:
                  h: &22
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w: &23
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
    [...]
            properties:
              100:
                $ref: ./image_size.yaml
                properties:
                  h: *22
                  w: *23
              200:
                $ref: ./image_size.yaml
                properties:
                  h: *22
                  w: *23
              400:
                $ref: ./image_size.yaml
                properties:
                  h: *22
                  w: *23
              full:
                $ref: ./image_size.yaml
                properties:
                  h: *22
                  w: *23
```

L'absence de la  clé technique `type` pour les clés  métier `h` et `w`
me  gêne  un  peu.  J'ai  donc désactivé  l'utilisation  du  cache  et
maintenant, on obtient bien :

```
            properties:
              full:
                $ref: ./image_size.yaml
                description: |
                  properties of fullsize image
                  **TODO** explain how to compute name
                properties:
                  h:
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w:
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
   [...]
            properties:
              100:
                $ref: ./image_size.yaml
                properties:
                  h:
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w:
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
              200:
                $ref: ./image_size.yaml
                properties:
                  h:
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w:
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
              400:
                $ref: ./image_size.yaml
                properties:
                  h:
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w:
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
              full:
                $ref: ./image_size.yaml
                properties:
                  h:
                    description: "The height of the reduced/full image in pixels.\n"
                    example: 400
                    type: integer
                  w:
                    description: "The width of the reduced/full image in pixels.\n"
                    example: 255
                    type: integer
```

###  Fonction `check_hash`

Lors du test d'une donnée avec une expression régulière tirée de
`patternProperties`, il ne faut pas tester avec :

```
        if ($key =~ $patt) {
```

car on pourrait avoir une correspondance entre la chaîne

```
ingredients_text_with_allergens_en
```

et l'expression régulière

```
ingredients_text_(?<language_code>\w\w)
```

et  en capturant  le `language_code`  à `wi`,  alors que  l'expression
régulière

```
ingredients_text_with_allergens_(?<language_code>\w\w)
```

est plus appropriée.  Il faut donc tester avec

```
        if ($key =~ /^ $patt $/x) {
```

en balisant avec le début et la fin de la chaîne de caractères et on a
bien le `language_code` capturé égal à `en`.

### JSON ou JSON5 ? Quel module Perl ?

Ainsi qu'il a été écrit dans le
[paragraphe sur l'extraction de données](#user-content-où-trouver-des-données-de-test-),
l'utilitaire CLI  `mongosh` formatte  les données JSON  avec certaines
caractéristiques  de JSON5 :  pas de  quotes  pour les  clés dans  les
paires clé-valeur,  parfois des simples  quotes pour les  valeurs dans
les paires  clé-valeur. Faut-il donc  abandonner la version 4  de JSON
pour adopter
[JSON5](https://json5.org/) ?

J'ai essayé d'utiliser le
[module Perl JSON5](https://metacpan.org/pod/JSON5).
Résultat, de nombreux messages d'erreur

```
Deep recursion on subroutine "JSON5::Parser::_parse_object_kv" at /home/jf/perl5/lib/perl5/JSON5/Parser.pm line 189.
```

En consultant le  source Perl et en faisant des tests complémentaires,
j'ai trouvé que  cela se produisait lorsqu'un objet  JSON comporte une
centaire de  paires clé-valeur. Je n'ai  même pas eu besoin  de tester
des structures emboîtées. J'ai soumis un
[rapport de bug](https://github.com/karupanerura/p5-JSON5/issues/2).
En attendant, il faut trouver autre chose que `JSON5.pm`.

Parmi les modules Perl permettant d'analyser du JSON, j'ai regardé
[`JSON::PP`](https://metacpan.org/pod/JSON::PP).

La première  raison, c'est  qu'un module  pur Perl  est plus  simple à
installer  qu'un  module   XS  et  que  je  n'ai   pas  de  contrainte
particulière pour les performances.

Lorsque j'ai été confronté aux extractions par `mongosh`, qui utilisent
certaines particularités de JSON5, j'ai relu la documentation de
`JSON::PP` et j'ai découvert
[l'option `allow_barekey`](https://metacpan.org/pod/JSON::PP#allow_barekey)
qui règle le cas des clés sans quotes, ainsi que
[l'option `allow_singlequote`](https://metacpan.org/pod/JSON::PP#allow_singlequote)
qui  traite le  cas des  valeurs  délimitées par  des simples  quotes.
Hélas, même avec ces deux  options, le module `JSON::PP` déclenche une
erreur  sur certaines  chaînes  de caractères  comportant des  doubles
quotes :

```
    ingredients_text_with_allergens: 'Cheddar cheese (<span class="allergen">milk</span>), potato starch.',
                                     .............................*........*..............................
```

J'ai soumis une
[demande de correction](https://github.com/makamaka/JSON-PP/issues/90).
L'auteur du module l'a rejetée, en expliquant que je pouvais utiliser
[l'option `loose`](https://metacpan.org/pod/JSON::PP#loose)
ou, de  manière préférable, un  module analysant réellement  du JSON5.
L'inconvénient qu'il donne pour `loose` est que cela pourrait accepter
des sources JSON incorrects au  lieu de déclencher un message d'erreur
de syntaxe. Pour  les raisons indiquées ci-dessus et parce  que le but
de mon  programme n'est pas de  vérifier la syntaxe JSON,  j'ai adopté
l'option `loose` plutôt que le module `JSON5`.

Et si je puis me permettre une remarque acerbe, je ferai remarquer que
le but du  langage JSON5 est de faciliter la  saisie de documents JSON
par des  humains. On pense  notamment à des fichiers  de configuration
qu'il  faut éditer  lorsque  l'on  installe tel  ou  tel logiciel.  En
revanche, si un document JSON est généré par un programme, alors c'est
la version stricte  de JSON (v4 ?) qui doit  être utilisée. Jusque-là,
je  suis d'accord.  Mais  dans ces  conditions, pourquoi  l'utilitaire
`mongosh` de MongoDB  génère-t-il du JSON5 au lieu de  la syntaxe plus
rigoureuse de JSON v4 ?

### YAML ou YAML::XS ? Quel module Perl ?

`YAML`  a  un   avantage  sur  `YAML::XS`,  il   est  compatible  avec
`YAML::Node`, module  qui permet de  trier les clés d'un  hachage dans
l'ordre que  l'on souhaite.  Cela me  permet d'afficher  les attributs
d'une  propriété en  commençant par  l'attribut `type`  et en  listant
ensuite les  autres attributs  dans l'ordre  alphabétique. On  y gagne
beaucoup en  lisibilité. C'est pour  cela que, dans un  premier temps,
j'ai choisi `YAML.pm`.

Suite  à la
[refonte des schémas le 2024-10-21](https://github.com/openfoodfacts/openfoodfacts-server/commit/8cb187340e912f21565c2b752c70e226a6b31ac0),
sont apparues  des
erreurs   de  syntaxe   dans  les   fichiers  YAML.   Cela  concernait
essentiellement  l'écriture  de  tableaux  en  _flow  style_  (que  je
traduirai par « style  au fil de l'eau », un style  qui rappelle JSON,
par opposition au _block style_ (« style en blocs »), qui est le style
basé sur l'indentation des divers éléments.

Exemple, tiré de `product_nutriscore.yaml`

```
      properties:
        id:
          type: string
          examples:
            [
              "energy",
              "sugars",
              "saturated_fat",
              "salt",
              "fiber",
              "fruits_vegetables_legumes",
            ]
        points:
          type: integer
          examples: [5, 6, 7, 2, 1, 0]
        points_max:
          type: integer
          examples: [10, 15, 20, 25, 5, 5]
```

Les tableaux associés  aux attributs `examples` utilisent  le style au
fil de l'eau, tandis que tout le  reste utilise le style en blocs. Les
deux styles sont parfaitement valides pour la syntaxe YAML.

Le problème avec le module `YAML.pm`,  c'est qu'il coince sur le style
au fil de l'eau quand il  s'étale sur plusieurs lignes. Dans l'exemple
ci-dessus, le  module déclenche  une erreur sur  les `examples`  de la
propriété `id`. À  l'inverse, pas de problème pour  les `examples` des
propriétés `points` et `points_max`. En revanche, le module `YAML::XS`
traite sans problème cet extrait.

J'ai réagi en mettant la charrue avant les bœufs.

J'ai commencé par réécrire les fichiers YAML en corrigeant les points
où le module `YAML.pm` déclenchait une erreur, par exemple :

```
        id:
          type: string
          examples:
            - "energy"
            - "sugars"
            - "saturated_fat"
            - "salt"
            - "fiber"
            - "fruits_vegetables_legumes"
```

J'ai créé une
[_pull request_](https://github.com/openfoodfacts/openfoodfacts-server/pull/11220)
pour reporter ces modifications sur le
[dépôt OFF](https://github.com/openfoodfacts/openfoodfacts-server).

J'ai relu la
[spécification de YAML](https://yaml.org/spec/1.2.2/)
et j'ai  constaté que le style  au fil de l'eau  était bien compatible
avec les passages à la ligne.

J'ai écrit un
[utilitaire beaucoup plus succint](https://github.com/jforget/perl-Open-Food-Facts-utils/tree/master/yaml-check)
dont le seul but  est de vérifier la syntaxe d'un  fichier YAML, en se
basant soit sur le module `YAML.pm`, soit sur `YAML::XS`.

Après avoir constaté que `YAML::XS` acceptait les changements de ligne
dans  un passage  en  style au  fil  de l'eau,  j'ai  annulé ma  _pull
request_ et j'ai adapté mon utilitaire `schema-check.pl` pour utiliser
le module `YAML::XS`.

Hélas, dans  les listings,  on ne trouvait  plus l'attribut  `type` en
première position  pour une  propriété. Donc  maintenant, l'utilitaire
`schema-check.pl` utilise  les deux  modules `YAML::XS`  et `YAML.pm`,
chacun pour un besoin particulier :

* `YAML::XS` pour lire les fichiers YAML et les charger en mémoire,

* `YAML` pour afficher le schéma chargé dans le fichier compte-rendu,
si cela a été demandé par l'option `--list-schema`.

### Autres modules ? ou autres programmes ?

En faisant une
[recherche Internet](https://www.qwant.com/?client=brz-moz&q=yaml+%24ref)
sur `YAML` et les clés `$ref`, je suis tombé sur un
[article de stackoverflow](https://stackoverflow.com/questions/53475979/how-to-use-ref-within-a-schema-in-openapi-3-0)
décrivant
[Open API](https://www.openapis.org/).
Un peu plus tard, j'ai trouvé également le projet
[JSON schema](https://json-schema.org/)
qui ressemble beaucoup à ce que je viens d'expliquer et de mettre
en œuvre. Ce site propose
[quelques utilitaires en ligne de commande](https://json-schema.org/implementations#validators-command-line)
et de nombreux modules, dont
[quelques-uns en Perl](https://json-schema.org/tools?query=&sortBy=name&sortOrder=ascending&groupBy=languages&licenses=&languages=&drafts=&toolingTypes=&environments=&showObsolete=false#perl)

Ultérieurement, en lisant le
[commit du 17 octobre](https://github.com/openfoodfacts/openfoodfacts-server/commit/d605b4712288f9107370dca7d7059c47da4f1717)
et le
[commit du 24 octobre](https://github.com/openfoodfacts/openfoodfacts-server/commit/b7aefbd03b95fa863b39550250ddbe2f0712febb),
j'ai vu quelques mentions de
[OpenAPI Generator](https://openapi-generator.tech/),
ce  qui confirme  mon impression  que les  fichiers YAML  étaient bien
traités par un utilitaire particulier.

Lors de ma première visite au site JSON schema, les programmes en ligne de commande étaient :

* [`valbuddy`](https://www.json-buddy.com/json-validator-command-line-tool.htm),

* [`ajv-cli`](https://www.npmjs.com/package/ajv-cli)

* [`yajsv`](https://github.com/neilpa/yajsv)

* [« Polyglottal JSON Schema Validator »](https://www.npmjs.com/package/pajv).

Et  lors d'une  visite  ultérieure, j'en  ai  trouvé quelques  autres.
Inutile de les lister, la liste  aura encore changé lorsque vous lirez
cette documentation.

Pour les modules Perl, le site propose :

* [`JSON::Schema::Modern`](https://metacpan.org/search?q=JSON%3A%3ASchema%3A%3AModern),

* [`JSON::Schema::Tiny`](https://metacpan.org/pod/JSON::Schema::Tiny),

* [`JSON::Validator`](https://metacpan.org/pod/JSON::Validator)

* [`JSONSchema::Validator`](https://metacpan.org/pod/JSONSchema::Validator).

Me suis-je fatigué pour rien ? Le programme Perl que j'ai écrit est-il
inutile ?  Je pense  le contraire,  parce que  ces utilitaires  et ces
modules ne  correspondent peut-être pas aux  fonctionnalités dont j'ai
besoin.  D'autre part,  cela  m'a  permis de  décrire  la syntaxe  des
schémas JSON de façon progressive, incrémentale et pédagogique, plutôt
que de lire le pavé indigeste que constitue la
[spécification](https://json-schema.org/specification)
des schémas JSON.

Par  exemple, `JSON::Schema::Tiny`  ne traite  pas les  entrées `$ref`
pointant vers des fichiers externes. Étant  donné que le nom du module
comporte la mention `Tiny`, ce n'est pas étonnant. Toujours est-il que
cela ne correspond pas à mes besoins. Abandonné.

Éventuellement,  j'installerai  les  autres  modules Perl  et  je  les
testerai, quand j'aurai  le temps. Pour l'instant, je  continue sur ma
lancée et  je me contente  des modules JSON  et YAML, sans  chercher à
utiliser des  solutions existantes  pour JSON Schema.  Et je  lirai la
spécification pour  voir si ce  que j'ai  déjà compris est  correct et
quels sont les points particuliers que j'aurai manqués.

Licence
=======

Texte diffusé sous la licence  CC-BY-SA : Creative Commons avec clause
de paternité, partage à l'identique.
