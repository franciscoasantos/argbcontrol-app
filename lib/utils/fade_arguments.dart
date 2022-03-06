class FadeArguments{
  final int increase;
  final int delay;

  FadeArguments(this.increase, this.delay);

  @override
  String toString() {
    return increase.toString() + delay.toString();
  }
}