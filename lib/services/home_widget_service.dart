import 'package:home_widget/home_widget.dart';
import '../models/book.dart';

class HomeWidgetService {
  static const androidWidgetName = 'ContinueReadingWidget';
  static const iosWidgetName = 'ContinueReadingWidget';

  static Future<void> update(Book? book) async {
    try {
      if (book == null || book.isCompleted) {
        await HomeWidget.saveWidgetData<String>('title', 'No active book');
        await HomeWidget.saveWidgetData<String>('progress', 'Start a book');
        await HomeWidget.saveWidgetData<int>('percent', 0);
        await HomeWidget.saveWidgetData<bool>('hasBook', false);
      } else {
        final percent = (book.progress * 100).round();
        await HomeWidget.saveWidgetData<String>('title', book.title);
        await HomeWidget.saveWidgetData<String>('progress', '${book.currentPage} of ${book.totalPages} pages');
        await HomeWidget.saveWidgetData<int>('percent', percent);
        await HomeWidget.saveWidgetData<bool>('hasBook', true);
        await HomeWidget.saveWidgetData<String>('type', book.isPhysical ? 'Physical' : 'PDF');
      }
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iosWidgetName,
      );
    } catch (_) {}
  }
}
