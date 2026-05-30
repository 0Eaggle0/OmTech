import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;

  const TiltCard({super.key, required this.child, this.maxTilt = 0.04});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rxAnim;
  late Animation<double> _ryAnim;

  double _rx = 0;
  double _ry = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _rxAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _ryAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    if (size.width == 0 || size.height == 0) return;
    setState(() {
      _rx = (d.localPosition.dy / size.height - 0.5) * -widget.maxTilt * 2;
      _ry = (d.localPosition.dx / size.width - 0.5) * widget.maxTilt * 2;
    });
  }

  void _onPanEnd() {
    _rxAnim = Tween<double>(begin: _rx, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _ryAnim = Tween<double>(begin: _ry, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward(from: 0);
    _controller.addListener(() => setState(() {
          _rx = _rxAnim.value;
          _ry = _ryAnim.value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _onPanEnd(),
      onPanCancel: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rx)
          ..rotateY(_ry),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
