import WidgetKit
import SwiftUI

struct ContinueReadingEntry: TimelineEntry {
    let date: Date
    let title: String
    let progress: String
    let percent: Int
}

struct Provider: TimelineProvider {
    private let groupId = "group.app.one.tome"

    func placeholder(in context: Context) -> ContinueReadingEntry {
        ContinueReadingEntry(date: Date(), title: "Your book", progress: "12 of 240 pages", percent: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (ContinueReadingEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContinueReadingEntry>) -> ()) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> ContinueReadingEntry {
        let defaults = UserDefaults(suiteName: groupId)
        let title = defaults?.string(forKey: "title") ?? "No active book"
        let progress = defaults?.string(forKey: "progress") ?? "Start a book"
        let percent = defaults?.integer(forKey: "percent") ?? 0
        return ContinueReadingEntry(date: Date(), title: title, progress: progress, percent: percent)
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
