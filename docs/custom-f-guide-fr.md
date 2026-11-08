# Lichii Custom F Build117 — essai portable

Extraire le ZIP dans un nouveau dossier distinct de la build117 et de C/D/E. Garder le
dossier user/config fourni. Lancer lichii.exe : aucune installation de runtime ou d'outil
sur le PC n'est nécessaire. Les réglages, caches et données de F restent dans son dossier
user. Ne pas utiliser une migration vers les données originales. Pour tester une progression,
utiliser uniquement une copie jetable de sauvegarde et garder l'original intact.

Commencer avec Vulkan, la RX 7800 XT sélectionnée, une fenêtre/écran à 2560x1440, résolution
interne 1x et les autres réglages avec lesquels D affiche correctement les ombres. La taille
de la fenêtre et la résolution interne du jeu sont deux réglages distincts. Comparer une
augmentation de résolution interne seulement après le contrôle du rendu et des pauses.

Les options de 117 sont conservées. Pour l'asynchrone : jeu arrêté, clic droit sur Ocarina
→ Configure Game → Ext. Graphics → Enable asynchronous shader compilation. Dans Adv. Graphics,
Switch 2 draws with unbuilt pipelines → Bounded wait et Pipeline wait per frame → 8 ms.
Ce mode peut omettre des dessins en attente : si des effets ou objets disparaissent, comparer
Wait. Il ne couvre pas toutes les compilations compute et ne garantit pas zéro pause.

La préparation de shaders est expérimentale et désactivée par défaut. Pour un essai séparé :

1. Clic droit sur le jeu → Configure Game → Adv. Graphics → activer Shader libraries.
2. Jeu arrêté, clic droit → Prepare shaders (warm-up), puis attendre la génération des fichiers.
3. Lancer le jeu ; la compilation par le pilote constitue une seconde étape. Attendre la fin
   du compteur Shader warm-up dans une zone calme avant de comparer le parcours.
4. Garder le dossier de F entre les lancements. Un historique joué dans F peut être repris
   ensuite par Rebuild shader warm-up pour améliorer les états préparés.

La durée initiale peut être longue et dépend du pilote. Les capacités Vulkan nécessaires
sont vérifiées ; si elles manquent, le chemin officiel reste utilisé et le journal le précise.
Ne pas copier ou renommer les anciens caches D/E en caches F. Le jeu déjà disponible sur
le PC fournit les shaders ; aucun pack externe, jeu, firmware ou clé n'est téléchargé.

Comparer un seul changement à la fois : ombres, végétation, brouillard, transparences, pauses,
et même trajet à cache froid puis chaud. Le journal est user/log/eden_log.txt. Les tests cloud
ne reproduisent pas une RX 7800 XT et aucun gain FPS n'est annoncé.

Les notes officielles de build117 signalent des traînées blanches nocturnes avec le remplacement
DLSS activé : si elles apparaissent, désactiver « Use NVIDIA DLSS in place of a game's DLSS »
pour comparer. Les fonctions de mise à jour officielles restent présentes ; installer une
version officielle par l'updater remplacerait les modifications Custom F dans son dossier.
