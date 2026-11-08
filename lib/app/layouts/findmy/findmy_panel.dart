import 'package:flutter/widgets.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';

/// Fraction of the drawer's travel where it rests halfway open.
const double findMyPanelSnapPoint = 0.5;

/// Height of the collapsed drawer: its drag handle and nothing else.
const double findMyPanelMinHeight = 50;

/// The round back and refresh buttons floating over the map: Material's
/// minimum touch target.
const double findMyMapButtonSize = 48;

/// Gap between the top of the map's safe area and those buttons.
const double findMyMapButtonInset = 10;

/// Clear space kept around framed locations so no pin sits on an edge; a
/// pin is about 35 px tall.
const double findMyCameraMargin = 40;

/// How long the camera waits for related updates (the tab, both lists and
/// the first fix often land within a few frames) before framing them once.
const Duration findMyCameraSettle = Duration(milliseconds: 100);

/// The part of the map the opening camera frames on a phone: below the
/// floating buttons and above the drawer at its halfway point, so the framing
/// stays put however the drawer is dragged. [topInset] is the status bar,
/// [hiddenBelowPanel] the part of the map under the bottom navigation bar.
EdgeInsets findMyCameraPadding({
  required double topInset,
  required double hiddenBelowPanel,
  required double maxPanelHeight,
}) => EdgeInsets.fromLTRB(
  findMyCameraMargin,
  topInset + findMyMapButtonInset + findMyMapButtonSize + findMyCameraMargin,
  findMyCameraMargin,
  hiddenBelowPanel +
      findMyPanelMinHeight +
      findMyPanelSnapPoint * (maxPanelHeight - findMyPanelMinHeight) +
      findMyCameraMargin,
);

/// Scroll controller for the Find My drawer itself. The drawer never scrolls its
/// own content (each tab has its own controller), yet sliding_up_panel2 reads
/// this offset whenever the drag handle is touched, which throws without a
/// client and skips the start of the drag's velocity tracking.
class FindMyPanelScrollController extends ScrollController {
  @override
  double get offset => hasClients ? super.offset : 0.0;
}

/// Find My opens with the drawer halfway, as Apple's does. sliding_up_panel2 can
/// only start fully open or closed, so move it once the panel has attached.
void openFindMyPanelAtSnapPoint(PanelController panelController) {
  if (panelController.isAttached) panelController.panelPosition = findMyPanelSnapPoint;
}
