# Product: Shlyakh (Шлях)

## Vision

A walking tracker that feels like a polished, hand-crafted App Store app
rather than a fitness dashboard. Walking is rewarded with XP and named
levels, and progress is shown as a calm illustrated landscape where each
person is a dot on the path.

## Users

Any number of people. Everyone walks on their own path, and anyone can
create a "Спільно" (Together): a private shared journey where they invite
people close to them (a spouse, a relative, friends). Members of a Спільно
see each other on the landscape. The first users are the developer and his
wife, then family; no public release is planned yet, but nothing in the
data model, auth or row-level security may assume a fixed number of users
or of members per Спільно.

Registration must ask for the user's gender (male or female). It is stored
as a grammatical gender and used only to pick the form of Ukrainian level
titles ("Мандрівник" / "Мандрівниця").

## Goals

- Steps are imported from HealthKit automatically, with no manual entry and
  no Shortcuts-style automations.
- Apple Watch steps are counted correctly (no double counting with iPhone).
- XP is earned from steps and raises levels; every level has a name.
- Main screen follows the "postcard" concept: illustrated landscape,
  progress ring, bottom sheet with details.
- Members of a Спільно see where the others are on the landscape, ideally in
  real time.
- The sky follows the real time of day continuously (dawn, day, golden
  hour, blue hour, night), not just day and night.
- Smooth, deliberate animations; typography in a modern SaaS style.
- Full Ukrainian and English localization.
- Also serves as a learning project for mobile development from scratch.

## Non-goals (for now)

- Android version
- Manual step entry or editing
- Public social features: feeds, global leaderboards, finding strangers.
  Спільно is only private groups by invitation
- A virtual geographic route (e.g. Kyiv to another city). Dropped in favor
  of an abstract landscape
- Workouts, calories, heart rate or other health metrics beyond steps
- Monetization, subscriptions, ads
- Standalone watchOS app (possible later as a separate SwiftUI project)

## Design principles

- Should not look like a template or AI-generated UI: no generic dashboard
  cards, no default gradients, no stock icon grids.
- Illustration first: the landscape is the hero of the main screen.
- RPG flavour is welcome in names and rewards (titles, chapters, level-up
  moments), but the mechanics stay fair: no penalties, no streaks, no XP
  ever lost.
- Fonts must have high-quality Cyrillic support.

## XP and levels

- Each local day is scored on its own: 1 XP per step up to 10 000 steps,
  1 XP per 2 steps beyond that, at most 20 000 XP a day (a long hike is
  rewarded but cannot race through the later path; sensor glitches cannot
  break the pace). Early on one big day can bring several levels at once
  (a capped first day reaches level 4), so level-ups must handle more than
  one level at a time.
- The main path has 25 levels and ends at 1 000 000 XP, "a million steps".
  At a typical pace it takes about a year: the first levels arrive within
  days, the last ones about once a month (about every six weeks at a
  slower 1 800 steps a day).
- After the main path the journey continues ("a new trail"): every further
  level takes the same 81 600 XP. A separate landscape for it is not
  planned yet.
- No penalties, no streaks, no XP ever lost; a day without steps simply
  earns nothing. Everyone follows the same rules.
- Exact rules and tables: `docs/superpowers/specs/2026-09-27-xp-rules-design.md`;
  code: `lib/features/progress/domain/`.

## Level titles

Every level has a title; the 25 main-path titles form 5 chapters of 5,
from the home village to the stars. After level 25 the last title gains a
Roman degree: Зоряний мандрівник II, III, … / Star Wanderer II, III, ….
Ukrainian titles have masculine and feminine forms, chosen by the user's
grammatical gender.

| Level | Українська (ч.) | Українська (ж.) | English |
|---|---|---|---|
| **1. Рідний край / Home Land** | | | |
| 1 | Новачок | Новачка | Newcomer |
| 2 | Перехожий | Перехожа | Passer-by |
| 3 | Мандрівник | Мандрівниця | Wanderer |
| 4 | Шукач стежок | Шукачка стежок | Pathfinder |
| 5 | Знавець околиць | Знавчиня околиць | Local Guide |
| **2. Битий шлях / The Beaten Road** | | | |
| 6 | Подорожній | Подорожня | Traveller |
| 7 | Прочанин | Прочанка | Pilgrim |
| 8 | Прудконогий | Прудконога | Swift-foot |
| 9 | Посланець | Посланниця | Messenger |
| 10 | Вартовий шляху | Вартова шляху | Road Warden |
| **3. Чумацький тракт / The Salt Road** | | | |
| 11 | Погонич | Погоничка | Drover |
| 12 | Чумак | Чумачка | Salt Trader |
| 13 | Бувалий чумак | Бувала чумачка | Seasoned Trader |
| 14 | Знавець степу | Знавчиня степу | Steppe-wise |
| 15 | Отаман валки | Отаманка валки | Caravan Chief |
| **4. Гори й перевали / Peaks and Passes** | | | |
| 16 | Верховинець | Верховинка | Highlander |
| 17 | Пастух полонин | Пастушка полонин | Meadow Shepherd |
| 18 | Легінь | Легінка | Highland Daredevil |
| 19 | Підкорювач перевалів | Підкорювачка перевалів | Pass Conqueror |
| 20 | Володар вершин | Володарка вершин | Lord of the Peaks |
| **5. Чумацький Шлях / The Milky Way** | | | |
| 21 | Зорезнавець | Зорезнавчиня | Stargazer |
| 22 | Нічний мандрівник | Нічна мандрівниця | Night Wanderer |
| 23 | Провідник за зорями | Провідниця за зорями | Star Guide |
| 24 | Хранитель шляху | Хранителька шляху | Keeper of the Way |
| 25 | Зоряний мандрівник | Зоряна мандрівниця | Star Wanderer |

Source of truth for the strings: `lib/l10n/app_*.arb`; the table is pinned
by `test/features/progress/presentation/providers/level_title_test.dart`.

## Main screen content

Decided 2026-09-27 (design stage A):

- **No XP bonuses.** XP is only `dailyXp(steps)`; no "together" or
  "30-minute walk" bonuses: they would need intra-day data, location and
  more rules to understand.
- **No daily goal.** The progress ring shows progress to the next level
  (`levelProgress`); today's steps are the big number next to it.
- **Neutral week:** 7 bars with each day's steps (today highlighted) and
  the week's total. No check marks, no "active days", no weekly goal.
- **The dot is the position on the whole path:** 0 XP at the start of
  «Рідний край», 1 000 000 XP at «Чумацький Шлях». The landscape shows the
  viewer's current chapter; Спільно members in another chapter appear at
  the edge with a hint ("ahead · Битий шлях").
- The bottom sheet discloses progressively: collapsed shows the title,
  level and a thin progress bar; expanded shows today, the week and
  history.

## Open questions

- Home screen widget: in scope for v1 or later?
