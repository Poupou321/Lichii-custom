**Lichii Custom AMD — rapport final du 7 novembre 2026**

Les deux archives Windows x64 portables sont compilées en Release et validées dans le cloud.
Aucune installation sur le PC de l’utilisateur, aucun accès aux sauvegardes existantes,
aucun téléchargement de jeu, firmware ou clés, aucune modification des pilotes du PC et
aucune publication de release. Les artifacts sont conservés 14 jours, jusqu’au 21 novembre 2026.

La référence exacte est `222877d4f7c8945b2f31a87b76d09f0a92e4f1b8` :
[exécution officielle nº 95](https://github.com/zortos293/Lichii/actions/runs/42359130346).
La [release porte par erreur le tag build-94](https://github.com/zortos293/Lichii/releases/tag/build-94),
comme le précise sa description. Le snapshot nx2 audité est
`efa74e4beac72ae9f5834c1d3e8f6d8b8fb4c290`.

| Variante | Source exacte | Contenu | Compilation et tests | Téléchargement |
|---|---|---|---|---|
| A, témoin expérimental | [931a23fa894f2f305ecc51a8760720e7c3340f1a](https://github.com/Poupou321/Lichii-custom/commit/931a23fa894f2f305ecc51a8760720e7c3340f1a) | Build 95 + #408, adaptée aux corrections déjà présentes dans 95 | Release réussie ; 5/5 cibles CTest ; 852/852 cas de la suite principale | [Artifact A](https://github.com/Poupou321/Lichii-custom/actions/runs/42386255687/artifacts/13579529391) |
| B, candidat AMD | [eb15e8106707c529ce1a19764347fd5e303066a0](https://github.com/Poupou321/Lichii-custom/commit/eb15e8106707c529ce1a19764347fd5e303066a0) | A avec clés VertexA/VertexB conservatrices, #465, #463, #432 et documentation de #437 | Release réussie ; 5/5 cibles CTest ; 858/858 cas de la suite principale | [Artifact B](https://github.com/Poupou321/Lichii-custom/actions/runs/42386258249/artifacts/13580520348) |

Les [journaux A](https://github.com/Poupou321/Lichii-custom/actions/runs/42386255687)
et [journaux B](https://github.com/Poupou321/Lichii-custom/actions/runs/42386258249)
donnent les résultats complets et les diagnostics téléchargeables.

**Révisions intégrées et exclusions**

Les quatre PR demandées sont toujours ouvertes et non fusionnées à la revérification finale.
Les builds utilisent les révisions figées ci-dessous, identiques à celles de l’audit.

| PR / révision amont | A | B |
|---|---|---|
| #408 — `308c0ee995d00e28db02757b6b627d55a947f391` | Intégrée avec résolution des conflits | Intégrée avec adaptation conservatrice des clés de sommets |
| #465 — `5787498b2a5b48da1d8c1bf043b5bbe23b841715` | Exclue pour conserver le témoin | Intégrée ; mode Wait par défaut |
| #463 — `d9afb52fb6e994d90f552ffbffd086dd16240558` | Exclue | Ses deux commits sont intégrés, dont la correction des marques après read-back |
| #437 — `b6709c4a76b1ee67daf95d911aa6908fbcbca758` | Exclue | Documentation reprise ; migration des caches de shaders exclue ; migration du cache pilote déjà couverte par #408 |
| #432 — commit nx2 `2e69168aae86df70e73b513b8c2717ef8ca4a7c3` | Exclue | Correctif NaN intégré une fois ; remplace la première version de ce correctif dans #437 |

#408 contient déjà les ports de #174, #250, #288, #319 et Eglantine #634/#639.
Ils n’ont pas été rejoués séparément. Fusionner toute la branche de #437 aurait également
importé des changements nx2 postérieurs à 95 ; seuls les éléments retenus ci-dessus sont portés.
B ne reprend pas tous les correctifs nx2 récents, notamment #351.

**Conflits et adaptations**

Quatre conflits de #408 avec la build 95 ont été résolus :

- `host_memory.cpp` : conservation de l’implémentation de déplacement/fallback déjà corrigée dans 95.
- `core.cpp` : conservation de la gestion des échecs d’allocation, avec les changements de cycle de vie de #408.
- `spirv_emit_context.cpp` : conservation de tous les atomiques de 95 et application de DontInline à leurs helpers.
- `vk_rasterizer.h` : conservation du masque des sorties fragment et du nouvel état de contournement OOT.

#465 et les deux commits de #463 s’appliquent ensuite sans conflit textuel.
La hausse de version de cache de #432 était déjà couverte par #408 et n’est pas appliquée deux fois.
A utilise le cache v54 ; B utilise v55 pour distinguer ses clés conservatrices et son émission NaN.
La migration des caches de shaders de #437 est incompatible avec les clés modifiées de #408 :
elle reste exclue. Les dossiers portables séparés isolent aussi les caches et sauvegardes.

Un [signalement AMD d’écran titre noir](https://github.com/zortos293/Lichii/pull/408#issuecomment-6700864827)
a isolé le masquage des attributs de sommets de #408. A conserve cette modification comme témoin.
B garde tous les types VertexA/VertexB et conserve la réduction des clés task/mesh.
Cette adaptation n’a pas été validée en jeu sur RX 7800 XT.

**Vérifications réellement exécutées**

Chaîne de compilation Windows de la build 95 : runner `windows-2022`, MSVC x64,
Ninja, Qt 6.8.3 + Charts, SDK Vulkan officiel 1.4.341.1 ; Release avec tests activés.
Les cinq cibles CTest réussissent pour chaque version : `tests`, `sdl_window_state_tests`,
`update_checker_tests`, `config_tests`, `compatibility_report`.
A : 31,80 s pour CTest ; B : 25,72 s. Ces durées ne sont pas des mesures de performances en jeu.

Les corrections de portabilité des tests conservent leurs assertions : valeurs attendues
opcodes/compteurs de types non signés, et fermeture des lecteurs du fichier temporaire NUP
avant son remplacement sous Windows. Le code applicatif de l’éditeur NUP reste celui de 95.
Les tests d’installation/exemples de zlib sont désactivés avec `ZLIB_BUILD_TESTING=OFF`,
car la dépendance est consommée avec `ZLIB_INSTALL=OFF`. Aucun test Lichii n’est exclu.
Le pointeur local `state` de #408 est renommé `bypass_state` pour respecter l’avertissement MSVC C4458.

Les deux packages ont passé : présence de lichii.exe et eden-cli.exe, déploiement Qt,
présence de `plugins/platforms/qwindows.dll`, analyse des imports DLL et des binaires x64,
et lancement de l’interface pendant 15 secondes avec PATH limité au package et à Windows.
Aucun jeu n’a été ouvert. Les fichiers créés par ce test sont supprimés avant distribution.
Le contenu des ZIP téléchargés, leurs CRC, leurs en-têtes PE x64 et leurs empreintes SHA-256
ont aussi été vérifiés. Chaque ZIP contient seulement les deux exécutables attendus,
les bibliothèques/plugins, les fichiers de traçabilité et un dossier portable neuf.

Les archives incluent `COMMITS.json`, `COMMITS.txt`, `BUILD.txt`, `README-CUSTOM.md`,
les journaux `validation/`, la licence et `user/config/README.txt`.
Les SHA-256 ci-dessous concernent le ZIP portable à l’intérieur de l’artifact GitHub :

- `lichii-custom-A-windows-x64-931a23fa89.zip` : `ced8b37bc35fc857a988a73e66786a0732d154593265d3d87c8f2bb98b50d445`
- `lichii-custom-B-windows-x64-eb15e81067.zip` : `ae02899892bf8aecf589f9798a99715681ace6ecdb5aabb6d1e82b474d641486`

**Installation portable et premiers essais**

1. Téléchargez l’artifact puis extrayez le ZIP portable qu’il contient dans un dossier neuf,
   distinct de la build 95 et de l’autre variante.
2. Conservez le dossier `user/config` fourni, puis lancez `lichii.exe`. Aucune installation de runtime n’est requise.
3. Gardez vos sauvegardes originales intactes ; utilisez des copies jetables si vous testez une progression existante.
   N’utilisez pas la migration des données de l’installation existante.

B est le candidat AMD à essayer en premier. Commencez par Vulkan, GPU accuracy High pour
contrôler le rendu, et Native async draws = Wait. Comparez Normal séparément : High désactive
le split GPU et peut changer fortement les performances.
Dans B, Bounded avec un budget de 8 ms est une expérience facultative après ce premier contrôle ;
il peut supprimer des dessins en attente et produire des flashes. Laissez
`EDEN_NX2_ASYNC_DISCARD` non défini, car sa valeur 1 force Skip.
`EDEN_NX2_TC_SKIP_STALE=0` désactive l’optimisation de #463 si vous constatez des artefacts.
Le contournement OOT reste sur Game ; No sharpening est une comparaison visuelle facultative.
Testez un changement à la fois, et distinguez les sessions à cache froid des sessions à cache chaud.

Aucun benchmark sur Ryzen 5 9600X / RX 7800 XT, aucun essai en jeu à 1440p et aucun test de
stabilité prolongé n’a été effectué. Les effets individuels des PR de B ne sont pas mesurés.
Le test d’interface vérifie le chargement du package et de Qt ; il ne valide pas le rendu du jeu.
Aucun gain FPS n’est annoncé.

Le workflow est manuel uniquement, Windows x64 uniquement, avec `contents: read`,
checkout sans conservation des identifiants et aucun secret fourni au code expérimental.
Il publie uniquement les artifacts et diagnostics. Mise à jour automatique et Discord sont
désactivés à la compilation ; aucun job de release ou de création de tag n’est présent.
