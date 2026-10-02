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
| ~~`contact`~~ | Transactions | ✅ Superseded by the `Contacts` table + FK (Phase 1 #1) | — |
| ~~`recurrenceType`~~ | Transactions | ✅ Written by the recurrence form, read by `Recurrence.occurrence` | `finance_repository.dart:_ruleOf` |
| ~~`recurrenceEnds`~~ | Transactions | ✅ Written by the recurrence form, drives the series end condition | `services/finance/recurrence.dart` |
| `separator` | Currencies | 🟡 Editable in form, never read (formatting uses phone locale) | `app_database.dart:13`; `currency_form.dart:39` |
| `decimalDigits` | Currencies | 🟡 Now consumed as arithmetic precision at every conversion boundary (`getDecimalDigits`), but still not honoured for *display* — `formatMoney` keeps locale separators and its own digit count | `app_database.dart:15`; `currency_converter.dart:29` |
| `currencySelectionMode` | UserSettings | 🟡 Gates daily auto-sync, but **no editor after onboarding**; sync overwrites it back to `'auto'` | `app_database.dart:101`; `currency_provider.dart:71,162` |

### 1.2 Behavioral gaps on wired fields

| Field | Gap | Evidence |
|-------|-----|----------|
| `isRecurrenceEnabled` | ✅ Shipped: defaults to **false**, and a template now materialises its own due occurrences on app open (`materializeDueRecurrences`, capped at 12/series/run) | `finance_repository.dart:685`; `home_screen.dart:74` |
| `includeInRevaluation` (Accounts) | 🟡 Toggle works one-way; repository supports `includeExcluded` but no UI shows excluded accounts | `revaluation_service.dart:33`; no caller passes `includeExcluded: true` |
| Transaction `date` | 🟡 Pickable **only while recurrence is on** — the sole date picker (`_pickFirstDue`) lives inside the recurrence block, so an ordinary transaction is still pinned to `DateTime.now()` | `transaction_screen.dart:53,1945` |

### 1.3 Dead inputs / null taps / placeholder screens

| Screen/Element | State | Evidence |
|----------------|-------|----------|
| **Dashboard** — chart | ✅ Bound to real data. `CashFlowChart` plots `watchCashFlow` (base-currency income or spending, one point per day/week/month/year); the hardcoded `CustomPaint` path and hardcoded axis labels are gone | `widgets/cash_flow_chart.dart`; `finance_repository.dart:watchCashFlow` |
| Dashboard — Spending/Income toggle + D/W/M/Y filter | ✅ Both live: they change the plotted leg and the bucket granularity respectively | `dashboard_screen.dart:_selectBucket` |
| Dashboard — Goal cards | ✅ Deleted. There is no `goals` table, so the two hardcoded cards were pure fiction; `goal_projection_card.dart` is gone. A real Goals feature is Phase 2 #4 | — |
| Dashboard — notifications bell | ✅ Removed. It had `onPressed: () {}` and no screen behind it | — |
| ~~Transactions — search button~~ | ✅ Search is live and matches reference, contact, category, currency and amount | `transactions_screen.dart:154` |
| Config — "Notifications" settings tile | 🟡 onTap empty, `// TODO: Navigate to Notification Settings`, no screen exists | `config_screen.dart:151` |

### 1.4 Features that exist only as copy/imagery

| Mentioned | Where | State |
|-----------|-------|-------|
| Budgets | `transaction_screen.dart:1543` ("subscriptions, budgets, or saving goals") | Copy only — no code |
| ~~Goal projections / savings goals~~ | was `dashboard_screen.dart` fake cards | ✅ Fakes deleted; real feature is Phase 2 #4 |
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
2. ✅ **Recurring transactions.** Scheduler shipped: `recurrenceType`/`recurrenceEnds`
   are now written by the form, `_date` doubles as the series anchor, and
   `materializeDueRecurrences` adds due occurrences on app open (idempotent,
   capped at 12/series/run so a year-old daily series doesn't dump 365 rows).
   Default is **false**. Generated occurrences re-derive FX at their own date
   and carry no debt link.
3. ✅ **Dashboard → real data.** Chart bound to `watchCashFlow`; Spending/Income
   and D/W/M/Y both live; the fake goal cards, the hardcoded `CustomPaint` and
   the dead notification bell are deleted.
4. ✅ **Transactions search** — query stream over
   `reference`/`contact`/category/`currency`/`amount`.
5. **Notifications settings tile** — implement a notifications screen (needed by
   recurring txs) or remove the dead tile and its `// TODO` (`config_screen.dart:151`).
6. **Transaction date picker** — the date is pickable *only* inside the
   recurrence block (`_pickFirstDue`); hoist it to a plain "Date" row so
   ordinary transactions can be backdated too. Keeps `getRateAtDate`
   cost-basis capture honest for backdated entries.
7. **Currency formatting** — `decimalDigits` is honored as arithmetic precision,
   but `formatMoney` still ignores both it and `separator`, and
   `toStringAsFixed(2)` is hardcoded in ~9 places including the amount input.
   Either feed both columns into `formatMoney` or delete them from
   `CurrencyForm`.
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
   debt unlinks its payments. Settling moved out of the UI into
   `_syncDebtSettlement`, which runs on every payment create/update/delete, so
   `isSettled` is correct the moment a payment is recorded and reopens when one
   is removed; debt remaining is quantized to the debt currency's minor unit so
   float residue can't keep a paid debt open.
   ~~Deferred: partial payments/installments~~ — now built (`DebtInstallments`
   + quota split on the payment form). Still deferred: per-contact debt summary
   in analytics.
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

1. **Recurring transaction engine** — generation on app open is done. Remaining:
   mark an occurrence paid/skipped (currently occurrences land in the ledger as
   ordinary transactions with no state), and notifications.
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
  `baseCurrencyAmount` guard. All green: **102 tests**, `flutter analyze` clean.
- Two charts now carry near-identical fl_chart scaffolding
  (`widgets/net_worth_line_chart.dart`, `widgets/purchasing_power_chart.dart`,
  `widgets/cash_flow_chart.dart`) — worth folding into one shared chart widget
  once a fourth arrives.