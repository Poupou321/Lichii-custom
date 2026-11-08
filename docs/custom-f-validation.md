# Custom F — intégration et validation Build 117

## Références figées

- Base officielle complète : `build-117`, commit `89440b29a90708c0fefc126b2bd8c7a64a996bdd`.
- Provenance vérifiée : tag léger du dépôt `zortos293/Lichii` et SHA identique dans la
  [release build-117](https://github.com/zortos293/Lichii/releases/tag/build-117).
- E étudiée : `dc01ef09825c00d0b0a1631f7c257f7a154461ba`, issue de D/C et de la build 95.
- Branche F : `custom/amd-build117`. Aucun remplacement ou merge dans C, D, E ou nx2.

F part de l'intégralité de 117. Le diff E n'est pas appliqué globalement : il contient
également des anciennes versions de code amélioré depuis la build 95. Les ports sont
comparés par comportement et conservent les mécanismes officiels plus récents.
Une compilation réussie ne garantit ni absence de régression matérielle ni gain FPS.

## Corrections officielles demandées

Le commit de fusion de chacune des six PR est un ancêtre de la référence exacte, vérifié
avec `git merge-base --is-ancestor`. L'inspection du code complète cette preuve historique.

| PR | Commit officiel présent dans 117 | Mécanisme conservé |
|---|---|---|
| #149 | `79f284eab8674d5ce90165c58353fed9550efee6` | Soumission des travaux différés avant attente de fence ; correction RED/SURED dans le lowering Ampere |
| #214 | `186d4dd1b8cd567ca5da9e653ab2ab9049aeb5f8` | Outils de reconstruction depuis des hints, parsing d'archives et replay task/mesh ; ce n'est pas à lui seul le warm-up intégré de E |
| #215 | `7ae3e740147e246efb582ea173bfe54d7ec130bd` | Flush des résultats de queries avant DMA macro, attente et soumission différée Vulkan |
| #273 | `28d99d3dad14d46a3ac42bc13cb7282fcb0e5dab` | Images depth-compare float, retries atomiques, fallback shuffle fragment AMD et deux shaders compute AMD sans optimisation |
| #295 | `18cfe8556341a0b969a7ae28b71fb541632a90ca` | Accès SSBO 64/128 bits désalignés et barrières compute/graphics |
| #301 | `c87f09a84c7d22b90bf72c8408d23524e62b4f9a` | Trace BEGIN/END des builds de pipelines avec hashes et durées ; diagnostic désactivé par défaut |

Le code officiel supplémentaire est aussi conservé : matrices coopératives #582/#583,
garde AMD matérielle #657, repli task/mesh #569, paramètres OOT #616, Dynamic FPS et autres
changements de 117. Les performances rapportées par leurs auteurs ne sont pas des mesures
sur le PC cible et ne sont pas reprises comme résultats de F.

## Correspondance E / 117 / F

| Apport E | Situation dans 117 | Décision F |
|---|---|---|
| #351, sondes d'éclairage et portée des tables | Présent (`b72195422…`), avec améliorations SSBO64 ultérieures | Conserver l'officiel, sans réappliquer l'ancienne portée de D |
| #432, NaN min/max/clamp/atomiques | Présent (`2e69168aa…`) | Conserver l'officiel une seule fois |
| #465, Wait/Bounded/Skip | Présent (`f992933e5…`) | Conserver les réglages et la politique officiels |
| #408, mémoire, durée de vie, caches, scheduler | Présence partielle et implémentations officielles plus récentes | Porter seulement les différences pertinentes, détaillées dans les notes de code |
| Clés VertexA/VertexB conservatrices AMD de E | Adaptation spécifique à E | Conserver des clés complètes ; ne pas restaurer le masquage AMD problématique |
| #463, suivi des écritures périmées | Non fusionnée dans le tag | Port ciblé en conservant la gestion officielle des images/framebuffers |
| #448, mipmaps ASTC/BC irrégulières AMD | PR fermée non fusionnée ; comportement de code comparé | Port ciblé du fallback RGBA8 de E, avec coût VRAM possible |
| #579, bibliothèques et préparation intégrée | Absent du tag | Adapter E aux APIs et chemins Vulkan/compute/mesh de 117 ; désactivé par défaut |
| #437, anciennes migrations shader et driver | E excluait déjà la migration incompatible ; fallback driver couvert par #408 | Aucune fusion de branche #437 et aucune migration shader incompatible |
| Corrections Windows des tests E | Plusieurs déjà officielles | Conserver les assertions et appliquer uniquement les ajustements encore nécessaires |

Les révisions E épinglées et les commits officiels se trouvent dans `COMMITS.json`.
Les notes de conflits, variantes supersédées et preuves de comportement sont précisées dans
`docs/custom-f-code-integration.md`. Une PR fusionnée après le tag ne compte pas comme présente.

## Caches et préparation

F utilise le namespace Vulkan **11701**, distinct de l'officiel 54, de D 55 et de E 56.
Les clés et bindings modifiés interdisent de renommer ou charger leurs anciens caches comme
un cache runtime F. L'historique éventuellement lu pour préparer des états est distinct du
chargement de pipelines. Chaque version dispose de son dossier portable neuf.

Les bibliothèques Vulkan et la préparation ne sont pas activées automatiquement. Elles
requièrent les capacités adéquates du pilote ; le chemin officiel reste le repli.
La préparation intégrée utilise exclusivement les fichiers du jeu déjà présents sur le PC,
sans Python et sans installation d'outil de développement. Aucune ROM, clé, firmware ou
cache propriétaire n'est distribué. Les chemins task/mesh et compute non couverts peuvent
encore compiler en jeu. Le rendu de E ne valide pas celui de F.

## Chaîne de compilation et publication

Le seul workflow de F est `release-binaries.yml`, déclenché manuellement, Windows x64,
permissions `contents: read`, checkout sans persistance d'identifiants, sans secret fourni
aux sources, sans création de tag/release et sans message vers un tiers. Les anciennes
automatisations Linux/macOS et de labellisation ne sont pas actives sur F.

La chaîne suit le Windows PGO officiel de 117 : clang-cl 22.1.8, lld-link, ThinLTO,
profil `lichii-windows.profdata` officiel, Qt 6.8.3 et SDK Vulkan 1.4.341.1.
Les avertissements de profil périmé/non entraîné restent des avertissements, comme dans
l'officiel ; ils ne désactivent ni tests ni vérifications de compilation ordinaires.
Le profil et les outils sont identifiés par leurs empreintes dans les diagnostics.

Le même job construit et teste d'abord le source officiel exact dans `source/`, puis F
au même emplacement, avec les mêmes options. Le cache de compilation contient des objets
indexés par contenu et ne remplace aucun contrôle. L'updater officiel et son helper Windows
sont conservés ; Discord et les programmes room restent configurés comme dans le Windows
officiel. Le build de référence n'est pas distribué comme F.

Le ZIP final `Lichii-Custom-F-Build117-AMD-Win64.zip` est publié uniquement après :

1. Compilation complète et tous les CTest de la référence officielle.
2. Validation des imports DLL, des PE x64, de Qt et démarrage de référence pendant 15 secondes.
3. Compilation complète et tous les CTest de F, y compris ses tests supplémentaires.
4. Les mêmes contrôles de package pour F, présence de lichii.exe, eden-cli.exe et lichii-updater.exe.
5. Nettoyage des données créées par le smoke test, création d'un dossier portable neuf et SHA-256.

Les journaux de chaque étape et les échecs sont conservés comme diagnostics. Un échec
interdit la publication du ZIP final. Aucun test Lichii n'est supprimé pour obtenir un succès.

## Matrice de non-régression

| Domaine | Référence 117 | E | F / validation matérielle restante |
|---|---|---|---|
| Build/tests Windows | Réexécutés par le workflow F sur le SHA officiel exact | Run 42410316620 réussi : 5/5 CTest, 862 cas principaux | Résultat réel à lire dans Actions et validation/F/ |
| Démarrage et DLL/Qt | Contrôlés avant le build F | Smoke test 15 s réussi | Contrôlés avant publication ; aucun jeu lancé |
| Traduction, atomiques, alignement, cache | Tests officiels conservés | Tests E réussis | Tests officiels + ports/adaptations F ; pas une preuve exhaustive GPU |
| Synchronisation et mémoire | Code 117 conservé | Anciennes adaptations E comparées | Tests unitaires et revue ; longues sessions et traces GPU à faire sur RX 7800 XT |
| ASTC, ombres, brouillard, transparence | Pas de benchmark matériel ici | Ombres de D déclarées corrigées par l'utilisateur ; E non validée sur son GPU | Comparaison visuelle dans la même scène requise |
| Sauvegardes | Pas d'accès aux originaux | Dossiers distincts | Dossier user neuf ; test de chargement/sauvegarde sur copie jetable à faire |
| Fluidité 1440p et compatibilité autres jeux | Pas de mesure dans ce travail | Journal D analysé, pas de mesure E cible | À mesurer à réglages et parcours identiques, caches froids puis chauds |

Les résultats définitifs de compilation et les liens d'artifact seront ajoutés après leur
obtention. Les logs `validation/official117/` et `validation/F/` du ZIP réussi font foi
pour les vérifications de son exécution exacte.
