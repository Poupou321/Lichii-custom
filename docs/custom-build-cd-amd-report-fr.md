# Lichii Custom AMD — variantes C et D

La référence commune est la build 95 : `222877d4f7c8945b2f31a87b76d09f0a92e4f1b8`.
Ces variantes prolongent B ; les intégrations et exclusions de B restent celles du
[rapport A/B](custom-build-95-amd-report-fr.md). Aucun gain FPS n'a été mesuré.

| Variante | Source compilée | Ajout par rapport à B | Résultat |
|---|---|---|---|
| C | `eb34897cff9988a965c7652763236de26ee3ae5c` | #448, fallback RGBA8 des mipmaps ASTC irrégulières sur AMD | Release réussie, 5/5 cibles CTest |
| D | `aadd0154fe18bb9504dbcf9adf009039e95f53d8` | C + #351, portée des buffers de données d'éclairage | Release réussie, 5/5 cibles CTest |

C intègre #448 à la révision `af501da4b066e5b8c168b4ea795b516655bf82a6`.
Cette modification vise des coutures sombres sur les textures lointaines et peut augmenter
la consommation de VRAM. Comparaison sans le correctif : lancer avec
`EDEN_NX2_UNEVEN_BCN_RGBA8=0`. Elle ne prouve pas la correction des silhouettes noires
persistantes signalées sur les captures de l'utilisateur.

D porte le correctif #351, fusionné en amont après la référence 95 au commit
`b72195422b6c474c49b7143e880b882cbd3c1f46`. Les lectures via pointeurs de table
peuvent atteindre la fin de la zone mappée, dans les limites du pilote et de 1 Gio,
avec une réserve de 64 Kio. Cela permet d'atteindre les sondes d'éclairage situées au-delà
de l'ancienne limite de 64 Mio. Les limites d'écriture restent conservées.
Le conflit Vulkan conserve l'appel existant `multi_range_buffers.TickFrame()`.
Ce correctif ne nécessite pas de réglage utilisateur supplémentaire.

La première compilation D a échoué : le faux runtime utilisé par les tests n'exposait pas
`GetMaxStorageBufferRange()`, désormais appelé par le cache de buffers.
La correction fournit cette capacité dans le test, adapte l'attente de l'ancien test à la
nouvelle portée de 80 Mio et ajoute des cas vérifiant la limite pilote de 128 Mio et la
limite logicielle de 1 Gio. Les assertions sur les écritures et les pointeurs natifs restent
présentes. Aucun test Lichii n'est retiré.

Les branches C/D déclenchaient initialement une compilation sur push. Cette configuration
a été corrigée : les workflows nx2, C et D utilisent uniquement `workflow_dispatch`, avec
`contents: read`. Aucun job de release publique. La correction de workflow seule sur C est
`97bb9e0310b4b86da31618f8f666bcd197a12088` ; elle ne change pas le programme de son artifact.

## Vérifications et téléchargements

C : [compilation](https://github.com/Poupou321/Lichii-custom/actions/runs/42392392412),
[artifact portable](https://github.com/Poupou321/Lichii-custom/actions/runs/42392392412/artifacts/13583414354).
Les cinq cibles `tests`, `sdl_window_state_tests`, `update_checker_tests`, `config_tests`
et `compatibility_report` réussissent. La suite principale comporte 858 cas, les trois
suites auxiliaires respectivement 4, 8 et 7 cas. Le package passe l'analyse des imports DLL,
le déploiement Qt et un lancement d'interface de 15 secondes avec PATH restreint.
Vérification indépendante du ZIP téléchargé : CRC et SHA-256 corrects, 35 fichiers PE x64,
`lichii.exe`, `eden-cli.exe` et `plugins/platforms/qwindows.dll` présents.

ZIP intérieur C : `lichii-custom-C-windows-x64-eb34897cff.zip`.
SHA-256 : `5b3171940a955664f7d3cd551b784d46d3f93c61a8748389631e5b884e541cce`.

D : [nouvelle compilation](https://github.com/Poupou321/Lichii-custom/actions/runs/42403988738).
[Artifact portable D](https://github.com/Poupou321/Lichii-custom/actions/runs/42403988738/artifacts/13586861775).
Les cinq cibles CTest réussissent ; la suite principale comporte 859 cas, les trois suites
auxiliaires respectivement 4, 8 et 7 cas. Le déploiement Qt, l'analyse des imports DLL et le
test d'interface de 15 secondes réussissent. Vérification indépendante du ZIP téléchargé :
CRC et SHA-256 corrects, 35 fichiers PE x64 et un dossier portable vierge.

ZIP intérieur D : `lichii-custom-D-windows-x64-aadd0154fe.zip`.
SHA-256 : `8ed106a37d024f2075b876e0e5012ca247413851f0f982c450fd9646a294eb86`.

Chaque archive contient `COMMITS.json`, `COMMITS.txt`, `BUILD.txt`, les journaux de validation,
la licence et le dossier portable. Les artifacts sont conservés 14 jours après publication.

## Essai sur le PC cible

Extraire chaque ZIP intérieur dans un nouveau dossier distinct de la build 95 et des autres
variantes. Conserver `user/config` fourni et lancer `lichii.exe`. Les originaux des sauvegardes
restent intacts ; une progression existante ne doit être testée qu'avec une copie jetable.
Les archives ne contiennent ni jeu, firmware, clés ni pack de shaders précompilés.

Pour comparer le défaut d'ombres persistant, utiliser la même scène et les mêmes réglages
entre C et D. Le statut graphique FAST correspond à la précision GPU basse ; ACCURATE à la
précision élevée. Une comparaison en ACCURATE après redémarrage du jeu est utile, mais peut
réduire les FPS en désactivant le traitement GPU partagé.

Pour les pauses de compilation, activer la compilation asynchrone des shaders. Le mode
`Native async draws = Bounded`, budget 8 ms, peut réduire certaines attentes de pipelines
graphiques ; il peut aussi omettre des dessins en attente et provoquer des flashes. Wait
reste le réglage par défaut. Toutes les pauses, notamment de compilation compute, ne sont
pas couvertes. Tester un changement à la fois.

Les validations cloud ne lancent aucun jeu et ne reproduisent pas une RX 7800 XT.
Ni le rendu des ombres, ni la fluidité à 1440p, ni la stabilité prolongée ne sont donc validés.
Aucun changement de pilote Windows et aucune installation d'outil sur le PC ne sont nécessaires.
