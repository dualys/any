# Proposition de contrat de publication v2

Statut : **proposition partiellement implémentée et non validée conjointement**.
Le téléversement des blobs candidats et l'installation Rust depuis un dépôt
local sont implémentés ; le registre ne publie pas encore de release v2. Le
format source v1 d'anynix ne signe pas les métadonnées d'installation : il ne
doit pas être accepté comme release v2. Les clients et le registre doivent
rejeter les versions qu'ils ne comprennent pas.

## Conventions cryptographiques

- Tous les objets signés sont sérialisés en JSON canonique RFC 8785 (JCS),
  encodé en UTF-8. Les clés JSON dupliquées et les champs inconnus sont
  rejetés avant canonisation. Les tableaux conservent leur ordre.
- Un hash est le BLAKE3 sur les octets indiqués, encodé en hexadécimal
  minuscule sur 64 caractères. Une clé publique Ed25519 brute est encodée en
  hexadécimal minuscule sur 64 caractères ; une signature, sur 128 caractères.
  L'empreinte d'une clé est le BLAKE3 de ses 32 octets bruts.
- Les tailles et permissions sont des entiers JSON, sans signe négatif et au
  plus égaux à 2^53-1. Les chaînes sont sensibles à la casse ; aucune
  normalisation Unicode implicite n'est appliquée.
- Les signatures sont des signatures Ed25519 sur les **32 octets** du hash
  BLAKE3 du JSON canonique de l'objet à signer, et non sur sa représentation
  hexadécimale. La vérification Ed25519 doit être stricte.

## Objets signés

Le document de release a exactement les champs suivants :

```json
{
  "format": "anynix-release-v2",
  "package": "example",
  "version": "1.0.0",
  "license": "MIT",
  "source": {
    "payload": {"digest": "<blake3>", "size": 123},
    "build_script": {"digest": "<blake3>", "size": 456}
  },
  "sources": [{"url": "https://example.org/source.tar.gz", "digest": "<blake3>", "size": 789}],
  "targets": [
    {
      "os": "linux",
      "architecture": "x86_64",
      "status": "success",
      "dependencies": [{"package": "libexample", "version": "1.2.3"}],
      "files": [
        {"digest": "<blake3>", "size": 42, "install_path": "bin/example", "permissions": 493, "type": "binary"}
      ]
    }
  ]
}
```

Les valeurs entre chevrons sont des substituts, pas des hashes valides.
`license` est une chaîne non vide ou `null`. `sources` peut être vide ; ses URL
sont indicatives et ne remplacent jamais la vérification des octets. Les
versions des dépendances sont exactes. Les paires `os`/`architecture`, les
noms de dépendance par cible et les chemins d'installation par cible sont
uniques. Chaque cible réussie possède au moins un fichier. Les types de fichier
admis sont `binary`, `configuration`, `documentation`, `manual` et `source`.
Les permissions sont des bits Unix de `0` à `511`, sans bits spéciaux.
Les noms de paquet sont composés de 1 à 128 caractères ASCII parmi
`a-z`, `0-9`, `.`, `_`, `+` et `-`, et commencent par une lettre ou un
chiffre. Les versions sont composées de 1 à 128 caractères ASCII parmi
`A-Z`, `a-z`, `0-9`, `.`, `_`, `+`, `~` et `-`, commencent par une lettre ou
un chiffre et ne valent pas `latest`. Ces règles s'appliquent aussi aux
dépendances. Les identifiants `os` et `architecture` sont des chaînes ASCII
non vides en minuscules composées de lettres, chiffres, `_` ou `-`.

Une cible dont le build a échoué a exactement les champs `os`, `architecture`,
`status: "failed"` et `error`, une chaîne non vide. Elle ne contient ni
dépendances ni fichiers. Toute cible obligatoire doit être présente et
réussie. Les autres échecs restent visibles dans le document signé.

Les chemins d'installation sont relatifs, non vides et séparés par `/`. Les
composants vides, `.` et `..`, les barres obliques inverses et les caractères
NUL sont interdits. Les fichiers sont des fichiers réguliers ; les liens
symboliques et autres fichiers spéciaux sont interdits. Le client doit aussi
empêcher la traversée de liens existants lors de l'installation.

L'objet source, signé avant le build, est exactement :

```json
{
  "format": "anynix-source-v2",
  "package": "example",
  "version": "1.0.0",
  "source": {
    "payload": {"digest": "<blake3>", "size": 123},
    "build_script": {"digest": "<blake3>", "size": 456}
  }
}
```

Ses champs `package`, `version` et `source` doivent être identiques à ceux du
document de release. Son hash et celui du document de release sont calculés
sur leurs JSON canoniques respectifs.

## Chaîne d'attestations

Une publication comprend exactement cinq attestations, dans cet ordre :
`Developer`, `Reviewer`, `Manager`, `BuildServer`, `ReleaseAuthority`.
Chaque entrée possède exactement `role`, `decision`, `subject`,
`previous`, `public_key` et `signature`. Pour une publication, `decision`
vaut toujours `Approve` ; un rejet n'est pas publiable.

Pour les trois premiers rôles, `subject` est le hash de l'objet source ; pour
les deux derniers, c'est le hash du document de release complet. `previous`
vaut `null` pour la première entrée et, pour les suivantes, le hash du JSON
canonique de l'attestation précédente **complète**, signature comprise.

La signature de chaque entrée porte sur l'objet ci-dessous, où les valeurs
sont celles de l'entrée correspondante :

```json
{
  "domain": "anynix-release-attestation-v2",
  "role": "Developer",
  "decision": "Approve",
  "subject": "<blake3>",
  "previous": null,
  "public_key": "<ed25519-public-key>"
}
```

La chaîne lie ainsi l'approbation des sources aux résultats de build et à la
release finale. Les trois premiers rôles n'approuvent **pas** les métadonnées
d'installation futures ; seuls `BuildServer` et `ReleaseAuthority` signent le
document complet. Il faut donc que ces deux rôles vérifient explicitement les
métadonnées et les fichiers avant de signer. Le protocole v2 n'est pas
compatible avec les messages signés de la chaîne source v1.

## Confiance et politique

La possession d'une clé embarquée ou renvoyée par `/v1/keys` ne prouve pas son
autorisation. La confiance initiale repose sur une racine TUF installée et
vérifiée par un canal indépendant. Les métadonnées TUF sont vérifiées selon
[la spécification TUF 1.x](https://theupdateframework.github.io/specification/latest/),
avec une implémentation conforme ; les règles de canonisation propres à TUF ne
doivent pas être remplacées par JCS. Les clés des rôles TUF sont distinctes des
clés des cinq rôles d'attestation.

La racine initiale contient trois clés racine distinctes, avec un seuil de deux
signatures sur trois. Les mises à jour de la racine suivent les règles TUF,
notamment les seuils de l'ancienne et de la nouvelle racine. La création, la
garde et la récupération de ces clés sont des opérations administratives hors
du protocole ; les valeurs des seuils des autres rôles TUF sont définies dans
la racine authentifiée.

La politique de clés des attestations est le fichier cible TUF
`anynix/attestation-keys.json`, dont la structure est :

```json
{
  "format": "anynix-attestation-keys-v1",
  "roles": {
    "Developer": ["<ed25519-public-key>"],
    "Reviewer": ["<ed25519-public-key>"],
    "Manager": ["<ed25519-public-key>"],
    "BuildServer": ["<ed25519-public-key>"],
    "ReleaseAuthority": ["<ed25519-public-key>"]
  }
}
```

Les clés listées sont autorisées **globalement** pour leur rôle, et donc pour
tous les paquets. Les cinq rôles sont obligatoires, chaque liste est non vide,
et une même clé ne peut apparaître qu'une fois dans l'ensemble de la politique.
Les clés utilisent l'encodage brut hexadécimal défini plus haut. Une clé absente
de la liste de son rôle est refusée ; une réponse `/v1/keys` ne peut pas
modifier la confiance. Les cinq attestations restent obligatoires, même si
plusieurs clés sont autorisées pour chaque rôle.
Une clé Developer autorisée peut donc signer n'importe quel nom de paquet ;
une isolation par propriétaire nécessiterait une politique supplémentaire.

La rotation et la révocation sont distribuées par une nouvelle politique
authentifiée par TUF. Une révocation appliquée au client rend aussi invérifiables
les anciennes releases utilisant cette clé, faute d'un mécanisme de preuve de
signature antérieure. À l'inverse, un client hors ligne ne peut pas connaître
une révocation publiée après sa dernière mise à jour. Il doit refuser les
métadonnées expirées et utiliser une horloge fiable ; il n'y a pas de
contournement silencieux de l'expiration.

TUF doit aussi authentifier l'index des versions et les documents de release :
authentifier seulement la liste de clés ne protège pas le choix d'une ancienne
version par un serveur malveillant. Le client conserve son état TUF vérifié
pour détecter les retours arrière. TUF ne peut pas garantir la fraîcheur sur
une machine sans état de confiance préalable ni horloge fiable.

Les cibles TUF comprennent, pour chaque paquet publié :

- `anynix/packages/<package>.json` : un objet contenant exactement `format`
  (`anynix-package-index-v1`), `package`, `latest` et `versions`. `versions`
  est un tableau non vide de versions distinctes ; `latest` est une de ces
  versions, choisie par le registre. Aucun ordre sémantique n'est supposé.
- `anynix/releases/<package>/<version>.json` : un objet contenant exactement
  `source`, `release` et `attestations`, correspondant aux deux objets signés
  et à leur chaîne complète définis ci-dessus.

Pour une version exacte, le client vérifie sa présence dans l'index authentifié
avant de vérifier la cible release correspondante. Pour `latest`, il utilise
la valeur de l'index authentifié, et non une réponse non signée de l'API.
Les noms et versions doivent correspondre à ceux des objets signés. Les octets
des fichiers cibles sont vérifiés par TUF avant d'être analysés ; les signatures
et hashes BLAKE3 propres à anynix sont ensuite vérifiés séparément. La
distribution et les URL précises des métadonnées et cibles TUF restent à
spécifier.

La politique serveur contient une liste explicite de couples
`os`/`architecture` obligatoires. Elle est vide par défaut : une liste vide
interdit toute publication. Un couple ne peut être ajouté qu'après validation
de son build et de son installation. Le serveur contrôle les statuts signés,
mais une signature seule ne prouve pas qu'un build ou un test a réellement eu
lieu : cette garantie dépend de l'exploitation des signataires.

## Revue privée et corrections

Le service de revue est distinct du registre public. Il authentifie les
développeurs au moyen de jetons individuels et contrôle les autorisations de
lecture et d'écriture. Une correction est une nouvelle soumission liée
explicitement à la soumission refusée ; le paquet et le refus précédents sont
conservés. Une correction doit être revue à nouveau, et ne prolonge pas la
chaîne d'attestations d'une soumission rejetée.

Les refus, leurs motifs, les liens entre corrections et l'historique restent
strictement internes au service de revue et ne sont pas inclus dans le document
de release ni dans les réponses publiques du registre. Le format signé d'un
refus privé, les droits des reviewers et managers, les transitions autorisées et
les schémas HTTP de ce service restent à définir. Les identifiants et jetons
internes ne doivent pas apparaître dans les objets signés publics.

## Installation locale

Une release installable est distincte de l'archive source produite par `pack`.
Un dépôt local contient les métadonnées TUF, les cibles TUF décrites ci-dessus
et les blobs référencés par les releases. La racine TUF initiale est fournie
séparément et vérifiée par un canal indépendant : la racine incluse dans un
dépôt ou un paquet n'est pas automatiquement approuvée.

Le dépôt local utilise les répertoires `metadata/`, `targets/` et `blobs/`,
ces derniers contenant des fichiers nommés par leur hash BLAKE3. Ce format
de répertoire ne définit pas encore une archive hors ligne autonome.

Le client sélectionne la cible correspondant à son OS et son architecture,
résout récursivement les versions exactes des dépendances dans le dépôt local,
puis vérifie l'ensemble des métadonnées, attestations et blobs nécessaires avant
de modifier le préfixe. Des dépendances manquantes, contradictoires ou
cycliques entraînent un refus. Le fonctionnement hors ligne n'effectue aucune
requête réseau, y compris pour TUF.

Les chemins d'installation des fichiers sont relatifs au préfixe partagé
`/apps` par défaut, par exemple `bin/example` devient `/apps/bin/example`.
Aucun fichier ou lien existant ne doit être écrasé, et les chemins ne doivent
pas traverser de lien symbolique. Les tests utilisent uniquement des préfixes
temporaires. Ce contrat ne définit pas encore les commandes `remove` et
`uninstall` ni leur registre de fichiers installés.

L'implémentation actuelle refuse les fichiers déjà présents, les métadonnées
TUF déléguées et les répertoires d'installation appartenant à un autre
utilisateur ou modifiables par d'autres. Elle limite chaque fichier à 256 Mio,
l'ensemble des fichiers à 512 Mio, le nombre de fichiers à 1 024 et le nombre
de paquets à 256. Une interruption brutale peut laisser une copie partielle.

## Publication proposée

Les requêtes d'écriture utilisent HTTPS et
`Authorization: Bearer <jeton-manager>`. Le jeton est administré côté serveur,
ne doit pas être journalisé et ne remplace aucune signature. En l'absence de
jeton configuré, les écritures sont désactivées. Les réponses d'erreur suivent
le contrat `{"error": "..."}`.

1. `POST /v1/blobs` téléverse un fichier candidat avec son hash et sa taille
   annoncés. Le serveur calcule le BLAKE3 et la taille des octets reçus et
   refuse toute divergence. Un blob candidat n'est pas public. L'API existante
   attend un formulaire multipart `file`, `digest`, `size`, limité à 256 Mio ;
   elle renvoie `{"data":{"digest":"...","size":123}}` avec le statut 201.
   Un digest déjà présent renvoie 409 et une divergence renvoie 422.
2. `POST /v1/releases` soumet le document, l'objet source et la chaîne
   d'attestations. Le serveur vérifie le schéma, les clés autorisées, les
   signatures, les liens entre objets, la politique des cibles et les hashes
   et tailles de tous les blobs référencés avant publication.
3. `GET /v1/publications/{id}` permet au manager de consulter le résultat ;
   les détails exacts des requêtes, réponses et états restent à définir avant
   implémentation.

La consultation publique d'une release v2 devra fournir les objets source et
release complets ainsi que les cinq attestations, sans reconstruire ni omettre
de champs signés. La forme exacte de cette réponse reste à définir.

La vérification et la transition vers l'état public doivent empêcher les
courses concurrentes : une paire paquet/version publiée ne peut jamais être
remplacée, et seuls les blobs vérifiés référencés par une release publiée sont
accessibles publiquement. Une erreur laisse la release non publiée. Les
blobs doivent rester immuables après vérification ; les URL de stockage ne
doivent pas contourner ces règles d'accès.

Avant déploiement, ce contrat doit être adopté côté Rails et Rust, accompagné
de vecteurs de test communs couvrant la canonisation, les signatures et les
rejets, puis complété par le profil TUF, la politique de clés et les schémas
HTTP exacts.
