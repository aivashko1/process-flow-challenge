# Process Flow Challenge: Caffeine Distribution

A browser-based learning game for process mapping, in a single file, `index.html`:

- no installs or accounts for players
- the only network calls are the session saves to Supabase

Hosted on **Vercel**, which redeploys automatically on every push to `main`.

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

## Collecting data (Supabase)
Sessions save automatically to the Supabase project **process-flow-challenge** (organization: Team Ivashko). The game saves:
- at Start
- every 3 minutes during the build
- when the build ends
- after the reflection
- when the player clicks Finish
- when the tab closes (best effort)

Each save is a new row in `session_saves`; nothing is overwritten.

**Reading results:** in the Supabase dashboard, open **Table Editor**:
- `session_summary`: one row per player, from their latest save. It shows code, condition, number of AI Friend requests, when the first one came, draft and final scores, confidence at start and end, and all reflection answers. The full session record is in `payload`.
- `feedback_uptake`: one row per piece of feedback. It shows when the feedback came, which criteria it covered, whether the player revised within 3 minutes, whether the edit matched the feedback, and the score before and after.

**Security:** the game uses Supabase's *publishable* key, which is designed to be public. Database rules allow a browser only to *add* rows; reading, changing or deleting data from the browser is refused. The full setup is in `supabase-setup.sql`.

**Backup:** players can still click **Download data (JSON)**, and the **Facilitator ▾** menu has *Save to database now* and *Export data (JSON)*. If the database can't be reached, the game tells the player to download instead.

## Editing content
Open `index.html` in a text editor. All content sits in two objects at the top of the script, and you change the game by editing only these:

- `GAME_CONFIG`: scenario, SOP text, rubric, timings, warm-up, reflection and debrief questions.
- `COACH_CONFIG`: the built-in coach's checkpoints, wording, keywords, priorities and hints.

## About "AI Friend"
AI Friend is a **built-in, rule-based coach**. It is not a generative AI model and makes no external calls. It analyses the structure and labels of the learner's map against an encoded model of the SOP and the rubric. For the same map, it always gives the same feedback.
