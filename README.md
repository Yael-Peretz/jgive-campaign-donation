# Jgive Campaign Donation Page

A Rails reproduction of the Jgive "Orange Garden" campaign donation page (reference: [jgive.com/.../donation-targets/159183](https://www.jgive.com/new/en/ils/donation-targets/159183)) — campaign details, tabs, a donation form that creates a `pending` donation and updates the campaign's progress. No payment/checkout, no accounts/admin, per the assignment scope.

**Live app:** https://jgive-assignment.onrender.com
**Repo:** https://github.com/Yael-Peretz/jgive-campaign-donation

## Running locally

Requires Ruby 3.3.1 (see `.ruby-version`) and SQLite — no Node/Postgres needed.

```bash
bin/setup        # bundle install, prepare the db
bin/rails db:seed
bin/dev          # rails server + tailwind --watch
```

Visit `http://localhost:3000`.

## Key decisions & trade-offs

- **`raised_amount` / `progress_percentage` are derived, not stored.** `Campaign` has no
  `raised_amount` column — both are computed from the `donations` association on read. At this
  scale, deriving from the source of truth is simpler than keeping a denormalized counter in sync,
  and it can't drift out of sync with the actual donation rows.
- **`progress_percentage` returns one decimal place.** With a ₪5,000,000 goal, early donations
  produce sub-1% progress that would round to 0 with integer rounding. Using `round(1)` keeps the
  bar visible and the badge shows "< 1%" rather than "0%". A minimum bar width of 0.5% is applied
  in the view whenever any amount has been raised.
- **Pending donations count toward progress.** The assignment explicitly wants progress to move
  when a donation is submitted, but there's no payment flow to ever produce a `paid` one. A
  `Donation.countable` scope (currently `pending` + `paid`) is what gets summed, so narrowing it to
  `where(status: :paid)` later is a one-line change.
- **Donor name is required unless the donor chooses to stay anonymous.** Anonymity means skipping
  the name entirely, not just hiding an internally-collected one.
- **Campaign cover is a YouTube URL, not an image file.** The Orange Garden campaign's cover is a
  video, so `cover_image_url` stores the YouTube URL. A `youtube_video_id` model method extracts
  the video ID; the view renders the thumbnail as the hero and opens the video inline via
  a `<dialog>` lightbox (using a `video` Stimulus controller that sets/clears the iframe `src`
  to control playback). No Active Storage, no external image host.
- **Readable campaign URLs via a plain `slug` column + `to_param` override**, not the `friendly_id`
  gem — one column, one callback, one `find_by!` didn't justify the dependency.
- **Tailwind via `tailwindcss-rails`** (standalone binary), not a Node toolchain — keeps the app
  consistent with the existing importmap/Propshaft setup from `rails new`.
- **SQLite on Render's free tier, no persistent disk.** Render's free instances have an ephemeral
  filesystem, so `bin/docker-entrypoint` runs `db:prepare` + `db:seed` on every boot — the app is
  never blank, at the cost of donations not surviving a spin-down/restart. Upgrading to a paid plan
  + a real disk is a one-line `render.yaml` change if that trade-off stops being acceptable.
- **English/LTR**, not Hebrew/RTL. The build mirrors the reference's sections, tabs, and donation
  flow structurally, but not its language or text direction.
- **Donation form is a popup, not an always-visible inline form.** Uses the native `<dialog>`
  element + a small Stimulus `modal` controller — focus-trapping, Esc-to-close, and the backdrop
  come from the browser for free.

## UI design

The page closely follows the live JGive reference:

- **Full-width video hero** — YouTube thumbnail with a centred play button; clicking opens the
  video inline in a `<dialog>` lightbox. Closing the dialog clears the iframe `src` to stop
  playback.
- **Stats bar** — raised amount, gradient progress bar (orange → pink → purple), donor count and
  goal amount. The bar uses a minimum visible width of 0.5% whenever any amount has been raised.
- **Sidebar** — bit button, purple-gradient DONATE button (opens donation modal), Join as
  Participant outline button, tax-deductible country badges, and share icons.
- **Tab navigation** — Project Info and Recent donations are functional; Leaderboard, Teams,
  Non-Profit Info, and Updates are visible placeholders matching the reference's tab bar.
- **Donation modal** — preset amounts with per-campaign labels (Plant a Tree of Life / Plant Two
  Trees / etc.), One Time / Recurring toggle, ILS badge, live "Total to pay" counter, "Write a
  comment" checkbox that reveals the dedication message field, and a green Continue button.
- **Donation cards** — 2-column grid; each card shows amount, donor name, time since donation,
  optional dedication message, and a heart icon.

## What I changed from the original design, and why

- **Collapsed the reference's multi-step donation flow (amount → details → payment) into one
  modal.** Since payment/checkout is explicitly out of scope, a wizard with no final step adds
  complexity without value — one form covering amount, frequency, display preference, name, and
  dedication captures everything this build actually does. The first-step layout (preset amounts
  with labels, frequency toggle, live total) is preserved visually.
- **Tabs are functional only where there is data.** The reference shows six tabs (Project Info,
  Recent donations, Leaderboard, Teams, Non-Profit Info, Updates); this build wires up Project Info
  and Recent donations and renders the rest as greyed-out placeholders — they look right without
  requiring data models that are out of scope.

## Payment Provider Integration (Future Scope)

Currently, the application records donations in a `pending` state and immediately updates the
campaign's progress. In a production environment, progress would only move after successful payment
verification.

To wire in a real payment provider (e.g., Stripe, Tranzila, or CreditGuard):

1. **Checkout initialization** — on form submission, create a `Donation` with `status: pending`,
   call the provider's API to get a Checkout Session or Payment Intent, store the provider's
   reference ID on the donation.
2. **Client handoff** — redirect the user to the provider's hosted checkout page (or an embedded
   secure iframe) so the app never touches raw card data (PCI compliance).
3. **Asynchronous webhooks** — expose a `/webhooks/payments` endpoint; never rely on the browser's
   "success URL" redirect as the source of truth.
4. **Webhook processing** — verify the signature, immediately return `200 OK`, enqueue a background
   job (ActiveJob / Sidekiq), then transition the donation from `pending` → `paid`, increment the
   raised amount with an atomic counter to avoid race conditions, generate a tax receipt, and send
   a confirmation email.
5. **Idempotency** — track processed event IDs to prevent double-counting if the provider retries a
   webhook; transition failed payments to a `failed` state so users can retry.

## What I'd do with more time

- Test coverage — model validations, a request spec for donation creation (happy path + the
  anonymous-no-name case), a system test for tab switching and the donation modal.
- Hebrew/RTL + i18n, to actually match the reference's language and direction.
- Real image/video uploads (Active Storage) and a minimal admin, so campaigns aren't seed-only.
- Recurring-billing automation for `monthly` donations once a payment provider is wired in.
- Donor email receipts.
- An accessibility pass (the modal and tabs use semantic roles/`aria-selected`, but haven't been
  tested with a screen reader).
- A paid Render plan + persistent disk, for donations to survive a restart.

## AI usage

Built with Claude Code (Sonnet 4.6) end-to-end — planning, implementation, and debugging. The full
transcript is in this repo: [`TRANSCRIPT.md`](TRANSCRIPT.md) (readable) and
[`transcript.jsonl`](transcript.jsonl) (raw Claude Code session log).
