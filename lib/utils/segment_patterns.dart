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
    79: A1 | A2 | B | C | D1 | D2 | E | F, // O
    80: A1 | A2 | B | F | E | G1 | G2, // P
    81: A1 | A2 | B | C | D1 | D2 | E | F | K, // Q
    82: A1 | A2 | B | F | E | G1 | G2 | K, // R
    83: A1 | A2 | F | G1 | G2 | C | D1 | D2, // S
    84: A1 | A2 | I | L, // T
    85: F | E | D1 | D2 | C | B, // U
    86: F | E | M | J, // V (Use diagonals)
    87: F | E | B | C | K | M, // W
    88: H | J | K | M, // X
    89: H | J | L, // Y
    90: A1 | A2 | J | M | D1 | D2, // Z
    // Symbols
    33:
        B |
        C, // ! (Simulated with right side approx) -> Actually B|C is 1. Maybe just I|L and dot? No dot.
    // Let's use B|C for !, or just middle vertical I|L? I|L looks like I.
    // Use B|C|0 (off).
    // Let's go with B and C.
    63: A1 | A2 | B | G2 | L, // ?
    36: A1 | A2 | F | G1 | G2 | C | D1 | D2 | I | L, // $ (S with vert line)
    37: F | G1 | J | M | D1, // %
    42: G1 | G2 | I | L | H | J | K | M, // * (All internal)
    43: G1 | G2 | I | L, // +
    45: G1 | G2, // -
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
