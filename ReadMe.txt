TriviaBot Turtle WoW 2.0.0-alpha24

TriviaBot-TurtleWoW v1.0

TriviaBot-TurtleWoW is a fun trivia bot, which can be used as a way to distract yourself and others when hanging under tents, sitting around campfires, grinding, during raids, or when idling in one of the major cities.

Plot twist: We're adding TurtleWoW questions! Currently at 17 questions!

The author does not take any responsibility for wipes and equipment damage caused as a result of using this mod Kappa

The mod maintains a list of top scorers which is printed out after every 5th question. It also keeps speed-records for the quickest answers. It allows you to switch the channel at any point, but if you want to change the question list you will need to stop the Trivia Bot first.

This addon was forked from Road-blocks TriviaBot which is based on the RaidTrivia mod by Psy on Frostwolf, the 'normal' question list is his, as are small parts of the code. The geography question set is sourced from opentrivia.com. The WoW questions were written by Road-block.

Command List:
/trivia channel [SAY|PARTY|RAID|GUILD|<custom channel>] - Sets the trivia channel.
/trivia start	- Starts the trivia game.
/trivia stop 	- Stops the current game.
/trivia skip 	- Skips the current question.
/trivia shuffle - Reshuffles the questions (restarts from beginning)
/trivia clear   - Clears the scores.
/trivia qlist [wow|normal|geography] -  Select the question list.
/trivia help    - In-game help display

Included Questions:
Normal (2632 questions)
WoW (1010 questions)
Geography (135 questions)
Turtle (17 questions)

Submit a TurtleWoW question:
<TurtleWoW Forum link goes here>

Changes
v1.0

- Initial Release


TriviaBot 2.0.0-alpha2 (development build)
----------------------------------------
- Fixed matching for alternate answers 4 through 8.
- Fixed a Turtle WoW question whose answer was stored in an undefined answer array.
- Answers are matched case-insensitively and ignore leading/trailing spaces.
- Restored classic scoring: the first correct answer closes the question and earns one point.
- Fixed matching for alternate answers 4 through 8.
- Fixed a Turtle WoW question whose answer was stored in an undefined answer array.
- Answers ignore letter case and leading/trailing spaces.
- Added session-wide fastest and slowest winning-answer records.
- Added English, French, and mixed WoW question lists with 30 new questions in each language.
- Added safer empty-bank handling, improved scheduled-event processing, and restored the private score reply.
- Starting a new session resets speed records but keeps the existing score table.

Payments are handled manually between players and the organizer.


New question list commands
--------------------------
/trivia qlist wow       - Compatibility alias for the expanded English WoW bank.
/trivia qlist wowen     - English WoW questions.
/trivia qlist wowfr     - French WoW questions.
/trivia qlist mixed     - English and French WoW questions mixed together.
/trivia qlist normal    - Original general-knowledge questions.
/trivia qlist geography - Original geography questions.

Payments are handled manually between players and the organizer.


TriviaBot 2.0.0-alpha3
----------------------
- Corrected the Rogue Tier 3 answer to Bonescythe (also accepts Bonescythe Armor).
- Added a movable, in-game question browser inspired by the classic WoW UI.
- Added manual question selection and an Ask Selected Question action.
- Added a separate, hideable leaderboard window with score pagination and session speed records.
- Added /trivia ui (or /trivia menu) and /trivia board (or /trivia scores).
- The question browser can switch between WoW English, WoW French, mixed WoW, general knowledge, and geography banks while the game is stopped.
- Manual questions use the same classic first-correct-answer scoring and timeout rules.

This remains an alpha build. The in-game UI must be tested on a Turtle WoW client before public release.


TriviaBot 2.0.0-alpha4 — core addon
-----------------------------------
- The core addon no longer bundles the additional English/French WoW question banks.
- The original WoW, Normal, and Geography banks remain included.
- Optional English and French WoW questions are distributed as a separate addon:
  TriviaBot-TurtleWoW-Questions.
- Install the optional extension only if you want the extra English/French questions.
- Without the extension, /trivia qlist wowen continues to use the original English WoW bank.
- /trivia qlist wowfr and /trivia qlist mixed require the optional extension.
- The main UI and leaderboard remain included.

Install the optional extension in Interface/AddOns/TriviaBot-TurtleWoW-Questions
alongside the core TriviaBot-TurtleWow folder. Enable both addons on the character
select screen. The extension depends on the core addon.


Version 2.0.0-alpha5
- Integrates a French translation bank for the original WoW question set into the Core.
- /trivia qlist wowfr works without the optional Questions extension.
- /trivia qlist mixed includes the original English and French base banks.
- Optional English/French question packs remain separate and are appended only when installed.
- English accepted answers are retained as aliases in the French bank.


TriviaBot 2.0.0-alpha6 — Core FR
--------------------------------
- Intégration dans le Core d'une banque française correspondant aux 1 027 questions WoW originales.
- La banque anglaise d'origine reste disponible.
- Sélection des banques : /trivia qlist wowen, /trivia qlist wowfr, /trivia qlist mixed.
- Les questions supplémentaires restent dans l'extension facultative TriviaBot-TurtleWoW-Questions.
- Vérification statique : XML valide, index français complets et archives lisibles. Pas encore de test en client Turtle WoW.


Payments are handled manually between players and the organizer.


Alpha24: clearer betting announcements and tie instructions; !bet remains removed; contributions and payouts are exchanged manually in-game.


Alpha26: restored the visible Leaderboard toggle button in the main TriviaBot UI.
