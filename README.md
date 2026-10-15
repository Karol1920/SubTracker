# SubTracker

An iOS app for keeping track of recurring subscriptions and what they actually
cost per month. Built with SwiftUI and SwiftData.

I kept losing track of what I was paying for, and most apps in this space either
want an account or a subscription of their own, which felt like the wrong way to
solve the problem. Everything here stays on the device.

## What it does

Add a subscription with a name, price, next payment date, category and billing
cycle. The list is grouped by category, and the header shows the combined
monthly cost. Weekly and yearly prices are normalised to a monthly figure, so a
49 PLN yearly plan and a 15 PLN monthly one can be compared directly.

Swiping right on an entry marks it as paid and moves the renewal date forward by
one billing period. Swiping left deletes it. Each row shows how many days are
left before the next payment, or flags it as overdue.

The analysis tab draws a donut chart of spending, either grouped by category or
broken down per subscription, plus a ranking by price.

Settings cover the display currency (PLN, EUR, USD, GBP), chart grouping and
list sort order. The app follows the system light and dark appearance, and the
interface is localised.

## Built with

- SwiftUI for the interface
- SwiftData for local persistence
- Swift Charts for the donut charts
- `@AppStorage` for user preferences
- String catalogs (`.xcstrings`) for localisation
- Haptic feedback on payment and deletion

## Running it

Open `SubTracker.xcodeproj` in Xcode and run on a simulator or a device. No
dependencies to install and no configuration needed.

## Known issues and next steps

- Marking a weekly subscription as paid advances the date by one day instead of
  one week. The billing cycle switch uses the wrong calendar component for that
  case.
- The default currency is not consistent between views before the user picks one
  in settings.
- `UserNotifications` is imported but reminders are not implemented yet. Local
  notifications a few days before each renewal date are the next thing I want to
  add.
- The hex colour initialiser only handles six-digit values and falls back to
  black otherwise.
- No tests, and the main view file has grown large enough that the views should
  be split into separate files.
