# Setting up Shelter Ops

Three files, ~30–40 minutes the first time, no coding required. You'll create one free Supabase account (your database + login system + photo storage) and put one file online.

## 1. Create your Supabase project
1. Go to supabase.com → sign up (free, no card needed) → **New project**.
2. Pick any name/password for the project (the password is for the database itself, not for staff logins — write it down somewhere safe, you likely won't need it again).
3. Wait ~2 minutes for it to spin up.

## 2. Run the database schema
1. In your project, open **SQL Editor** (left sidebar) → **New query**.
2. Open `schema.sql` from this folder, copy all of it, paste into the editor, click **Run**.
3. This creates all your tables, security rules, and seeds rooms 01–34. If your rooms are numbered differently (e.g. 101–134), tell me and I'll adjust the seed line, or just edit room numbers later in Table Editor → `rooms`.

## 3. Create the photo storage bucket
1. Left sidebar → **Storage** → **Create bucket**.
2. Name it exactly: `maintenance-photos`
3. Leave **Public bucket** turned **OFF** (keeps photos private — important since some may document tenant damage).
4. The two storage policies were already created by schema.sql, so nothing else needed here.

## 4. Create staff logins
1. Left sidebar → **Authentication** → **Users** → **Add user**.
2. Add each of your 3–5 staff by email, set a temporary password, and share it with them directly (text/call — not email, since they'll need it to log in).
3. Once everyone's added, go to **Authentication → Providers → Email** and turn **off** "Allow new users to sign up" — this stops strangers from creating their own accounts, since only you should add staff.
4. Each staff member can change their password anytime with the "Forgot password" link on the login screen (it'll email them a reset link).

## 5. Connect the app to your project
1. In Supabase: **Settings → API**. Copy the **Project URL** and the **anon public** key.
2. Open `index.html` in any text editor, find these two lines near the top of the `<script>` block:
   ```
   const SUPABASE_URL = "YOUR_SUPABASE_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
3. Paste your values in between the quotes. Save.

## 6. Put it online (pick one, all free)
**Easiest — Netlify Drop:**
1. Go to app.netlify.com/drop
2. Drag `index.html` onto the page. Done — you get a live URL immediately.
3. (Optional) Netlify → Site settings → rename the site for a nicer URL.

**Alternative — GitHub Pages:** if you already use GitHub, push this file to a repo and enable Pages in repo settings.

Send the resulting URL to your 3–5 staff, and have them add it to their home screen (Safari/Chrome → Share → "Add to Home Screen") so it opens like an app.

## Updating an already-running install (this round: badges, snapshots, live sync, and more)
This update adds:
- **Tab badges** — a red count on Maintenance (open urgent/high issues) and an amber count on Inventory (low-stock items), visible the moment the app opens.
- **Condition snapshots** — on any room, "+ Condition snapshot" lets you take a dated set of photos with no issue attached, for a "before" record (handy at move-in).
- **Occupant name on Occupied** — optional, short (e.g. "Jamie K.") — see privacy note below before turning this into a habit.
- **Edit issue details** — fix a typo or wrong category/urgency without losing history.
- **Photo compression** — photos are resized before upload, so a room full of photos won't eat your phone's data or Supabase's storage quota anywhere near as fast.
- **Save-button lock** — buttons disable and show "Saving…" after one tap, so a slow connection can't create duplicate entries.
- **Printable room reports** — "🖨 Export report" on a room opens your browser's print dialog with all issues, snapshots, and photos laid out; choose "Save as PDF" there.
- **Live sync** — one person's change now appears on everyone else's screen within about a second, no refresh needed.

To update:
1. Re-run the whole `schema.sql` again in SQL Editor. It's now fully safe to re-run any time — every step either skips what already exists or replaces it cleanly, so it won't touch your existing data.
2. Replace your live `index.html` with the new version, and paste your Supabase URL/key back into the two config lines at the top (they reset to placeholders in every fresh copy I send you).

### A privacy note on occupant names
Recording a guest's name against a room ties condition evidence to a specific stay, which is genuinely useful if a damage dispute comes up. But it's also personal data about people in a vulnerable situation, held on a tool 3–5 staff can see. Worth deciding as a team:
- First name + last initial only (not full name) is usually enough to be useful without being identifying.
- Consider whether to clear the occupant name from a room's record some time after they leave, rather than letting it sit indefinitely — you could do this manually, or ask me to add an automatic clear-after-X-days rule if that'd help.
- It's optional per-room — leave it blank for anyone not comfortable using it, or if your organisation already has a formal record-keeping process this shouldn't duplicate.

## Notes
- Everything (issues, photos, inventory changes, vacancy status) is shared live across everyone's devices — no syncing step needed.
- Photos are private; only signed-in staff can view them. Each photo link that renders in the app expires after an hour for security, but the underlying photo is kept until you delete it.
- Staying on Supabase's free tier: 500 MB database + 1 GB file storage + 50,000 monthly active user checks — for 5 staff and normal shelter use, you won't come close to the limits. If photo volume ever grows large (thousands of high-res photos), Supabase's paid tier is pay-as-you-go and cheap (~$0.021/GB storage).
- The Shopping tab sorts items into "hardware run" vs "check secondhand first" using a plain $40 cutoff (plus category) — no AI involved. Change the cutoff by editing `SHOP_THRESHOLD` near the top of the `<script>` in `index.html`.
- Want me to add anything — e.g. exporting a damage report as a PDF for a specific tenant, or a dashboard of overdue urgent issues? Just ask.
