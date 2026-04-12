
import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

class PositionIndicator extends MainIndicator<KLineEntity, MAStyle> {
  final Color _positionColor = Colors.green.withValues(alpha: 0.7);

  final List<double> entryPrices;

  PositionIndicator({required this.entryPrices})
    : super(
        name: 'POS',
        shortName: 'POS',
        indicatorStyle: const MAStyle(),
        calcParams: [],
      );

  @override
  void calc(List<KLineEntity> data) {}

  @override
  void drawChart(
    KLineEntity lastData,
    KLineEntity curData,
    double lastX,
    double curX,
    double Function(double) getLineY,
    Canvas canvas,
    KChartColors chartColors,
  ) {
    for (var price in entryPrices) {
      final y = getLineY(price);
      canvas.drawLine(
        Offset(lastX, y),
        Offset(curX, y),
        Paint()
          ..color = Colors.green.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  TextSpan? drawFigure(
      CandleEntity entity, int precision, KChartColors chartColors) {
    List<InlineSpan> result = [];
    for (var price in entryPrices) {
      var item = TextSpan(
        text: "POS:$price ",
        style: TextStyle(
          fontSize: 10,
          color: _positionColor,
        ),
      );
      result.add(item);
    }
    return TextSpan(children: result);
  }

  @override
  (double, double) getMaxMinValue(KLineEntity data, double min, double max) {
    double newMin = min;
    double newMax = max;
    for (var price in entryPrices) {
      if (price < newMin) newMin = price;
      if (price > newMax) newMax = price;
    }
    return (newMin, newMax);
  }
}

class TimePoint {
  final int value; // Time in seconds
  final Color color; // The color of this point in time

  TimePoint({required this.value, required this.color});
}

class TimelineIndicator extends MainIndicator<KLineEntity, MAStyle> {
  final List<TimePoint> timePoints;

  TimelineIndicator({required this.timePoints}): super(
        name: 'POS',
        shortName: 'POS',
        indicatorStyle: const MAStyle(),
        calcParams: [],
      );

  @override
  void calc(List<KLineEntity> dataList) {}

  @override
  void drawChart(KLineEntity lastPoint, KLineEntity curPoint, double lastX, double curX, GetYFunction getY, Canvas canvas, KChartColors chartColors) {
    for (var timePoint in timePoints) {
      final y = getY(curPoint.close);
      if (timePoint.value >= (lastPoint.time ?? 0) && timePoint.value <= (curPoint.time ?? 0)) {
        canvas.drawCircle(
          Offset(curX,y),
          5.0,
          Paint()
            ..color = timePoint.color
            ..strokeWidth = 1.0
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  TextSpan? drawFigure(KLineEntity value, int precision, KChartColors chartColors) {
    return null;
  }

  @override
  (double, double) getMaxMinValue(KLineEntity entity, double minV, double maxV) {
    return (minV, maxV);
  }
}