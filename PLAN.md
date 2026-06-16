# Implementation Plan — Jgive Donation Page Clone

Reference: https://www.jgive.com/new/he/ils/donation-targets/159183 (client-rendered SPA — its
markup couldn't be scraped directly, so the structure below is inferred from the assignment brief
plus typical crowdfunding-page conventions; a visual pass against the live page happens in Phase 4).

## Decisions locked in

- **Deploy target:** Render, building directly from the repo's existing `Dockerfile` (no Kamal).
- **Database:** SQLite, no persistent disk. Render's free instance type has an ephemeral
  filesystem (disks require a paid plan — confirmed in Render's docs), so `bin/docker-entrypoint`
  runs `db:prepare` + `db:seed` on every boot. The app is always populated on load; the trade-off
  is that a donation submitted in one session won't survive the free service spinning down and
  restarting — acceptable since cross-session persistence isn't a stated requirement, and
  upgrading to a paid plan + real disk later is a one-line `render.yaml` change if needed.
- **Locale:** English / LTR. Mirrors the reference's sections, tabs, and sticky-form structure —
  not its language or RTL direction. Fastest path within the time-box; called out explicitly so
  it's a documented trade-off, not an oversight.
- **Styling:** `tailwindcss-rails` gem — keeps the app Node-free (uses a standalone Tailwind
  binary), consistent with the existing importmap/Propshaft setup.
- **URLs:** campaigns get a readable slug (`/campaigns/help-build-a-community-center`), via a
  plain `slug` column + `to_param` override — no `friendly_id` gem. Simple enough not to need the
  dependency: one migration column, one `before_validation` callback, one `find_by!` in the
  controller.

## Phase 1 — Project Initialization & Configuration

1. Keep the Rails 8.1 skeleton as-is (Propshaft, importmap, Turbo/Stimulus, SQLite, Solid
   Queue/Cache/Cable already in `Gemfile`).
2. Add `tailwindcss-rails` for styling speed/fidelity.
3. Deliberately skip: Active Storage, ActionText, `friendly_id`, Faker/FactoryBot (rationale in
   Phase 2/4).
4. Remove or note-as-unused `.kamal/` and `config/deploy.yml` — dead weight once deploying via
   Render's native Docker build instead of Kamal.
5. `bundle install`, run `bin/rubocop -A` once for a clean omakase baseline.
6. Commit per phase/sub-step — real history is an explicit deliverable, not a single squash.

## Phase 2 — Database Schema & Setup (Migrations + Seeds)

**`Campaign`**
- `title:string`, `slug:string` (unique index; backfilled from `title.parameterize` in a
  `before_validation on: :create` callback), `summary:string` (one-liner for cards/header),
  `story:text` (rendered with `simple_format`, no ActionText since there's no rich-text upload UI
  to justify it), `cover_image_url:string`, `goal_amount:decimal, precision: 10, scale: 2`.
- `to_param` overridden to return `slug`, so every `campaign_path(@campaign)` link automatically
  uses the readable URL with zero changes elsewhere; controllers look it up with
  `Campaign.find_by!(slug: params[:id])`.
- No `raised_amount` column. `raised_amount` / `progress_percentage` / `donations_count` are
  instance methods derived from the `donations` association — at this scale, deriving from the
  source of truth is simpler than keeping a denormalized counter in sync.

**`Donation`**
- `campaign:references`, `amount:decimal, precision: 10, scale: 2`,
  `frequency:integer` enum (`one_time`/`monthly`, default `one_time`),
  `display_preference:integer` enum (`full_name`/`first_name_only`/`anonymous`, default `full_name`),
  `status:integer` enum (`pending`/`paid`, default `pending`),
  `donor_name:string`, `dedication_message:text` (optional).
- `donor_name` is required unless `display_preference: anonymous` — an anonymous donor doesn't
  have to give a name at all (not just hide it from public display).
- A `Donation.countable` scope (`pending` + `paid`) is what `Campaign#raised_amount` sums. The
  assignment wants progress to move when a *pending* donation is created (no payment flow exists
  to ever produce a `paid` one yet), so pending counts for now. Isolating that policy in one named
  scope makes "only `paid` counts" a one-line change once a real payment provider lands.

**Seeds (`db/seeds.rb`)**
- 2 campaigns, hand-written (not Faker) — deterministic and readable in a diff for ~2 records.
- Cover images bundled under `app/assets/images/seeds/`, referenced by filename via `image_tag` —
  no Active Storage, no external hotlinked URL, fully self-contained for a reliable demo.
- 6–10 donations across both campaigns, varied `frequency`/`display_preference`/
  `dedication_message` (some blank), mostly `pending`, one or two `paid` to prove the model
  supports it.
- Written idempotently (`find_or_create_by!`) since it now runs on every container boot
  (see Phase 5).

## Phase 3 — Controller Logic & Routing

```ruby
root to: "campaigns#index"
resources :campaigns, only: [:index, :show] do
  resources :donations, only: [:create]
end
```

- `CampaignsController#index` — minimal card grid, not the graded focus.
- `CampaignsController#show` — `Campaign.find_by!(slug: params[:id])`; loads a new unsaved
  `@donation` for the form, and `@campaign.donations.countable.recent` for the Donors tab.
- `DonationsController#create` — builds under `@campaign`; strong params on `:amount, :frequency,
  :display_preference, :donor_name, :dedication_message`.
  - `turbo_stream`: replace the progress bar, prepend to the donor list, swap the form for a
    thank-you state (or re-render the form with errors, `422`, on failure).
  - `html`: redirect to the campaign with a flash notice (standard Turbo fallback).
- Custom-amount handling stays server-naive: "preset vs. custom" merge is client-side JS (Phase 4),
  so the controller only ever sees one `donation[amount]` value.
- If time allows: a model validation test + one request spec for donation creation. If cut, name
  it explicitly in the README rather than dropping it silently.

## Phase 4 — Frontend (Grid, Hotwire Tabs, Sticky Form)

- Layout: light header, `<main>` yield, Tailwind via `tailwindcss-rails`.
- Show page: hero (cover image, title, summary) → stats bar (raised/goal via a reusable
  `_progress_bar` partial shared with index cards, donor count) → responsive grid
  (`grid-cols-1 lg:grid-cols-3`): left 2 cols = tabs, right 1 col = donation form.
- Tabs ("About", "Story", "Donors") — small Stimulus `tabs_controller.js` toggling a `hidden`
  class + `aria-selected` on server-rendered panels. No Turbo Frames needed; content is already in
  the DOM, this is pure client-side show/hide.
- Sticky CTA — plain CSS `position: sticky; top: …` on the right-column wrapper holding the
  progress bar and a "Donate Now" button, no JS for the stickiness itself.
- Donation form lives in a popup, not always inline — the reference site (per direct visual
  inspection of `.../donate/amount`) opens the donation form as a modal rather than showing it
  inline in the sidebar at all times. Implemented with the native `<dialog>` element + a tiny
  `modal_controller.js` (`showModal()`/`close()`, plus closing on backdrop click) instead of a
  hand-rolled JS modal — gets focus trapping and Esc-to-close from the browser for free.
  - Amount: preset radios + a separate "other amount" input. A tiny Stimulus
    `amount_controller.js` makes typing into "other" activate it as the selected radio, so exactly
    one `donation[amount]` is ever submitted.
  - Frequency toggle (one-time/monthly), display-preference radios, donor name (required unless
    `display_preference: anonymous`), optional dedication textarea, submit.
- Checkpoint before closing this phase: eyeball the live reference page against ours for
  spacing/colors/section order. Couldn't scrape the reference's actual markup (client-rendered SPA,
  blocked from simple fetch/curl), so this stayed limited to general crowdfunding-page conventions
  plus direct user feedback (e.g. the popup form). Worth a manual side-by-side glance before
  calling the visual pass fully done.

## Phase 5 — Deployment Strategy & README

**Deployment (Render, free tier, SQLite, no disk)**

1. `render.yaml` (added) — `runtime: docker`, `plan: free`, `dockerfilePath: ./Dockerfile`,
   `healthCheckPath: /up`, `RAILS_MASTER_KEY` as a dashboard secret (`sync: false`).
2. `bin/docker-entrypoint` (updated) — runs `db:prepare` then `db:seed` on every server boot, so
   the ephemeral free-tier filesystem never comes up blank.
3. Push to a public GitHub repo, connect Render via Blueprint (`render.yaml`), paste
   `config/master.key`'s contents into the `RAILS_MASTER_KEY` dashboard field, deploy.
4. Smoke-test the live URL: index → show → tab switching → submit a donation → progress bar and
   donor list update in place.

**README outline**
- Live URL + repo link.
- Run locally: `bin/setup`, `bin/rails db:seed`, `bin/dev`.
- Key decisions & trade-offs: derived `raised_amount` vs. counter cache; pending donations
  counting toward progress (`Donation.countable` scope as the seam for later); manual slug instead
  of `friendly_id`; no Active Storage/admin (bundled seed images, no upload UI in scope); Tailwind
  for Node-free speed; free Render tier + reseed-on-boot instead of a paid disk; English/LTR for
  time-budget reasons.
- **Wiring a real payment provider:** Donation created `pending` → redirect to a provider-hosted
  checkout (Stripe Checkout, or an Israeli processor like Tranzila/PayMe — jgive itself loads
  `cdn.payme.io`) with the donation id in metadata → webhook verifies signature, flips status to
  `paid`, stores the provider's transaction id under a unique index for idempotency →
  failure/cancel webhook handled separately → redirect user back to a thank-you state. Only `paid`
  would count toward `Donation.countable` at that point.
- What I'd do with more time: test coverage, Hebrew/RTL + i18n, real image uploads + a minimal
  admin, recurring-billing automation, donor receipts, accessibility pass, a paid Render plan +
  persistent disk for real cross-session durability.
- AI usage note + pointer to the transcript file(s).
