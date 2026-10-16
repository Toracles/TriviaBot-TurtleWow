# TriviaBot for Turtle WoW

**Maintainer / addon author:** `CloudNine_Ex`  
**Target:** Turtle WoW 1.18.1  
**Current development build:** `2.0.0-alpha27`

TriviaBot is an in-game trivia and quiz addon for Turtle WoW. It lets an organizer ask questions, track player scores, display a leaderboard, and run short quizzes with a configured question count.

> This repository is an ongoing community project. The current alpha builds are experimental; test them in-game before using them for an event.

## Features from the original addon

- In-game trivia interface and question browser.
- Multiple question banks/categories, including WoW English, WoW Français, WoW Mix, General Knowledge and Geography.
- Ask a selected question or start with a random question.
- Chat-based answers and scoring.
- Score tracking and leaderboard display/publication.
- Fastest and slowest answer records.
- Controls to start, stop and skip questions.
- Configurable chat channel for quiz announcements and leaderboard publication.

## Turtle WoW updates and improvements by CloudNine_Ex

- **French question bank integration:** integrated the French base question bank into the core addon while keeping the optional extra-question pack separate.
- **Optional question extension support:** additional French/English questions can be distributed separately rather than bundled into the core.
- **Quiz length presets:** choose a 5-, 10- or 20-question quiz; the quiz ends after the selected number of questions.
- **Contribution guidance for quiz events:** suggested minimum contributions based on quiz length:
  - 5 questions: 1 silver per player
  - 10 questions: 5 silver per player
  - 20 questions: 10 silver per player
- **Manual payment workflow:** payments are handled through direct in-game trades with the organizer. There is no `!bet` chat command and the addon does not transfer money automatically.
- **Betting/event announcements:** the start button announces the planned quiz length, contribution guidance, 30-second contribution window at the start of each question, and the payout/tie rules.
- **Payout rules communicated to players:**
  - One winner: 70% to the winner, 30% to the organizer.
  - Two players tied: either a random tie-break question, `/roll` (highest roll wins), or a shared payout where 85% of the pot is split equally between the two winners and 15% goes to the organizer.
- **Tie-break UI:** displays the tied players and presents the available tie-break options.
- **Leaderboard UI fixes:** restores the visible Leaderboard toggle and keeps the leaderboard associated with the main TriviaBot window.
- **UI refinements:** layout and controls adjusted to fit the quiz length and leaderboard controls.
- **Chat compatibility fixes:** leaderboard messages are formatted to avoid WoW chat escape-character issues.

### Important notes about contributions and payments

The addon cannot reliably detect WoW trade-window transactions. The organizer must keep track of contributions and make the agreed payments manually. The 30-second window is an announcement/event rule; it does not lock the WoW trade system.

## Installation

1. Download the latest ZIP from the repository's **Releases** section (or the repository's Code menu while testing).
2. Extract the `TriviaBot-TurtleWow` folder.
3. Copy it into your Turtle WoW installation at:

   `Interface/AddOns/TriviaBot-TurtleWow`

4. If replacing an existing installation, back up the old folder first.
5. Log in and run `/reload`, or restart the client.
6. Open the interface with:

   `/trivia ui`

The optional question extension, when distributed separately, should be installed as its own addon folder alongside the core addon.

## Starting a quiz

1. Open `/trivia ui`.
2. Select the quiz length (5, 10 or 20 questions).
3. Make sure the correct question bank is selected.
4. Click **Start + annonce** to start the quiz and announce the event rules.
5. Use **Stop**, **Skip**, or the question browser as needed.
6. Use **Leaderboard** to show or hide the score window.

Contributions and final payments are agreed and exchanged manually in-game. Keep your own record of who paid and which payouts have been completed.

## Useful commands

- `/trivia ui` — open the main interface.
- `/trivia help` — show available commands.
- `/trivia board` — show or hide the participant leaderboard.

Some commands may vary between alpha builds; the in-game `/trivia help` output is the authoritative list for the installed version.

## Credits

A big thank-you to **LizardBerry** for their work on the original TriviaBot-TurtleWoW project. This project builds on that foundation.

The addon also retains upstream code and question-bank lineage from the projects and contributors credited in the original files, including Roadblock, Guri and Psy. Their existing credits are preserved in the source where applicable.

## Development status

This is an **alpha** build. Features, layout and commands may change. Please report bugs with:
- Turtle WoW client/version
- the exact steps to reproduce the issue
- Lua errors from the error window, if any
- a screenshot when the problem is visual

## License

This project is distributed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [`LICENSE`](LICENSE) file for the full license text.
