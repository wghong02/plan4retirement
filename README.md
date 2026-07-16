# Plan4Retirement

An iOS app for planning and projecting retirement savings. Track your accounts, set economic assumptions, and see how your balances grow (and draw down) over time.

Built with SwiftUI and Core Data.

## Features

The app is organized into five tabs.

### Accounts
- Add up to 5 retirement accounts, each with a type (**Pre-Tax** / **Post-Tax**), current balance, annual contribution, and expected ROI.
- **Update Balance** — record a new balance with a date and optional note (notes capped at 150 characters).
- **Balance history** per account:
  - Every account is seeded with an "Initial balance" entry on creation.
  - View, edit, or delete past entries (swipe-to-delete, or delete from the edit screen).
  - The last remaining entry can't be deleted, so an account always keeps a baseline balance.
  - History is ordered newest-first.
- The displayed balance always reflects the **latest-dated** update, and each row shows its last update date.
- Swipe-to-delete an account (with confirmation) also removes its history and saved projections.

### Assumptions
- **Personal information** — current age, retirement age, life expectancy (typed input plus steppers).
- **Economic assumptions** — annual inflation rate, asset growth rate, annual contribution increase, and annual spending in retirement. Rates accept decimals, are bounded (−100% to 10000%), and show inline red warnings when out of range.
- **Life events** — one-off events (house/car purchase, major expense, inheritance, medical expense, other) with a date and amount that affect the projection in the month they occur.
- All assumptions are saved automatically.

### Dashboard
- Total current assets and total annual contributions.
- Average ROI, weighted by each account's current balance.
- Projected balance at retirement.
- Per-account breakdown.

### Projections
- **Current** — a growth/drawdown line chart plus the assumptions driving it.
  - Toggle between **Monthly** and **Yearly** resolution; the x-axis shows calendar years/months.
  - Press-and-hold the chart to inspect a point (balance, age, contribution, growth); a plain drag still scrolls.
  - Save the current projection as a named snapshot.
- **Saved** — review saved snapshots. Each stores the exact computed data points (frozen at save time) plus the assumptions used, and its axis stays anchored to the date it was saved.
- **Breakdown** — histogram of balances by tax treatment.

### Settings
- Max number of saved projections.
- How many points to show on the monthly / yearly charts.
- **Show in Today's Dollars** — display projected amounts inflation-adjusted to present-day purchasing power.
- Reset assumptions to defaults, or delete all data.

## How the projection works

Balances are projected month by month (nominal dollars):
- The series starts at your current total balance.
- Investment growth uses the asset growth rate, compounded monthly.
- While working, contributions are added and grow each year by the contribution-increase rate.
- After retirement age, inflation-adjusted spending is drawn down each year.
- Life events are applied in the month they fall.
- The horizon extends far enough to cover the configured display window.

Yearly and monthly views are derived from the same underlying monthly series.

## Tech stack
- **SwiftUI** for the UI, including custom `Canvas`-drawn line and bar charts.
- **Core Data** persists accounts, balance history, life events, and projection snapshots.
- **UserDefaults** stores assumptions and display settings.

## Requirements & build
- Xcode with an iOS 17+ deployment target (uses `NavigationStack`).
- Open `Plan4Retirement.xcodeproj` and run on a simulator or device.
