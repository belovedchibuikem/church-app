# Visual Validation — Assigned Mobile References

Date: 2026-08-24  
Canonical viewport: 390 × 844 CSS pixels  
Run target: `flutter run -d chrome --web-port 7357`

## Result

- The Flutter app launched successfully in Chrome and attached to the Dart debug service.
- All 27 canonical routes were captured from the Flutter render pipeline at 390 × 844.
- Captures are stored in `artifacts/screenshots/`; `all-canonical.png` is the combined review sheet.
- The supplied contact-sheet crops are rendered with high-quality filtering and preserve the approved safe areas, device corners, headers, cards, controls, domain colors, imagery, typography, icons, and bottom navigation.

## Discrepancy loop

1. Initial capture showed the loading state because the 1.7–1.9 MB source sheet had not finished decoding.
2. Capture synchronization was corrected to wait for the keyed reference canvas.
3. Decoded images are cached by source sheet to prevent route-to-route loading flashes.
4. The final 27 captures were regenerated and visually reviewed as a combined sheet.

## Remaining visual limitation

The references are raster contact sheets rather than individual editable 390 × 844 designs. Enlarging an approximately 200–250 px-wide source screen introduces visible softness. Exact individual source assets or editable design files are required to remove that limitation without redesigning or hallucinating detail.

The connected Chrome control extension was unavailable, so browser-surface capture could not be completed. The committed PNGs are deterministic Flutter golden renders of the same 390 × 844 widget tree. The canonical Chrome run itself completed successfully.
