class FadeArguments {
  final int increase;
  final int delay;

  FadeArguments(this.increase, this.delay);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FadeArguments &&
        other.increase == increase &&
        other.delay == delay;
  }

  @override
  int get hashCode => Object.hash(increase, delay);
}