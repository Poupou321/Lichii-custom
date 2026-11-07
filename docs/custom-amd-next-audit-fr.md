# Audit complémentaire AMD / OoT — 7 novembre 2026

Base étudiée : variante D `aadd0154fe18bb9504dbcf9adf009039e95f53d8`.
Snapshot Eglantine nx2 consulté : `ae9d3eb8d224e85b9fc4ec1df35f2825e13aef76`.
D est compilée et vérifiée dans le cloud ; aucun résultat en jeu de D n'a encore été fourni.
Aucun changement supplémentaire de rendu n'est intégré à la suite de cet audit.

| Candidat | Révision examinée | Constat et décision |
|---|---|---|
| [#354](https://github.com/zortos293/Lichii/pull/354) | `174c497314ae2aac886bfbf9b4501ac5c255ab97` | Support de tableaux de shadow maps absent de D. Amont décrit une teinte verte sur RX 7900 XTX, différente des ombres noires signalées ici. Nombreux conflits ; attendre des éléments identifiant le défaut. |
| [#579](https://github.com/zortos293/Lichii/pull/579) | `9db91fc6c1ba261c6ffb1c07e51937393a5d1f92` | Bibliothèques de pipelines et préparation des shaders absentes de D. La PR prend en compte les modes #465, mais le port vers notre base 95 présente de nombreux conflits. Tests amont NVIDIA Windows, AMD non testé. Éventuel travail dans une branche isolée après diagnostic des pauses. |
| [#557](https://github.com/zortos293/Lichii/pull/557) | `92518b24c54cd65788f99beb65b7cc941299ed7e` | Invalidation des slots de pointeurs compute devenus mappés, absente de D ; port Eglantine `688c6fa7d847abffebdb22874fb902ec64707096`. Application textuelle possible, mais vise des feuillages absents et peut ajouter des reconstructions. Non retenue sans symptôme correspondant. |

La branche de #408 a évolué depuis le head épinglé dans nos builds. Deux changements
récents sont absents de D et demandent une étude isolée :

- [9991f2782489eab997515ec22c54e876e62c79dc](https://github.com/zortos293/Lichii/commit/9991f2782489eab997515ec22c54e876e62c79dc) : conserve l'upload des images compressées après une copie d'alias incomplète.
- [d0a7b1ff386f45227c64b0efc1fb5c7777697460](https://github.com/zortos293/Lichii/commit/d0a7b1ff386f45227c64b0efc1fb5c7777697460) : limite DontInline aux helpers compute, suite à une régression NVIDIA 580.x. La pertinence AMD reste à établir.

Aucun de ces constats ne prouve la cause des silhouettes noires de l'utilisateur.
La PR #408 complète ne doit pas être rejouée : nos variantes possèdent déjà sa révision
épinglée avec des adaptations AMD et des résolutions de conflits propres à la base 95.

Doublons écartés : la condition depth-compare vers float de Eglantine #721 est déjà dans D.
Les correctifs AMD compute/shuffle et AVX-512 repris dans Eglantine #723 sont également
déjà présents ; aucune fusion globale de ce bundle n'est prévue.

La prochaine information utile est un essai de D dans la même scène, à réglages identiques
à B, et son `user\\log\\eden_log.txt`. Pour le rendu, comparer ensuite FAST à ACCURATE
après redémarrage du jeu en ne changeant que ce réglage. Pour les pauses, distinguer
premier parcours et deuxième parcours à cache chaud, dans la même installation portable.
Aucun téléchargement de pack de shaders externe n'est nécessaire à ces comparaisons.

Les archives et vérifications de C/D sont décrites dans le
[rapport C/D](custom-build-cd-amd-report-fr.md).
