import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class OHLCVGraph extends StatefulWidget {
  OHLCVGraph(
      {Key key,
      @required this.data,
      this.lineWidth = 1.0,
      this.fallbackHeight = 100.0,
      this.fallbackWidth = 300.0,
      this.gridLineColor = Colors.grey,
      this.gridLineAmount = 5,
      this.gridLineWidth = 0.5,
      this.gridLineLabelColor = Colors.grey,
      this.labelPrefix = "\$",
      @required this.enableGridLines,
      @required this.volumeProp,
      this.increaseColor = Colors.green,
      this.decreaseColor = Colors.red,
      this.fillBoxes = false,
      this.lowHighColor,
      this.volumeBarOpacity = 1.0,
      this.barWidth,
      this.selectionColor = Colors.black,
      this.touchDownCallBack,
      this.touchUpCallBack,
      this.widthProp = 1.0})
      : assert(data != null),
        super(key: key);

  /// OHLCV data to graph  /// List of Maps containing open, high, low, close and volumeto
  /// Example: [["open" : 40.0, "high" : 75.0, "low" : 25.0, "close" : 50.0, "volumeto" : 5000.0}, {...}]
  final List data;

  /// All lines in chart are drawn with this width
  final double lineWidth;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Color of grid lines and label text
  final Color gridLineColor;
  final Color gridLineLabelColor;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Proportion of paint to be given to volume bar graph
  final double volumeProp;

  /// If graph is given unbounded space,
  /// it will default to given fallback height and width
  final double fallbackHeight;
  final double fallbackWidth;

  /// Symbol prefix for grid line labels
  final String labelPrefix;

  /// Increase color
  final Color increaseColor;

  /// Decrease color
  final Color decreaseColor;

  /// Whether to fill or outline candleSticks
  final bool fillBoxes;

  /// Color for low/high spread lines, increaseColor or decreaseColor by default
  final Color lowHighColor;

  /// Opacity for the volume bar
  final double volumeBarOpacity;

  /// Width for bars
  final double barWidth;

  /// Color for selection line
  final Color selectionColor;

  /// The proportion of the width to draw on
  final double widthProp;

  /// Callbacks for touch events
  final Function touchDownCallBack;
  final Function touchUpCallBack;

  @override
  _OHLCVGraphState createState() => _OHLCVGraphState();
}

class _OHLCVGraphState extends State<OHLCVGraph> {
  final GlobalKey _chartKey = GlobalKey();

  Offset touchPosition;
  Function touchCallback;

  Size _getChartSize() {
    final RenderBox containerRenderBox =
        _chartKey.currentContext?.findRenderObject();
    if (containerRenderBox != null && containerRenderBox.hasSize) {
      return containerRenderBox.size;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (d) {
        setState(() {
          touchPosition = d.localPosition;
          touchCallback = widget.touchDownCallBack;
        });
      },
      onLongPressMoveUpdate: (d) {
        setState(() {
          touchPosition = d.localPosition;
          touchCallback = widget.touchDownCallBack;
        });
      },
      onPanDown: (d) {
        setState(() {
          touchPosition = d.localPosition;
          touchCallback = widget.touchDownCallBack;
        });
      },
      onPanUpdate: (d) {
        setState(() {
          touchPosition = d.localPosition;
          touchCallback = widget.touchDownCallBack;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          touchPosition = null;
          touchCallback = widget.touchUpCallBack;
        });
      },
      onPanEnd: (_) {
        setState(() {
          touchPosition = null;
          touchCallback = widget.touchUpCallBack;
        });
      },
      onPanCancel: () {
        setState(() {
          touchPosition = null;
          touchCallback = widget.touchUpCallBack;
        });
      },
      child: new LimitedBox(
        maxHeight: widget.fallbackHeight,
        maxWidth: widget.fallbackWidth,
        child: new CustomPaint(
          size: Size.infinite,
          painter: new _OHLCVPainter(widget.data,
              lineWidth: widget.lineWidth,
              gridLineColor: widget.gridLineColor,
              gridLineAmount: widget.gridLineAmount,
              gridLineWidth: widget.gridLineWidth,
              gridLineLabelColor: widget.gridLineLabelColor,
              // enableGridLines: widget.enableGridLines,
              volumeProp: widget.volumeProp,
              labelPrefix: widget.labelPrefix,
              increaseColor: widget.increaseColor,
              decreaseColor: widget.decreaseColor,
              fillBoxes: widget.fillBoxes,
              lowHighColor: widget.lowHighColor,
              volumeBarOpacity: widget.volumeBarOpacity,
              barWidth: widget.barWidth,
              touchPosition: touchPosition,
              selectionColor: widget.selectionColor,
              touchCallback: touchCallback,
              widthProp: widget.widthProp),
        ),
      ),
    );
  }
}

class _OHLCVPainter extends CustomPainter {
  _OHLCVPainter(this.data,
      {@required this.lineWidth,
      // @required this.enableGridLines,
      @required this.gridLineColor,
      @required this.gridLineAmount,
      @required this.gridLineWidth,
      @required this.gridLineLabelColor,
      @required this.volumeProp,
      @required this.labelPrefix,
      @required this.increaseColor,
      @required this.decreaseColor,
      @required this.fillBoxes,
      @required this.lowHighColor,
      @required this.volumeBarOpacity,
      @required this.barWidth,
      @required this.touchPosition,
      @required this.selectionColor,
      @required this.touchCallback,
      @required this.widthProp});

  final List data;
  final double lineWidth;
  // final bool enableGridLines;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final String labelPrefix;
  final double volumeProp;
  final Color increaseColor;
  final Color decreaseColor;
  final bool fillBoxes;
  final Color lowHighColor;
  final double volumeBarOpacity;
  final double barWidth;
  final Offset touchPosition;
  final Color selectionColor;
  final Function touchCallback;
  final double widthProp;

  double _min;
  double _max;
  double _maxVolume;

  List<TextPainter> gridLineTextPainters = [];
  TextPainter maxVolumePainter;

  numCommaParse(number) {
    return number.round().toString().replaceAllMapped(
        new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }

  update() {
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;
    for (var i in data) {
      if (i["high"] > _max) {
        _max = i["high"].toDouble();
      }
      if (i["low"] < _min) {
        _min = i["low"].toDouble();
      }
      if (i["volumeto"] > _maxVolume) {
        _maxVolume = i["volumeto"].toDouble();
      }
    }

    // if (enableGridLines) {
    //   double gridLineValue;
    //   for (int i = 0; i < gridLineAmount; i++) {
    //     // Label grid lines
    //     gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);
    //
    //     String gridLineText;
    //     if (gridLineValue < 1) {
    //       gridLineText = gridLineValue.toStringAsPrecision(4);
    //     } else if (gridLineValue < 999) {
    //       gridLineText = gridLineValue.toStringAsFixed(2);
    //     } else {
    //       gridLineText = gridLineValue.round().toString().replaceAllMapped(
    //           new RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    //           (Match m) => "${m[1]},");
    //     }
    //
    //     gridLineTextPainters.add(new TextPainter(
    //         text: new TextSpan(
    //             text: labelPrefix + gridLineText,
    //             style: new TextStyle(
    //                 color: gridLineLabelColor,
    //                 fontSize: 10.0,
    //                 fontWeight: FontWeight.bold)),
    //         textDirection: TextDirection.ltr));
    //     gridLineTextPainters[i].layout();
    //   }
    //
    //   // Label volume line
    //   maxVolumePainter = new TextPainter(
    //       text: new TextSpan(
    //           text: labelPrefix + numCommaParse(_maxVolume),
    //           style: new TextStyle(
    //               color: gridLineLabelColor,
    //               fontSize: 10.0,
    //               fontWeight: FontWeight.bold)),
    //       textDirection: TextDirection.ltr);
    //   maxVolumePainter.layout();
    // }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_min == null || _max == null || _maxVolume == null) {
      update();
    }

    final double volumeHeight = size.height * volumeProp;
    final double volumeNormalizer = volumeHeight / _maxVolume;

    double width = size.width * widthProp;
    final double height = size.height * (1 - volumeProp);

    // if (enableGridLines) {
    //   width = size.width - gridLineTextPainters[0].text.text.length * 6;
    //   Paint gridPaint = new Paint()
    //     ..color = gridLineColor
    //     ..strokeWidth = gridLineWidth;
    //
    //   double gridLineDist = height / (gridLineAmount - 1);
    //   double gridLineY;
    //
    //   // Draw grid lines
    //   for (int i = 0; i < gridLineAmount; i++) {
    //     gridLineY = (gridLineDist * i).round().toDouble();
    //     canvas.drawLine(new Offset(0.0, gridLineY),
    //         new Offset(width, gridLineY), gridPaint);
    //
    //     // Label grid lines
    //     gridLineTextPainters[i]
    //         .paint(canvas, new Offset(width + 2.0, gridLineY - 6.0));
    //   }
    //
    //   // Label volume line
    //   maxVolumePainter.paint(canvas, new Offset(0.0, gridLineY + 2.0));
    // }

    final double heightNormalizer = height / (_max - _min);
    final double rectWidth = barWidth ?? width / data.length * .7;

    double rectLeft;
    double rectTop;
    double rectRight;
    double rectBottom;

    Paint rectPaint;

    // Loop through all data
    for (int i = 0; i < data.length; i++) {
      rectLeft = (i * width / data.length) + lineWidth / 2 + barWidth / 2;
      rectRight = rectLeft + rectWidth;

      double volumeBarTop = (height + volumeHeight) -
          (data[i]["volumeto"] * volumeNormalizer - lineWidth / 2);
      double volumeBarBottom = height + volumeHeight + lineWidth / 2;

      if (data[i]["open"] > data[i]["close"]) {
        // Draw candlestick if decrease
        rectTop = height - (data[i]["open"] - _min) * heightNormalizer;
        rectBottom = height - (data[i]["close"] - _min) * heightNormalizer;
        rectPaint = new Paint()
          ..color = decreaseColor
          ..strokeWidth = lineWidth;
      } else {
        // Draw candlestick if increase
        rectTop = (height - (data[i]["close"] - _min) * heightNormalizer) +
            lineWidth / 2;
        rectBottom = (height - (data[i]["open"] - _min) * heightNormalizer) -
            lineWidth / 2;
        rectPaint = new Paint()
          ..color = increaseColor
          ..strokeWidth = lineWidth;
      }

      Paint lowHighPaint = new Paint()..strokeWidth = lineWidth;

      // Change the color for low/high spread if [lowHighColor] is set
      if (lowHighColor != null) {
        lowHighPaint.color = lowHighColor;
      }

      // Draw low/high candlestick wicks
      double low = height - (data[i]["low"] - _min) * heightNormalizer;
      double high = height - (data[i]["high"] - _min) * heightNormalizer;
      canvas.drawLine(
          new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectBottom),
          new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, low),
          lowHighPaint);
      canvas.drawLine(
          new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectTop),
          new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, high),
          lowHighPaint);

      if (fillBoxes) {
        Rect ocRect =
            new Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom);
        canvas.drawRect(ocRect, rectPaint);

        // Draw volume bars
        Rect volumeRect = new Rect.fromLTRB(
            rectLeft, volumeBarTop, rectRight, volumeBarBottom);
        canvas.drawRect(
            volumeRect,
            new Paint()
              ..color = rectPaint.color.withOpacity(volumeBarOpacity)
              ..strokeWidth = lineWidth);
      } else {
        canvas.drawLine(new Offset(rectLeft, rectBottom - lineWidth / 2),
            new Offset(rectRight, rectBottom - lineWidth / 2), rectPaint);
        canvas.drawLine(new Offset(rectLeft, rectTop + lineWidth / 2),
            new Offset(rectRight, rectTop + lineWidth / 2), rectPaint);
        canvas.drawLine(new Offset(rectLeft + lineWidth / 2, rectBottom),
            new Offset(rectLeft + lineWidth / 2, rectTop), rectPaint);
        canvas.drawLine(new Offset(rectRight - lineWidth / 2, rectBottom),
            new Offset(rectRight - lineWidth / 2, rectTop), rectPaint);

        // Draw volume bars
        canvas.drawLine(
            new Offset(rectLeft, volumeBarBottom - lineWidth / 2),
            new Offset(rectRight, volumeBarBottom - lineWidth / 2),
            new Paint()
              ..color = rectPaint.color.withOpacity(volumeBarOpacity)
              ..strokeWidth = lineWidth);
        canvas.drawLine(
            new Offset(rectLeft, volumeBarTop + lineWidth / 2),
            new Offset(rectRight, volumeBarTop + lineWidth / 2),
            new Paint()
              ..color = rectPaint.color.withOpacity(volumeBarOpacity)
              ..strokeWidth = lineWidth);
        canvas.drawLine(
            new Offset(rectLeft + lineWidth / 2, volumeBarBottom),
            new Offset(rectLeft + lineWidth / 2, volumeBarTop),
            new Paint()
              ..color = rectPaint.color.withOpacity(volumeBarOpacity)
              ..strokeWidth = lineWidth);
        canvas.drawLine(
            new Offset(rectRight - lineWidth / 2, volumeBarBottom),
            new Offset(rectRight - lineWidth / 2, volumeBarTop),
            new Paint()
              ..color = rectPaint.color.withOpacity(volumeBarOpacity)
              ..strokeWidth = lineWidth);
      }
    }

    if (touchPosition != null) {
      int candleIndex = _getClosestTouchCandleIndex(width);
      if (touchCallback != null) {
        touchCallback(candleIndex);
      }

      rectLeft = (candleIndex * width / data.length) + barWidth;
      rectPaint
        ..color = selectionColor
        ..strokeWidth = .7;

      canvas.drawLine(new Offset(rectLeft, 0),
          new Offset(rectLeft, size.height), rectPaint);
    } else if (touchCallback != null) {
      touchCallback();
    }
  }

  int _getClosestTouchCandleIndex(double width) {
    double singleCandle = width / data.length;
    int candleIndex = touchPosition.dx ~/ singleCandle;

    return max(min(candleIndex, data.length - 1), 0);
  }

  @override
  bool shouldRepaint(_OHLCVPainter old) {
    return data != old.data ||
        lineWidth != old.lineWidth ||
        // enableGridLines != old.enableGridLines ||
        gridLineColor != old.gridLineColor ||
        gridLineAmount != old.gridLineAmount ||
        gridLineWidth != old.gridLineWidth ||
        volumeProp != old.volumeProp ||
        gridLineLabelColor != old.gridLineLabelColor ||
        touchPosition != old.touchPosition;
  }
}
