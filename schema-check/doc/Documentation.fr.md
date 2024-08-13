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
[`YAML::Node`](https://metacpan.org/dist/YAML/view/lib/YAML/Node.pod)
et [`JSON::PP`](https://metacpan.org/pod/JSON::PP).
J'ai eu l'intention  de prendre `YAML::Any`, mais comme l'explique la
[documentation](https://metacpan.org/dist/YAML/view/lib/YAML/Any.pod),
ce module est destiné à être remplacé par
`YAML` qui, à terme, fonctionnera comme un module `xxx::Any`.

Votre machine doit contenir une copie locale du dépôt
[`openfoodfacts-server`](https://github.com/openfoodfacts/openfoodfacts-server)
ou d'un clone ce de dépôt.

Dans le programme `schéma-check.pl`,  il faut changer l'initialisation
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
perl schema-check.pl --schema-listing exemple.txt
```

Dans ce cas, vous n'êtes pas obligés de fournir le nom d'un fichier de
données JSON.  Le programme se contentera  de charger le schéma  et de
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
perl schema-check.pl --schema=schemas/product.yaml exemple.txt
```

ou bien

```
perl schema-check.pl --schema-listing --schema=schemas/product.yaml exemple.txt
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

Où trouver des données de test ?
--------------------------------

Vous pouvez toujours  les taper directement en JSON sous  Vi, Emacs ou
tout autre éditeur de source à votre convenance.

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

Je ne  suis pas sûr du  mot-clé `NumberLong`, voyez vous-même  dans le
fichier lorsque vous l'aurez obtenu.  Cette syntaxe est refusée par le
module  d'analyse JSON  du programme  `schema-check.pl`, il  faut donc
convertir ces nombres en enlevant le type et les parenthèses.

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
`EJSON.stringify()` à toutes les requêtes, est peu ergonomique. À la place,
_a  priori_,  on  peut  s'en  sortir avec  les  bons  paramètres  pour
l'analyseur  JSON fourni  par `JSON::PP`.  Sauf que  certaines valeurs
contiennent des doubles quotes et `JSON::PP` n'aime pas. Par exemple :

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

Première étape
--------------

Le schéma est défini dans le fichier `product.yaml` du sous-répertoire
`docs/api/ref/schemas` du dépôt Git du serveur. En enlevant le libellé
documentaire, le fichier contient :

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
est utilisé  51 fois, 48  fois pour  importer un fichier  extérieur, 3
fois pour un autre mécanisme (décrit ultérieurement).

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
document, elle arrive avant dans le schéma.

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
`"with_allergens"`. Ça ferait désordre...

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

Pour la  base de  données `off`,  je considère que  l'on n'a  pas jugé
utile de signaler  dans le fichier `product.yaml`  que chaque document
de  la base  de  données comporte  une clé  `"_id"`.  Le programme  de
vérification du schéma ajoute automatiquement  cette clé au schéma, ce
qui fait que la présence de cette paire clé-valeur dans un document ne
provoquera pas d'erreur.

Le livre de  Kristina Chodorow ne mentionne pas  la clé `"_keywords"`.
Néanmoins, à  cause du  caractère souligné  initial, je  suppose qu'il
pourrait s'agir également d'une clé implicite, même si son ajout n'est pas
systématique. Cependant, comme ce n'est pas une certitude, je continue
à déclencher un message d'erreur sur cette clé.

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
subordonnées  `"(?<language_code>\w\w)"`.  Néanmoins,   on  trouve  la
valeur `"world"`  qui n'est pas un  code langue connu et  qui ne colle
pas à  l'expression rationnelle. D'où  un message d'erreur lors  de la
vérification.

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
  title:
    type: string
  grade:
    type: string
    description: Indicates that the panel corresponds to a A to E grade such as the Nutri-Score of the Eco-Score.
    enum:
      - a
      - b
      - c
      - d
      - e
      - unknown
  icon_url:
    type: string
  icon_color_from_evaluation:
    type: string
  icon_size:
    type: string
    description: |
      If set to "small", the icon should be displayed at a small size.
  <strong>type:</strong>
    type: string
    example: grade
    description: 'Used to indicate a special type for the title, such as "grade" for Nutri-Score and Eco-Score.'
</pre>


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

D'autres tableaux sont décrits ainsi :

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

J'ai écrit que les fichiers YAML contenaient 51 attributs `$ref`, dont
48 correspondaient à des appels de fichier similaires à `#include`. Et
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

Contrôle de valeur
------------------

Comme on l'a vu,  le contrôle de valeur des clés  est intrinsèque à la
description  du  schéma,  soit  par l'entrée  `properties`,  soit  par
l'entrée `patternProperties`. On  a déjà vu le cas  des codes langues,
il  y a  aussi les  tailles d'images,  ainsi que  le montre  l'extrait
suivant

```
    properties:
      1:
        type: object
        description: "This represents an image uploaded for this product.\n"
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
sous-propriétés de la propriété `nutrient_levels`

```
  nutrient_levels:
    type: object
    description: "Traffic light indicators on main nutrients levels\n"
    properties:
      fat:
        type: string
        enum:
          - low
          - moderate
          - high
      salt:
        type: string
        enum:
          - low
          - moderate
          - high
      saturated-fat:
        type: string
        enum:
          - low
          - moderate
          - high
      sugars:
        type: string.
        enum:
          - low
          - moderate
          - high
```

Mais le  programme de  vérification n'en tient  pas compte.  On trouve
également des valeurs à titre d'exemple (attribut `example`) qui elles
non plus ne sont pas utilisées dans le programme de vérification.

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
                  description: |
                    The type of the included element object.
                    The type also indicates which field contains the included element object.
                    e.g. if the type is "text", the included element object will be in the "text_element" field.

                    Note that in the future, new type of element may be added,
                    so your code should ignore unrecognized types, and unknown properties.

                    TODO: add Map type
                  element_type: string
                  enum:
                    - text
                    - image
                    - action
                    - panel
                    - panel_group
                    - table
```

Et une dernière curiosité, dans le fichier `product_extended.yaml`, le
champ  métier   `category_properties`,  de  type  `object`,   n'a  pas
d'attribut  `properties`, ni  `patternProperties`, mais  seulement une
entrée `additionalProperties`.

```
  category_properties:
    type: object
    additionalProperties:
      description: those are properties taken from the category taxonomy
      type: string
```

Remarquons  que cette  clé  `additionalProperties` se  trouve au  même
niveau que  l'attribut `type`, donc  est elle-même un  attribut, alors
que  dans  l'exemple  `owner_fields` quelques  paragraphes  ci-dessus,
`additionalProperties` apparaissait en  tant que propriété. Remarquons
aussi qu'au niveau suivant, nous  avons de nouveau des clés techniques
`description` et  `type`. Le  programme de  vérification ne  tient pas
compte  de cet  attribut  `additionalProperties` et  considère que  la
propriété `category_properties` est un  objet dont les sous-propriétés
sont inconnues. En fait, dans  les quelques exemples que j'ai extraits
de la  collection `products`,  la propriété  `category_properties` est
toujours un objet vide `{}`.

Déroulement
===========

Extraction du schéma
--------------------

Le fichier `product.yaml` est chargé et converti pour donner le schéma
de  données.  On y  ajoute  la  propriété auto-générée  `"_id"`,  pour
désactiver les messages d'erreur sur cette propriété.

Ensuite,  le programme  traite  en boucle  les  entrées de  l'attribut
`allOf`. Chacune  de ces entrées a  pour clé `$ref` et  pour valeur un
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

Voici un extrait du fichier `product.yaml` :

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

### Références récursives

Dans  le cas  des trois  `$ref` spéciaux,  pour `nova_groups_markers`,
`nutrient.yaml` et `ingredient.yaml`, le  programme ajoute un attribut
`dyn_sch` (schéma dynamique) et  insère une entrée correspondante dans
la variable  `%dyn_schema`, avec le répertoire  en cours et le  nom du
fichier en cours.

Ensuite, une fois  que le schéma principal est  entièrement chargé, le
programme  déroule  la  variable  `%dyn_schema`  pour  charger  chaque
sous-schéma dynamique. Le fonctionnement est  presque le même que pour
le schéma principal, avec deux différences.

La première différence  est que pour ajouter  l'attribut `dyn_sch` sur
la propriété  récursive, on reprend  la valeur déjà attribuée  dans le
schéma principal, au lieu d'en générer  une nouvelle. C'est la mise en
œuvre de la récursivité et de l'auto-référence.

La  deuxième  différence   se  voit  dans  le  cas   de  la  propriété
`nova_groups_markers`. Le sous-schéma dynamique ne correspond pas à la
totalité du  fichier `product_extended.yaml`,  mais à une  partie très
réduite de l'arborescence,  en fonction de la  sélection `properties /
nova_groups_markers  /  properties /  3  /  items`. Avant  de  charger
l'attribut `schema`  du sous-schéma  dynamique, le  programme effectue
cette sélection.

### Problèmes

La récursivité simple, qui concerne seulement le fichier en cours, est
bien traitée.  En revanche,  la récursivité croisée  ne l'est  pas. La
récursivité croisée est,  par exemple, le cas de figure  où un fichier
`poule.yaml`  fait  référence  au   fichier  `oeuf.yaml`,  tandis  que
`oeuf.yaml` faire référence à `poule.yaml`. Dans ce cas, le chargement
du schéma part dans une boucle infinie.

En fait, même la récursivité simple peut conduire à une boucle infinie.
Prenons le fichier `ingredient.yaml`. L'appel récursif est
défini par :

```
          $ref: '#/'
```

S'il avait été défini en revanche par :

```
          $ref: './ingredient.yaml'
```

là aussi il y aurait eu une boucle récursive infinie.

La solution  serait peut-être  d'utiliser la méthode  des sous-schémas
dynamiques pour  toutes les clés  `$ref`, sauf éventuellement  pour le
niveau 1.

Un  autre cas  d'erreur se  rencontre si  le même  fichier `toto.yaml`
contient deux références différentes. Voici  un exemple inspiré du cas
réel (qui fonctionne bien, alors que l'exemple ci-dessous foire) :

```
type: object
properties:
  nova_groups_markers:
    type: object
    properties:
      "2":
        description: |
          Markers of level 2
        type: array
        items:
          type: array
          description: |
            This array has two integer elements for each marker.
          items:
            type: integer
      "3":
        description: |
          Markers of level 3
        type: array
        items:
          type: array
          description: |
            This array has two string elements for each marker.
          items:
            type: string
      "4":
        description: |
          Markers of level 4
        type: array
        items:
          $ref: "#/properties/nova_groups_markers/properties/3/items"
      "5":
        description: |
          Markers of level 5
        type: array
        items:
          $ref: "#/properties/nova_groups_markers/properties/2/items"
```

Si, comme suggéré juste au-dessus,  on adopte le mécanisme d'insertion
dynamique pour  toutes les clés `$ref`  sauf au niveau 1,  ce deuxième
cas d'erreur est  présent dans de nombreux fichiers  YAML. Il faudrait
abandonner l'idée des  clés simples `dyna`, `dynb`  et suivantes, pour
adopter à la place des clés basées sur le nom du fichier à inclure.

Extraction des documents JSON
-----------------------------

Outre les  fichiers YAML du  schéma, le  programme reçoit des  noms de
fichiers. On  considère que ces  fichiers contiennent du  texte varié,
avec par moment  des documents JSON. On cherche des  documents JSON de
deux variétés.  Tout d'abord, des  documents mono-lignes. Et  ce n'est
pas  grave si  l'on obtient  une ligne  de plus  de 30 000 caractères.
Ensuite,  des  documents  bien  mis en  forme,  avec  une  indentation
cohérente. Ces documents sont sur  plusieurs lignes, la première étant
constituée d'une accolade ouvrante en  début de ligne et rien d'autre,
la dernière étant constituée d'une accolade fermante en début de ligne
et rien d'autre. Et enfin des objets JSON réunis dans un tableau JSON,
délimités  par  deux  lignes  contenant chacune  un  crochet  et  rien
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
l'automate analyse le JSON contenu dans la chaîne (un tableau, puisque
cela commence par  un crochet et que cela se  termine par un crochet),
découpe ce tableau  en documents élémentaires, appelle  la fonction de
vérification  pour chaque  document  élémentaire,  puis transite  vers
l'état `A`.

Il n'y a pas de transition possible entre l'état `B` et l'état `C`.

L'état final  autorisé devrait être  l'état `A`, mais le  programme ne
contrôle pas que le fichier se  termine bien. Il se contente de fermer
le fichier et de passer au suivant s'il en reste.

Vérification du document
------------------------

Au premier niveau,  chaque document est une table de  hachage, ou plus
précisément la référence  à une table de hachage.  Le programme charge
ce  document, du  texte  JSON  et le  convertit.  Puis  il appelle  la
fonction de vérification d'une table de hachage.

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

Si les éléments du tableau sont  des chaînes ou des numériques, pas de
contrôle supplémentaire.  Si ce sont  des objets, la  fonction appelle
récursivement  la fonction  de contrôle  des  objets. Si  ce sont  des
tableaux, la fonction de vérification d'un tableau s'appelle elle-même
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


Licence
=======

Texte diffusé sous la licence  CC-BY-SA : Creative Commons avec clause
de paternité, partage à l'identique.
