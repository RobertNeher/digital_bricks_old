class SegmentPatterns {
  // Segment Bit Definitions
  // Adapting standard 16-seg layout
  //     A1  A2
  //   F \  |  / B
  //   H  \ I / J
  //      G1  G2
  //   M  / L \ K
  //   E /  |  \ C
  //     D2  D1

  static const int A1 = 1 << 0; // Top Left Horiz
  static const int A2 = 1 << 1; // Top Right Horiz
  static const int B = 1 << 2; // Right Top Vert
  static const int C = 1 << 3; // Right Bottom Vert
  static const int D1 = 1 << 4; // Bottom Right Horiz
  static const int D2 = 1 << 5; // Bottom Left Horiz
  static const int E = 1 << 6; // Left Bottom Vert
  static const int F = 1 << 7; // Left Top Vert

  static const int G1 = 1 << 8; // Middle Left Horiz
  static const int G2 = 1 << 9; // Middle Right Horiz

  static const int H = 1 << 10; // Top Left Diag (inner)
  static const int I = 1 << 11; // Top Vert (inner)
  static const int J = 1 << 12; // Top Right Diag (inner)

  static const int K = 1 << 13; // Bottom Right Diag (inner)
  static const int L = 1 << 14; // Bottom Vert (inner)
  static const int M = 1 << 15; // Bottom Left Diag (inner)

  static const Map<int, int> _asciiMap = {
    // Numbers
    // Numbers
    0x30: A1 | A2 | B | C | D1 | D2 | E | F | K | M, // 0 (diagonal slash)
    0x31: B | C, // 1
    0x32: A1 | A2 | B | G1 | G2 | E | D1 | D2, // 2
    0x33: A1 | A2 | B | C | D1 | D2 | G2, // 3
    0x34: F | G1 | G2 | B | C, // 4
    0x35: A1 | A2 | F | G1 | G2 | C | D1 | D2, // 5
    0x36: A1 | A2 | F | E | D1 | D2 | C | G1 | G2, // 6
    0x37: A1 | A2 | B | C, // 7
    0x38: A1 | A2 | B | C | D1 | D2 | E | F | G1 | G2, // 8
    0x39: A1 | A2 | B | C | D1 | D2 | F | G1 | G2, // 9
    // Letters
    65: A1 | A2 | B | C | E | F | G1 | G2, // A
    66:
        A1 |
        A2 |
        B |
        C |
        D1 |
        D2 |
        I |
        L |
        G2, // B (Design 2: split middle vert)
    67: A1 | A2 | F | E | D1 | D2, // C
    68: A1 | A2 | B | C | D1 | D2 | I | L, // D
    69: A1 | A2 | F | E | D1 | D2 | G1 | G2, // E
    70: A1 | A2 | F | E | G1 | G2, // F
    71: A1 | A2 | F | E | D1 | D2 | C | G2, // G
    72: F | E | B | C | G1 | G2, // H
    73: A1 | A2 | D1 | D2 | I | L, // I
    74: B | C | D1 | D2 | E, // J
    75: F | E | G1 | J | K, // K
    76: F | E | D1 | D2, // L
    77: F | E | B | C | H | J, // M
    78: F | E | B | C | H | K, // N
    61: G1 | G2 | D1 | D2, // = (Bottom line?) Or maybe G and D? A and G?
    // Let's do G1|G2 for mid, and D1|D2 is too low.
    // Maybe separate?
    35: B | C | F | E | G1 | G2 | I | L, // #
    47: M | J, // /
    92: H | K, // \
    40: J | K, // ( (Right facing paren) -> Actually diagonals H/M?
    // usually ( starts top right goes bottom right?
    // No, ( is left side.
    // Let's use K and J adjusted? No.
    // Let's use distinct diagonal segments.
    41: H | M, // )
    // Quotes
    39: I, // '
    34: I | B, // "
  };

  static int getMask(int ascii) {
    // Determine letter case: map lower to upper
    if (ascii >= 97 && ascii <= 122) {
      ascii -= 32;
    }
    return _asciiMap[ascii] ?? 0;
  }
}

class Segment7Patterns {
  // 7-Segment Bit Definitions
  //      A
  //    F   B
  //      G
  //    E   C
  //      D

  static const int A = 1 << 0;
  static const int B = 1 << 1;
  static const int C = 1 << 2;
  static const int D = 1 << 3;
  static const int E = 1 << 4;
  static const int F = 1 << 5;
  static const int G = 1 << 6;

  static const Map<int, int> _hexMap = {
    0x0: A | B | C | D | E | F,
    0x1: B | C,
    0x2: A | B | G | E | D,
    0x3: A | B | G | C | D,
    0x4: F | G | B | C,
    0x5: A | F | G | C | D,
    0x6: A | F | E | D | C | G,
    0x7: A | B | C,
    0x8: A | B | C | D | E | F | G,
    0x9: A | F | G | B | C | D,
    0xA: A | F | B | G | E | C,
    0xB: F | E | D | C | G,
    0xC: A | F | E | D,
    0xD: B | C | D | E | G,
    0xE: A | F | G | E | D,
    0xF: A | F | G | E,
  };

  static int getHexMask(int value) {
    return _hexMap[value & 0xF] ?? 0;
  }
}
