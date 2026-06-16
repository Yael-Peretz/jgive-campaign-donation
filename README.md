# Jgive Campaign Donation Page

A Rails reproduction of a Jgive campaign donation page (reference: [jgive.com/.../donation-targets/159183](https://www.jgive.com/new/he/ils/donation-targets/159183)) — campaign details, tabs, and a donation form that creates a `pending` donation and updates the campaign's progress. No payment/checkout, no accounts/admin, per the assignment scope.

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
- **Pending donations count toward progress.** The assignment explicitly wants progress to move
  when a donation is submitted, but there's no payment flow to ever produce a `paid` one. A
  `Donation.countable` scope (currently `pending` + `paid`) is what gets summed, so narrowing it to
  `where(status: :paid)` later is a one-line change, not a hunt through the codebase.
- **Donor name is required unless the donor chooses to stay anonymous.** Anonymity means skipping
  the name entirely, not just hiding an internally-collected one.
- **No Active Storage, no admin.** Campaigns are seed-only (no creation/upload UI is in scope), so
  cover images are plain SVGs checked into `app/assets/images/seeds/` and referenced by filename —
  no blob storage, no external image host to go down mid-demo.
- **Readable campaign URLs via a plain `slug` column + `to_param` override**, not the `friendly_id`
  gem — one column, one callback, one `find_by!` didn't justify the dependency.
- **Tailwind via `tailwindcss-rails`** (standalone binary), not a Node toolchain — keeps the app
  consistent with the existing importmap/Propshaft setup from `rails new`.
- **SQLite on Render's free tier, no persistent disk.** Render's free instances have an ephemeral
  filesystem (disks require a paid plan), so `bin/docker-entrypoint` runs `db:prepare` + `db:seed`
  on every boot — the app is never blank, at the cost of donations not surviving a spin-down/restart.
  Documented in [PLAN.md](PLAN.md); upgrading to a paid plan + a real disk is a one-line
  `render.yaml` change if that trade-off stops being acceptable.
- **English/LTR**, not Hebrew/RTL. The build mirrors the reference's sections, tabs, and donation
  flow structurally, but not its language or text direction — the fastest path within the time-box.
- **Donation form is a popup, not an always-visible inline form.** The reference site opens
  donation as a modal (see `.../donate/amount`); this build uses the native `<dialog>` element +
  a small Stimulus controller rather than a hand-rolled modal, so focus-trapping, Esc-to-close, and
  the backdrop come from the browser for free.

## What I changed from the original design, and why

- **Collapsed the reference's multi-step donation flow (amount → details → payment) into one
  single-step modal.** Since payment/checkout is explicitly out of scope, a wizard with no final
  step to wizard towards added complexity without adding value — one form covering amount,
  frequency, display preference, name, and dedication captures everything this build actually does.
- **Tab structure (About / Story / Donors) is inferred, not copied.** The live reference is a
  client-rendered SPA that returns an empty shell to both `curl` and the WebFetch tool, so its
  actual tab markup/labels were never directly observable. The three tabs here were chosen to
  match the assignment brief's own field list (title, description/story, progress) plus a donor
  list, organized the way most crowdfunding pages structure this content. Worth a manual
  side-by-side glance against the live page if pixel-level fidelity matters more than structural
  fidelity.

## Payment Provider Integration (Future Scope)

Currently, the application records donations in a `pending` state and immediately updates the
campaign's progress. In a production environment, updating the campaign progress would only occur
after successful payment verification.

To wire in a real payment provider (e.g., Stripe, Tranzila, or CreditGuard), I would implement the
following architecture:

1. **Checkout Initialization:** Upon form submission, the backend creates a `Donation` record with
   `status: pending`. It then calls the payment provider's API to generate a secure Checkout
   Session or Payment Intent, storing the provider's reference ID on the donation record.

2. **Client Handoff:** The user is redirected to the provider's hosted checkout page (or an
   embedded secure iframe) to complete the transaction securely, ensuring the app doesn't touch
   raw credit card data (PCI compliance).

3. **Asynchronous Webhooks (The Source of Truth):** State transitions should never rely on the
   user's browser redirecting back to a "Success URL", as the browser might crash or be closed.
   Instead, the system will expose a webhook endpoint (e.g., `/webhooks/payments`).

4. **Webhook Processing & State Transition:**
   * **Verification:** The endpoint will first verify the webhook signature using the provider's
     secret to ensure authenticity.
   * **Async Processing:** To prevent timeouts, the endpoint immediately returns a `200 OK` and
     enqueues a background job (e.g., via Sidekiq / ActiveJob).
   * **State Machine:** The background worker retrieves the `Donation`, and safely transitions its
     state from `pending` to `paid` (ideally using a state machine like the `aasm` gem).
   * **Side Effects:** Only upon transitioning to `paid`, the system will increment the campaign's
     `amount_raised` (using pessimistic locking or database atomic counters like
     `increment_counter` to avoid race conditions during high-traffic campaigns), generate a tax
     receipt, and trigger a confirmation email.

5. **Idempotency & Reliability:** To prevent double-counting donations in case the provider sends
   the same webhook event twice, the processing logic will be idempotent, tracking processed event
   IDs. Failed payments will transition the donation state to `failed`, allowing the user to
   seamlessly retry.

## What I'd do with more time

- Test coverage — model validations, a request spec for donation creation (happy path + the
  anonymous-no-name case), a system test for tab switching and the donation modal.
- Hebrew/RTL + i18n, to actually match the reference's language and direction.
- Real image uploads (Active Storage) and a minimal admin, so campaigns aren't seed-only.
- Recurring-billing automation for `monthly` donations once a payment provider is wired in.
- Donor email receipts.
- An accessibility pass (the modal and tabs use semantic roles/`aria-selected`, but haven't been
  tested with a screen reader).
- A paid Render plan + persistent disk, for donations to survive a restart.

## AI usage

Built with Claude Code (Sonnet 4.6) end-to-end — planning, implementation, and debugging. The full
transcript is included with this submission alongside this README.
