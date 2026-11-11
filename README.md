# Process Flow Challenge: Caffeine Distribution

A self-contained, browser-based learning game for process mapping. It is one file, `index.html`:

- no installs, accounts or API keys
- no network calls after the page loads

## Run it locally
Double-click `index.html`. It opens in Chrome, Edge, Safari or Firefox.

## Deploy on GitHub Pages
1. Create a new GitHub repository (it can be private if your plan supports private Pages).
2. Upload `index.html` (and this README) to the repository root, then commit.
3. In the repository, go to **Settings → Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**, select the `main` branch and the `/ (root)` folder, then **Save**.
5. After about a minute, the site is live at `https://<your-username>.github.io/<repo-name>/`.

## Facilitator links
| Purpose | URL |
|---|---|
| Standard session (coach available) | `…/index.html` |
| Comparison group (no AI Friend) | `…/index.html?coach=off` |
| Dry run with short timers | `…/index.html?teach=1&read=1&build=3` |

The timers default to 5 / 5 / 15 minutes (instruction / SOP reading / build).

## Collecting data
- Nothing is stored on a server or in the browser.
- At the end of a session, the participant (or facilitator) clicks **Download data (JSON)** on the Debrief or Thank-you screen. The **Facilitator ▾** menu also exports at any time.
- Files are named like `PFC_P01_2026-11-10.json`.
- An event-log CSV and a PNG of the final map are also available.
- If the tab is closed before export, the browser shows a warning.

## Editing content
Open `index.html` in a text editor. All content sits in two objects at the top of the script, and you change the game by editing only these:

- `GAME_CONFIG`: scenario, SOP text, rubric, timings, warm-up, reflection and debrief questions.
- `COACH_CONFIG`: the built-in coach's checkpoints, wording, keywords, priorities and hints.

## About "AI Friend"
AI Friend is a **built-in, rule-based coach**. It is not a generative AI model and makes no external calls. It analyses the structure and labels of the learner's map against an encoded model of the SOP and the rubric. For the same map, it always gives the same feedback.
