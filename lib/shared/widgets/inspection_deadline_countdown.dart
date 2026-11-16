import 'dart:async';

import 'package:flutter/material.dart';

class InspectionDeadlineCountdown extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;

  const InspectionDeadlineCountdown({
    super.key,
    required this.deadline,
    this.onExpired,
  });

  @override
  State<InspectionDeadlineCountdown> createState() =>
      _InspectionDeadlineCountdownState();
}

class _InspectionDeadlineCountdownState
    extends State<InspectionDeadlineCountdown> {
  Timer? _timer;
  bool _expiredCallbackSent = false;

  Duration get _remaining {
    final difference = widget.deadline.toLocal().difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant InspectionDeadlineCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _expiredCallbackSent = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_remaining == Duration.zero && !_expiredCallbackSent) {
        _expiredCallbackSent = true;
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    if (remaining == Duration.zero) {
      return const Text(
        'Đã hết hạn · đang cập nhật trạng thái đơn',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB91C1C),
        ),
      );
    }
    final days = remaining.inDays;
    final hours = (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final time = days > 0
        ? '$days ngày $hours:$minutes:$seconds'
        : '${remaining.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
    return Text(
      'Còn lại $time',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9A3412),
      ),
    );
  }
}
