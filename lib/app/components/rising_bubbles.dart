/// The bubbles of BubbleBeam's loading animation: (x across the box, phase offset, radius as a
/// fraction of the box width, sideways sway as a fraction of the box width).
///
/// Shared by [RisingBubblesPainter] and the Android opening drawable
/// (scripts/opening_drawable.dart), so both draw the same bubbles.
const risingBubbles = [
  (0.10, 0.00, 0.050, 0.04),
  (0.30, 0.55, 0.035, 0.03),
  (0.84, 0.20, 0.060, 0.05),
  (0.68, 0.75, 0.030, 0.03),
  (0.93, 0.45, 0.025, 0.02),
  (0.05, 0.35, 0.028, 0.02),
  (0.50, 0.90, 0.022, 0.02),
];
