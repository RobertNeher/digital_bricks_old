class Wire {
  final String startComponentId;
  final int startPinIndex;
  final String endComponentId;
  final int endPinIndex;
  bool value = false;

  Wire({
    required this.startComponentId,
    required this.startPinIndex,
    required this.endComponentId,
    required this.endPinIndex,
    this.value = false,
  });
}
