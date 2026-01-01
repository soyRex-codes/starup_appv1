import 'package:flutter_test/flutter_test.dart';
import 'package:foundervers/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    // Helper to get time X ago
    DateTime timeAgo({
      int seconds = 0,
      int minutes = 0,
      int hours = 0,
      int days = 0,
    }) {
      return DateTime.now().subtract(
        Duration(seconds: seconds, minutes: minutes, hours: hours, days: days),
      );
    }

    group('formatTimeAgo', () {
      test('should return "Just now" for less than 1 minute', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(seconds: 30)), 'Just now');
      });

      test('should return minutes correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(minutes: 1)), '1 min ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(minutes: 25)), '25 mins ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(minutes: 59)), '59 mins ago');
      });

      test('should return hours correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(hours: 1)), '1 hr ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(hours: 5)), '5 hrs ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(hours: 23)), '23 hrs ago');
      });

      test('should return days correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 1)), '1 day ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 5)), '5 days ago');
      });

      test('should return weeks correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 8)), '1 week ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 14)), '2 weeks ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 28)), '4 weeks ago');
      });

      test('should return months correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 31)), '1 month ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 60)), '2 months ago');
      });

       test('should return years correctly', () {
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 366)), '1 year ago');
        expect(TimeFormatter.formatTimeAgo(timeAgo(days: 730)), '2 years ago');
      });
    });

    group('formatTimeAgoShort', () {
      test('should format short strings', () {
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(seconds: 30)), 'now');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(minutes: 5)), '5m');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(hours: 5)), '5h');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(days: 5)), '5d');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(days: 8)), '1w');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(days: 35)), '1mo');
        expect(TimeFormatter.formatTimeAgoShort(timeAgo(days: 370)), '1y');
      });
    });
  });
}
