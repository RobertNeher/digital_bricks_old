import 'package:flutter/material.dart';

class SegmentDisplayPainter extends CustomPainter {
  final int mask; // 16-bit mask
  final Color color;
  final double strokeWidth;

  SegmentDisplayPainter({
    required this.mask,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double gap = strokeWidth / 2;

    // Basic coordinates
    // Verticals: Left (0), Middle (w/2), Right (w)
    // Horizontals: Top (0), Middle (h/2), Bottom (h)

    // We need points for all 16 segments.
    // A1, A2, B, C, D1, D2, E, F (Outer)
    // G1, G2 (Middle Horiz)
    // H, I, J, K, L, M (Inner)

    final paintOn = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final paintOff = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    void drawSeg(int bit, Path path) {
      bool isOn = (mask & (1 << bit)) != 0;
      canvas.drawPath(path, isOn ? paintOn : paintOff);
    }

    // Paths definition

    // Top Horizontal (A1, A2)
    Path pA1 = Path()
      ..moveTo(gap, 0)
      ..lineTo(w / 2 - gap, 0);
    Path pA2 = Path()
      ..moveTo(w / 2 + gap, 0)
      ..lineTo(w - gap, 0);

    // Right Vertical (B, C)
    Path pB = Path()
      ..moveTo(w, gap)
      ..lineTo(w, h / 2 - gap);
    Path pC = Path()
      ..moveTo(w, h / 2 + gap)
      ..lineTo(w, h - gap);

    // Bottom Horizontal (D1, D2) --> D1 is Right, D2 is Left
    Path pD1 = Path()
      ..moveTo(w / 2 + gap, h)
      ..lineTo(w - gap, h);
    Path pD2 = Path()
      ..moveTo(gap, h)
      ..lineTo(w / 2 - gap, h);

    // Left Vertical (E, F) --> E is Bottom, F is Top
    Path pE = Path()
      ..moveTo(0, h / 2 + gap)
      ..lineTo(0, h - gap);
    Path pF = Path()
      ..moveTo(0, gap)
      ..lineTo(0, h / 2 - gap);

    // Middle Horizontal (G1, G2) -> G1 Left, G2 Right
    Path pG1 = Path()
      ..moveTo(gap, h / 2)
      ..lineTo(w / 2 - gap, h / 2);
    Path pG2 = Path()
      ..moveTo(w / 2 + gap, h / 2)
      ..lineTo(w - gap, h / 2);

    // Inner Verticals (I, L) -> I Top, L Bottom
    Path pI = Path()
      ..moveTo(w / 2, gap)
      ..lineTo(w / 2, h / 2 - gap);
    Path pL = Path()
      ..moveTo(w / 2, h / 2 + gap)
      ..lineTo(w / 2, h - gap);

    // Diagonals
    // H (Top Left)
    Path pH = Path()
      ..moveTo(gap, gap)
      ..lineTo(w / 2 - gap, h / 2 - gap);
    // J (Top Right)
    Path pJ = Path()
      ..moveTo(w - gap, gap)
      ..lineTo(w / 2 + gap, h / 2 - gap);
    // K (Bottom Right)
    Path pK = Path()
      ..moveTo(w / 2 + gap, h / 2 + gap)
      ..lineTo(w - gap, h - gap);
    // M (Bottom Left)
    Path pM = Path()
      ..moveTo(w / 2 - gap, h / 2 + gap)
      ..lineTo(gap, h - gap);

    // Draw in order of bits defined in SegmentPatterns
    // 0: A1, 1: A2
    drawSeg(0, pA1);
    drawSeg(1, pA2);
    // 2: B, 3: C
    drawSeg(2, pB);
    drawSeg(3, pC);
    // 4: D1, 5: D2
    drawSeg(4, pD1);
    drawSeg(5, pD2);
    // 6: E, 7: F
    drawSeg(6, pE);
    drawSeg(7, pF);

    // 8: G1, 9: G2
    drawSeg(8, pG1);
    drawSeg(9, pG2);

    // 10: H (TL Diag)
    drawSeg(10, pH);
    // 11: I (Top Vert)
    drawSeg(11, pI);
    // 12: J (Top Right Diag)
    drawSeg(12, pJ);

    // 13: K (Bot Right Diag)
    drawSeg(13, pK);
    // 14: L (Bot Vert)
    drawSeg(14, pL);
    // 15: M (Bot Left Diag)
    drawSeg(15, pM);
  }

  @override
  bool shouldRepaint(covariant SegmentDisplayPainter oldDelegate) {
    return oldDelegate.mask != mask || oldDelegate.color != color;
  }
}
