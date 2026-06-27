# Screenshots

The README embeds three images from this folder:

- `watchlist.png` — the watchlist with live prices
- `detail.png` — a coin detail screen with the 7-day chart
- `portfolio.png` — the portfolio with live P&L

To (re)generate them: run the app in demo mode and capture each screen at a
mobile size (~375×812):

```bash
flutter run -d chrome --dart-define=TICKR_DEMO=true
```

Then save the captures here with the filenames above.
