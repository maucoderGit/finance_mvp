# Finance MVP — Roadmap

Living backlog of everything pending: unimplemented features, dormant DB fields,
dead UI inputs, and placeholder screens. Compiled from a code audit of `lib/`
(date of scan: 2026-09-13).

Legend:
- 🟡 **Half-built** — exists in UI/schema but is not wired end-to-end
- ⬜ **New** — not implemented anywhere
- ✅ Done — completed, listed for reference

---

## 1. Audit findings — half-built, dormant, or dead

Everything below was found by grepping the model/UI and tracing every column and
`onTap`. Fixing these first closes data-model gaps and removes dead UI.

### 1.1 Dormant DB columns (stored but never produced/consumed)

| Column | Table | State | Evidence |
|--------|-------|-------|----------|
| `contact` | Transactions | 🟡 Never written, never displayed; UI row is a static mock | `app_database.dart:66`; mock row at `transaction_screen.dart:1398-1419` |
| `recurrenceType` | Transactions | 🟡 Never written; chip is hardcoded `'Monthly'` | `app_database.dart:70`; `transaction_screen.dart:1482` |
| `recurrenceEnds` | Transactions | 🟡 Never written; chip is hardcoded `'Until I cancel'` | `app_database.dart:71`; `transaction_screen.dart:1516` |
| `separator` | Currencies | 🟡 Editable in form, never read (formatting uses phone locale) | `app_database.dart:13`; `currency_form.dart:39` |
| `decimalDigits` | Currencies | 🟡 Editable in form, never read (UI hardcodes 2, BTC→3) | `app_database.dart:15`; `accounts_screen.dart:354` |
| `currencySelectionMode` | UserSettings | 🟡 Gates daily auto-sync, but **no editor after onboarding**; sync overwrites it back to `'auto'` | `app_database.dart:101`; `currency_provider.dart:71,162` |

### 1.2 Behavioral gaps on wired fields

| Field | Gap | Evidence |
|-------|-----|----------|
| `isRecurrenceEnabled` | Toggle persists but has **zero runtime effect** (no scheduler), and defaults to **true** on new transactions | `transaction_screen.dart:38,1448-1457` |
| `includeInRevaluation` (Accounts) | Toggle works one-way; repository supports `includeExcluded` but no UI shows excluded accounts | `revaluation_service.dart:33`; no caller passes `includeExcluded: true` |
| Transaction `date` | Always `DateTime.now()`, **no date picker** — cannot backdate/plan future transactions | `transaction_screen.dart` (no `showDatePicker` anywhere) |

### 1.3 Dead inputs / null taps / placeholder screens

| Screen/Element | State | Evidence |
|----------------|-------|----------|
| **Dashboard** — chart | Hardcoded `CustomPaint` path, no data binding; axis labels hardcoded `1 7 14 21 30` | `dashboard_screen.dart:193-201,203-212` |
| Dashboard — Spending/Income toggle + D/W/M/Y filter | Only flips active highlight, ignore both for the chart | `dashboard_screen.dart:243-368` |
| Dashboard — Goal cards | Two hardcoded fake goals ("Emergency Fund", "Vacation to Italy"); no Goal table/store | `dashboard_screen.dart:221-237`; `widgets/goal_projection_card.dart` |
| Dashboard — notifications bell | `onPressed: () {}` | `dashboard_screen.dart:126-129` |
| Transactions — search button | `onPressed: null` (dead) | `transactions_screen.dart:116` |
| Config — "Notifications" settings tile | onTap empty, `// TODO: Navigate to Notification Settings`, no screen exists | `config_screen.dart:127` |

### 1.4 Features that exist only as copy/imagery

| Mentioned | Where | State |
|-----------|-------|-------|
| Budgets | `transaction_screen.dart:1543` ("subscriptions, budgets, or saving goals") | Copy only — no code |
| Goal projections / savings goals | `dashboard_screen.dart` fake cards | Placeholder only |
| "Track your savings across currencies" | `onboarding_screen.dart:229` | Marketing copy only |

---

## 2. Phase 1 — Finish what's half-built (correctness & usability)

Highest priority: every item here is either a dormant data field or a lying UI
element. Checks the "dashboard usable" ask in one pass.

1. ✅ **Transaction contact (relational)** — new `Contacts` table
   (name + optional phone) + `transactions.contact_id` FK (the old free-text
   `contact` column is dropped in the v8 migration). The form's contact field
   opens a full-screen **Contact Picker** (search, list with initials avatars,
   on-the-fly registration); picked contact shows in the row with a one-tap
   clear. A **Contacts** manager screen under Settings lists all contacts with
   add/edit/delete (delete unlinks live transactions). Enables future
   per-contact analysis. Tests cover create, prefill, pick-and-keep, clear,
   and the manager CRUD. ~`roadmap phase 1 #1`~
2. **Recurring transactions — commit or cut.** Either ship a scheduler
   (due-date generation via `recurrenceType`/`recurrenceEnds` + notification) or
   hide the whole recurrence card. At minimum flip the default
   `_isRecurrenceEnabled = true` → false so users stop appending phantom
   recurring flags to every transaction.
3. **Dashboard → real data.** Bind the chart to `net_worth_history`
   (`NetWorthLineChart` already exists for RevaluationScreen — reuse it), wire
   the Spending/Income + D/W/M/Y filters to `watchMonthlySummary`, and delete or
   implement the goal cards. (Requested.)
4. **Transactions search** — wire the dead search button
   (`transactions_screen.dart:116`) to a query stream over `reference`/
   `contact`/category.
5. **Notifications settings tile** — implement a notifications screen (needed by
   recurring txs) or remove the dead tile and its `// TODO` (`config_screen.dart:127`).
6. **Transaction date picker** — let users pick the transaction date instead of
   pinning `now`; keeps `getRateAtDate` cost-basis capture honest for backdated
   entries.
7. **Currency formatting** — consume `separator`/`decimalDigits` in
   `formatMoney` (`services/finance/currency_converter.dart`) or remove them
   from `CurrencyForm`; stop hardcoding digits.
8. **Rate auto-sync mode** — add a settings editor for `currencySelectionMode`
   (auto/manual) and stop force-overwriting it to `'auto'`
   (`currency_provider.dart:162`).

## 3. Phase 2 — Core features (requested)

0. ✅ **Debts & Debtors** — new `Debts` table (`direction` = debtor/creditor,
   amount, currency, contact FK, description, date, `isSettled`, timestamps;
   v9 migration). Settings → **Debts & Debtors** shows base-currency totals of
   what others owe me vs what I owe (live `convertAmount`), open + settled
   groups, and add/edit (with contact picker), settle/reopen, delete per row.
   Transactions can be linked as **payments** against a debt (`debtId` FK,
   v10 migration): each linked expense reduces the debt's outstanding amount
   (valued in the debt's currency, converted at today's rate when currencies
   differ); fully paid debts auto-settle and drop out of totals; deleting a
   debt unlinks its payments.
   Deferred: partial payments/installments, per-contact debt summary in
   analytics.
1. **Export CSV / Excel.** (Requested.) CSV first (zero new deps — write to
   `getApplicationDocumentsDirectory`, share via `share_plus`); Excel/XLSX later
   (`excel` package). Exports: transactions (with `reference`, `contact`,
   `category`, both-currency amounts, `fxDelta`), account balances, net-worth
   history. Companion: **backup/restore** — copy the SQLite file out/in
   (schemaVersion-encapsulated, immune to teleporting between base currencies).
2. **Budgeting.** Per-currency monthly budgets per category (`budgets` table:
   category, amount, period); progress = actual spend vs budget in
   base/account currency; overrun highlighting on the transactions list and home.
   (Requested.)
3. **More customizable profile.** (Requested.) Editable username (`profile_screen.dart:51`
   currently display-only), plus: bio, currency display preferences, default
   account, per-profile formatting. Start with username + a settings entry;
   expand later.
4. **Goals & savings targets.** New `goals` table (name, target currency, target
   amount, deadline, icon/color) + real cards in place of the dashboard fakes.
   Could reuse the account/exchange plumbing already built.
5. **Contact tags & avatars.** Add a `tag` column (+ optional photo path) to
   `Contacts`, surface the Client/VIP/Vendor filter chips and avatar/photo tiles
   from the reference design (`contact_widgets.dart`, `contact_picker_screen.dart`,
   `contacts_screen.dart`), and support tag management in the contact form.
   Skipped during the initial contact work — no classification existed yet.

## 4. Phase 3 — Recurring, analytics, data safety

1. **Recurring transaction engine** (follow-on from Phase 1 #2): generate due
   instances on open, mark "paid/skipped", notifications.
2. **Realized gains/losses** — the formula exists only in a comment
   (`PLAN.md:51`); add realized P&L per sale/transfer alongside the unrealized
   dashboard.
3. **Per-account revaluation breakdown** — drill into the unrealized total per
   account and per holding, with the FX deltas that produced it.
4. **Market-rates gap card** — surface the official-vs-parallel VES spread
   (already fully computed in `fx_delta`/`market_rates`) as a first-class
   dashboard widget instead of it being implicit.
5. **Backup automation** — scheduled local backups; export/import JSON messages.

---

## Cross-cutting notes

- Web target unsupported (drift sqlite3 requires native targets) —
  `PLAN.md:299`.
- "Realized" P&L has never existed; the unrealized engine ignores the
  parallel-rate table — keep those two rate worlds distinct when building new
  cards (`PLAN.md` section context).
- Big-fix ledger from earlier sessions: migration guards + schema self-heal
  (unrecoverable DBs are rebuilt from current schema), base-currency
  `baseCurrencyAmount` guard. All green: 45 tests.