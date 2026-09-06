import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'error_types.dart';

class ContentError extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final Future<void> Function() onRefresh;
  final bool sq;

  const ContentError({
    Key? key,
    required this.error,
    required this.stackTrace,
    required this.onRefresh,
    this.sq = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var type = errorType("$error");
    late String message;
    late IconData iconData;
    switch (type) {
      case ERROR_TYPE_NETWORK:
        iconData = Icons.wifi_off_rounded;
        message = "Unable to connect. Please check your network";
        break;
      case ERROR_TYPE_PERMISSION:
        iconData = Icons.highlight_off;
        message = "Permission denied or path unavailable";
        break;
      case ERROR_TYPE_TIME:
        iconData = Icons.timer_off;
        message = "Please check your device time";
        break;
      case ERROR_TYPE_UNDER_REVIEW:
        iconData = Icons.highlight_off;
        message = "Resource is unavailable or has not been reviewed";
        break;
      default:
        iconData = Icons.highlight_off;
        message = "Oops, something went wrong";
        break;
    }
    if ("$error".contains("This content is temporarily unavailable")) {
      iconData = Icons.timer_off;
      message = "Please log in and check in once";
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        print("$error");
        print("$stackTrace");
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        if (sq) {
          height = width;
        }
        var min = width < height ? width : height;
        var iconSize = min / 2.3;
        var textSize = min / 16;
        var tipSize = min / 20;
        var infoSize = min / 30;
        return GestureDetector(
          onTap: onRefresh,
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                Expanded(child: Container()),
                Icon(
                  iconData,
                  size: iconSize,
                  color: Colors.grey.shade600,
                ),
                Container(height: min / 10),
                Container(
                  padding: const EdgeInsets.only(
                    left: 30,
                    right: 30,
                  ),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: textSize),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text('(Tap Refresh)', style: TextStyle(fontSize: tipSize)),
                Container(height: min / 15),
                Text('$error', style: TextStyle(fontSize: infoSize)),
                Expanded(child: Container()),
              ],
            ),
          ),
        );
      },
    );
  }
}
