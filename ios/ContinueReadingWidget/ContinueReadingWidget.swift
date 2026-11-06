import WidgetKit
import SwiftUI

struct ContinueReadingEntry: TimelineEntry {
    let date: Date
    let title: String
    let progress: String
    let percent: Int
    let hasBook: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ContinueReadingEntry {
        ContinueReadingEntry(date: Date(), title: "Your book", progress: "12 of 240 pages", percent: 5, hasBook: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ContinueReadingEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContinueReadingEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.app.one_tome")
        let title = userDefaults?.string(forKey: "title") ?? "No active book"
        let progress = userDefaults?.string(forKey: "progress") ?? "Start a book"
        let percent = userDefaults?.integer(forKey: "percent") ?? 0
        let hasBook = userDefaults?.bool(forKey: "hasBook") ?? false

        let entry = ContinueReadingEntry(date: Date(), title: title, progress: progress, percent: percent, hasBook: hasBook)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        completion(timeline)
    }
}

struct ContinueReadingWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CONTINUE READING")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0, green: 0.48, blue: 1))
            Text(entry.title)
                .font(.headline)
                .lineLimit(2)
            Text(entry.progress)
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressView(value: Double(entry.percent), total: 100)
                .tint(Color(red: 0, green: 0.48, blue: 1))
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ContinueReadingWidget: Widget {
    let kind: String = "ContinueReadingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ContinueReadingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Continue Reading")
        .description("Pick up your current book.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
