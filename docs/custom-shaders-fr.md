# Essai de la variante E — préparation des shaders

Cette variante expérimentale sert à comparer les pauses avec D. D reste la référence de rendu.
L'archive ne contient aucun shader de jeu précompilé. La préparation utilise votre jeu déjà
présent et votre pilote actuel, sans installation de Python ni d'outil de développement.

1. Extraire E dans un dossier neuf, distinct de D et de la build 95. Conserver le dossier user/config.
2. Dans E, jeu arrêté : clic droit sur Ocarina of Time → Configure Game → Adv. Graphics.
   Cocher « Shader libraries (faster first-time shader builds) », puis OK.
3. Clic droit sur le jeu → « Prepare shaders (warm-up) ». Attendre le résultat de cette préparation.
4. Lancer le jeu. La compilation par le pilote se fait ensuite en arrière-plan ; attendre la fin
   du compteur « Shader warm-up » dans un menu ou une zone calme avant de comparer un parcours.
   La première préparation complète peut être longue. Aucun temps de préparation AMD n'est mesuré.
5. Garder les mêmes réglages de jeu et de précision GPU qu'avec D, puis comparer les pauses,
   les ombres, les effets manquants et le fichier user/log/eden_log.txt. Conserver le dossier E
   entre les sessions pour réutiliser ses caches.

Le décompte de préparation des fichiers et le décompte de compilation par le pilote sont deux
étapes distinctes. Un message annonçant que les fichiers sont prêts ne signifie pas que toutes
les compilations Vulkan sont déjà terminées. Certaines variantes de shaders, notamment les
chemins non couverts par les bibliothèques, peuvent encore compiler pendant le jeu.

Le pilote doit fournir les bibliothèques de pipelines Vulkan avec liaison rapide. Si cette
capacité manque, E garde le chemin habituel et le journal indique pourquoi. Aucun gain sur
RX 7800 XT n'est garanti. Si le rendu se dégrade, revenir à D dans son dossier intact pour
comparer. Désactiver Shader libraries retire les bibliothèques graphiques ; la préparation
compute déjà générée peut encore s'exécuter. « Delete shader warm-up » retire les fichiers de
préparation de E, sans toucher aux sauvegardes ni au dossier D.

L'historique de jeu rend la préparation plus pertinente. E utilise son propre historique
lorsqu'il existe. Après avoir joué dans E, « Rebuild shader warm-up » permet de le prendre
en compte. Les limites du premier essai sans historique doivent être distinguées d'un essai
préparé avec les états réellement rencontrés.

Option avancée, facultative : E sait lire une COPIE du seul fichier vulkan.fork-v55.bin de D
pour déduire ces états, sans utiliser ses pipelines en jeu. Les deux émulateurs doivent être
fermés. Copier ce fichier de D/user/cache/shader/0400486024dec000/ vers le même sous-dossier
dans E, avant la première préparation. Garder son nom v55 ; ne pas le renommer en v56 et ne
pas copier le dossier user entier. Le fichier d'origine et toutes les sauvegardes restent
intacts. Aucun fichier de cache n'est envoyé à un service en ligne.
