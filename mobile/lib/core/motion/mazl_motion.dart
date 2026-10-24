import 'package:flutter/widgets.dart';

/// Every motion value of the app's gestures, in one place, so the card deck,
/// the couple deck, the photo viewer and swipe-to-reply cannot drift apart.
/// Canon: docs/design/MOUVEMENT.md (proposal approved by Renaud on
/// 2026-10-24: corner intent disc, 30 % threshold, match sheet).
/// A test checks that each gesture reads its values from here.
abstract final class MazlMotion {
  /// True when the user asked the system to reduce motion: no rotation, no
  /// spring, no pop; fades of [reducedFade] and returns of [reducedReturn].
  /// On iPhone the setting arrives through `ReduceMotionScope` at the app
  /// root, which folds it into `disableAnimations`.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static const reducedFade = Duration(milliseconds: 150);
  static const reducedReturn = Duration(milliseconds: 120);
  static const reducedReturnCurve = Curves.easeOut;

  /// Snap-back of anything released before its threshold. Damping 0.7: a
  /// slight overshoot, settled in about 350 ms.
  static final spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 320,
    ratio: 0.7,
  );

  /// When a spring is considered settled: closer than this to its target (px)
  /// and slower than this (px per second).
  static const springTolerance = Tolerance(distance: 0.2, velocity: 2);

  /// The little bounce of something that becomes true (intent disc at the
  /// threshold, reaction pill appearing): 1 → [popScale] → 1.
  static const popDuration = Duration(milliseconds: 220);
  static const popScale = 1.15;

  /// A chat reaction pill pops in from this scale (0.5 → [popScale] → 1).
  static const reactionPopFrom = 0.5;

  // --- Card decks (Discover, couple activities) ---------------------------

  /// Rotation at a drag of one card width, pivoting on the grab point: a card
  /// held by its lower half turns the other way.
  static const deckMaxRotationDegrees = 8.0;

  /// Share of the card width that commits a left / right swipe.
  static const deckThreshold = 0.30;

  /// Share of the card height that commits an upward swipe (super like, save).
  static const deckUpThreshold = 0.25;

  /// A fling commits below the threshold only if it is fast, long enough and
  /// clearly horizontal, so a small vertical flick never becomes a like.
  static const deckFlingVelocity = 800.0; // logical px per second
  static const deckFlingMinDistance = 48.0;
  static const deckFlingHorizontalRatio = 1.2; // |dx| > ratio × |dy|

  /// Directions that do nothing (down on Discover) give way at this rate,
  /// then spring back: a hard stop reads as a bug.
  static const deckBlockedResistance = 0.2;

  /// The card below grows from this scale to 1 and rises from this offset to
  /// 0 as the top card travels one card width.
  static const deckBackScale = 0.96;
  static const deckBackOffset = 8.0;

  /// A committed card leaves along its drag and fling direction.
  static const deckExit = Duration(milliseconds: 240);
  static const deckExitCurve = Curves.easeOutCubic;

  /// A card grabbed below this share of its height pivots the other way.
  static const deckGrabLowerHalf = 0.5;

  /// A committed card travels this many card sizes from its resting place
  /// (width for left / right, height for up): always fully off screen.
  static const deckExitDistance = 1.6;

  /// Seconds of the release velocity added to the travel across the exit axis,
  /// so the card keeps the direction of the flick.
  static const deckExitVelocityCarry = 0.18;

  /// Extra turn during the exit, as a share of [deckMaxRotationDegrees].
  static const deckExitExtraRotationShare = 0.8;

  /// Corner intent disc: white, opacity and scale follow progress 0 → 1.
  static const intentDiscSize = 56.0;
  static const intentDiscMinScale = 0.8;

  /// Distance of the disc from the card's top and side edges.
  static const intentDiscInset = 20.0;

  /// The matching action button under the card grows up to this scale.
  static const deckButtonMaxScale = 1.1;

  /// The photo position indicator of a card slides from one photo to the
  /// next instead of jumping (instant under reduced motion).
  static const photoIndicatorSlide = Duration(milliseconds: 200);
  static const photoIndicatorCurve = Curves.easeOutCubic;

  // --- Profile gallery (profile page) ---------------------------------------

  /// A tap on a half of the photo turns the page; reduced motion jumps.
  static const galleryPageTurn = Duration(milliseconds: 250);
  static const galleryPageCurve = Curves.easeOut;

  // --- Everything else that moves on its own ---------------------------------

  /// What an entrance (staggered list, pop-in badge, logo) becomes under
  /// reduced motion: no scale, no slide, no bounce; at most this fade.
  static const reducedEntrance = reducedFade;

  // --- Swipe to reply (chat) ----------------------------------------------

  static const replyThreshold = 64.0;

  /// Past the threshold the row follows at this rate, up to [replyMaxOffset].
  static const replyResistance = 0.35;
  static const replyMaxOffset = 110.0;

  // --- Photo viewer: drag to close ----------------------------------------

  static const viewerDismissDistance = 120.0;
  static const viewerDismissVelocity = 600.0; // logical px per second

  /// Over [viewerProgressDistance] of drag, the photo shrinks to
  /// [viewerMinScale] and the background loses [viewerMaxFade] of its opacity.
  static const viewerProgressDistance = 300.0;
  static const viewerMinScale = 0.85;
  static const viewerMaxFade = 0.7;
  static const viewerReturnToThumbnail = Duration(milliseconds: 260);

  /// Fade-in of the viewer page when a thumbnail is opened (the photo itself
  /// flies in with the Hero).
  static const viewerOpen = Duration(milliseconds: 200);

  // --- Match sheet ---------------------------------------------------------

  /// The two photos slide toward each other until they touch.
  static const matchMeet = Duration(milliseconds: 420);
  static const matchMeetCurve = Curves.easeOutCubic;

  /// How far each photo starts from its resting place, on its own side.
  static const matchApartOffset = 28.0;

  /// The single accent ring that pulses around the pair once they touch:
  /// it grows to [matchPulseMaxScale] while its opacity goes 1 → 0.
  static const matchPulse = Duration(milliseconds: 600);
  static const matchPulseCurve = Curves.easeOut;
  static const matchPulseMaxScale = 1.3;
}
