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

  // --- Pull to refresh: the Star of David « Le trait » ----------------------
  // Proposal approved by Renaud on 2026-10-27:
  // docs/design/pull-refresh-proposition.html, variant A.

  /// Pull that arms a refresh; a selection tick when the finger crosses it.
  static const refreshThreshold = 64.0;

  /// Gap the list keeps above it while the refresh runs.
  static const refreshHold = 60.0;

  /// The gap where the star fades in, from 0 to fully opaque.
  static const refreshFadeInGap = 26.0;

  /// One loading turn: the star turns a third (back to upright) and each
  /// comet runs once around its triangle. Loading always ends on a whole
  /// turn, and lasts at least [refreshMinCycles] of them.
  static const refreshCycle = Duration(milliseconds: 800);
  static const refreshMinCycles = 1;

  /// The drawn triangles shrink into comets over the start of the loading.
  static const refreshCometShrink = Duration(milliseconds: 300);

  /// Length of each comet, as a share of its triangle.
  static const refreshCometShare = 0.55;

  /// The bloom once the refresh is done: the comets close, the star swells to
  /// [refreshBloomScale] and fills with the accent, then the list goes back.
  static const refreshBloom = Duration(milliseconds: 600);
  static const refreshBloomScale = 1.4;

  /// During Hanukkah a hanukkiah stands in for the star: its flames flicker
  /// by up to this share of their size while the refresh runs.
  static const refreshFlameFlicker = 0.15;

  // --- Typing thread (chat) --------------------------------------------------

  /// One loop of the « … écrit » thread: it ripples, ties a knot at the
  /// centre, then undoes it, and starts over seamlessly.
  static const typingThreadCycle = Duration(milliseconds: 1800);

  /// Where in the cycle (0 → 1) the knot is fully tied: the still frame shown
  /// under reduced motion.
  static const typingThreadKnotFormed = 0.5;

  // --- Loading thread (skeletons) -------------------------------------------
  // The skeleton blocks stay flat and calm; one accent thread runs over them.

  /// One pass of the thread across the skeleton, in reading direction.
  static const loadingThreadPeriod = Duration(milliseconds: 2400);
  static const loadingThreadCurve = Curves.easeInOutSine;

  /// Width of the thread, in logical pixels.
  static const loadingThreadWidth = 2.0;

  /// Share of the height at each end of the thread where it fades out.
  static const loadingThreadEndFade = 0.2;

  /// Share of the pass, at each edge, where the whole thread fades in or out
  /// so it never appears or vanishes abruptly.
  static const loadingThreadEdgeFade = 0.12;

  // --- Like fill (heart buttons) -------------------------------------------

  /// While the finger rests on a heart button, a disc grows from the exact
  /// touch point toward [likeFillPreview] of the button over this time.
  static const likeFillDuration = Duration(milliseconds: 360);
  static const likeFillCurve = Curves.easeOut;

  /// How far the disc gets before the tap is confirmed (0 = nothing, 1 =
  /// the whole button): the lift of the finger takes it the rest of the way.
  static const likeFillPreview = 0.65;

  /// Time a confirmed tap needs to bring the disc from nothing to the whole
  /// button; less when the disc is already part way (the common bounce
  /// follows, see [popDuration] and [popScale]).
  static const likeFillFinish = Duration(milliseconds: 140);

  /// A cancelled tap (the finger slid out) empties the disc this fast, from
  /// full; less when it is part way.
  static const likeFillCancel = Duration(milliseconds: 160);

  /// Once the bounce is over, the full button goes back to rest in this time,
  /// so a button that outlives its card never stays filled.
  static const likeFillRelease = Duration(milliseconds: 200);

  // --- Rolling count (likes) -----------------------------------------------

  /// A digit that changes rolls vertically to its new value, like a
  /// mechanical counter (up when the number grows, down when it shrinks).
  /// Under reduced motion the new number simply appears.
  static const rollingCount = Duration(milliseconds: 420);
  static const rollingCountCurve = Curves.easeOutCubic;

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

  // --- Event page: the photo of a card becomes the header of its page -----

  /// The page of an event fades in while its photo flies from the card to the
  /// header; going back is the same flight in reverse, a little faster.
  static const eventOpen = Duration(milliseconds: 460);
  static const eventClose = Duration(milliseconds: 340);
  static const eventOpenCurve = Curves.easeInOutCubicEmphasized;

  /// The page itself is opaque after this share of the transition.
  static const eventPageFadeEnd = 0.35;

  /// The texts of the page enter one group after the other: the first starts
  /// at [eventTextStart] of the transition, each next one [eventTextStagger]
  /// later, each rising by [eventTextRise] while it fades in.
  static const eventTextStart = 0.40;
  static const eventTextStagger = 0.08;
  static const eventTextSpan = 0.40;
  static const eventTextRise = 14.0;

  /// Corner radius of a card of the events list, where the flight starts.
  static const eventCardRadius = 16.0;

  /// A photo fades in over its placeholder.
  static const eventPhotoFade = Duration(milliseconds: 280);

  /// Pulse of the placeholder of a photo that is still loading.
  static const eventPlaceholderPeriod = Duration(milliseconds: 1600);
}
