import AppKit
import SwiftUI

struct BlitzOverviewView: View {
  @ObservedObject var monitor: SystemMonitor
  @ObservedObject var memory: MemoryRescueModel
  @ObservedObject var repeats: RepeatCleanupModel
  @ObservedObject var processes: DevProcessModel
  @ObservedObject var recovery: AppRecoveryModel
  @ObservedObject var navigation: CleanNavigation
  @State private var forceQuitThread: AIThread?

  private struct Suggestion: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let detail: String
    let open: () -> Void
  }

  private var hogThreads: [AIThread] { Array(processes.threads.prefix(8)) }

  private var suggestions: [Suggestion] {
    var result: [Suggestion] = []
    if recovery.attentionCount > 0 {
      result.append(
        .init(
          id: "revive", symbol: "waveform.path.ecg",
          title: recovery.attentionCount == 1
            ? "1 app is stopped or frozen"
            : "\(recovery.attentionCount) apps are stopped or frozen",
          detail: "Revive or force quit them", open: { navigation.page = .recovery }))
    }
    let regrown = repeats.ready
    if !regrown.isEmpty {
      result.append(
        .init(
          id: "regrown", symbol: "arrow.counterclockwise",
          title: regrown.count == 1
            ? "1 removed folder grew back" : "\(regrown.count) removed folders grew back",
          detail:
            "\(ByteText.full(regrown.reduce(0) { $0 + (repeats.statuses[$1.id]?.bytes ?? 0) })) to remove again",
          open: {
            navigation.storagePage = .cleanup
            navigation.page = .storage
          }))
    }
    return result
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        let pressure = processes.pressure
        PressureBanner(
          assessment: pressure,
          review: .init(title: pressure.reviewTitle, action: { navigation.review(pressure) }))
        StorageHero(
          snapshot: monitor.snapshot,
          action: {
            navigation.storagePage = .browse
            navigation.page = .storage
          })
        HStack(alignment: .top, spacing: 16) {
          OverviewResourceCard(
            title: "Memory", value: ByteText.compact(monitor.snapshot.ramUsed),
            detail: "of \(ByteText.compact(monitor.snapshot.ramTotal)) used",
            footnote: "\(ByteText.compact(monitor.snapshot.ramAvailable)) available",
            samples: monitor.resourceSamples, kind: .memory,
            action: { navigation.page = .memory })
          OverviewResourceCard(
            title: "CPU", value: monitor.snapshot.cpuUsage.map(PercentText.make) ?? "—",
            detail: "across \(ProcessInfo.processInfo.activeProcessorCount) cores",
            footnote: "Thermals: \(monitor.snapshot.thermalStatus.title.lowercased())",
            samples: monitor.resourceSamples, kind: .cpu,
            action: { navigation.page = .cpu })
        }
        Button {
          navigation.page = .projects
        } label: {
          HStack {
            Label("Running projects", systemImage: "folder.fill")
            Spacer()
            let names = processes.projects([]).filter(\.isRunning)
            Text(
              names.prefix(3).map { "\($0.preference.name) · \(ByteText.compact($0.memoryBytes))" }
                .joined(separator: "   ")
            )
            .lineLimit(1).foregroundStyle(BlitzUI.secondaryText)
            BlitzChevron()
          }.blitzRow()
        }.buttonStyle(.plain).blitzPointingHand().blitzTable()
        threadSection
        let suggestions = suggestions
        if !suggestions.isEmpty {
          VStack(spacing: 0) {
            ForEach(suggestions) { suggestion in
              suggestionRow(suggestion)
              if suggestion.id != suggestions.last?.id { BlitzRowDivider(leading: 56) }
            }
          }.blitzTable()
        }
        if let error = monitor.historyPersistenceError {
          Label(error, systemImage: "exclamationmark.triangle")
            .font(BlitzType.callout).foregroundStyle(BlitzUI.warning)
        }
      }.padding(BlitzUI.pagePadding)
    }
    .task {
      processes.refreshIfStale()
      repeats.check()
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if let thread = forceQuitThread {
        let name = thread.displayName
        BlitzConfirmation(
          title: "Force quit \(name)?",
          message:
            "Ends \(thread.processIDs.count) processes immediately, including work in progress.",
          confirmTitle: "Force Quit",
          onConfirm: {
            forceQuitThread = nil
            processes.stopThread(thread, force: true)
          }, onCancel: { forceQuitThread = nil })
      }
    }
  }

  @ViewBuilder private var threadSection: some View {
    let threads = hogThreads
    let running = processes.threads.filter { !$0.isPaused }
    let ram = processes.threads.reduce(0) { $0 + $1.memoryBytes }
    VStack(alignment: .leading, spacing: 10) {
      BlitzSectionHeader(title: "AI threads", count: processes.threads.count) {
        if ram > 0 {
          Text(ByteText.full(ram)).font(BlitzType.numeric).foregroundStyle(BlitzUI.secondaryText)
        }
        if running.count > 1 {
          Button("Pause \(running.count - 1) others") {
            for thread in running.dropFirst() { processes.pauseThread(thread) }
          }.blitzButton(.accent).controlSize(.small)
            .help("Keeps the largest thread. Paused threads keep their RAM until you Quit.")
        }
      }
      Text("Pause stops local workers and keeps RAM. Shared desktop chats may be grouped.")
        .font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
      if let message = processes.threadMessage {
        Text(message).font(BlitzType.body).foregroundStyle(BlitzUI.supportingText)
          .textSelection(.enabled)
      }
      if threads.isEmpty {
        Text(processes.scannedAt == nil ? "Reading AI processes…" : "No AI threads running")
          .font(BlitzType.body).foregroundStyle(BlitzUI.secondaryText)
          .frame(maxWidth: .infinity, minHeight: 56).panelCard()
      } else {
        VStack(spacing: 0) {
          ForEach(threads) { thread in
            AIThreadRow(
              thread: thread, isBusy: processes.stoppingThreads.contains(thread.id),
              onPause: { processes.pauseThread(thread) },
              onResume: { processes.resumeThread(thread) },
              onQuit: { processes.stopThread(thread, force: false) },
              onForceQuit: { forceQuitThread = thread })
            if thread.id != threads.last?.id { BlitzRowDivider(leading: 56) }
          }
        }.blitzTable()
        if processes.threads.count > threads.count {
          Button("Show all \(processes.threads.count) on Memory") { navigation.page = .memory }
            .blitzButton(.quiet).controlSize(.small)
        }
      }
    }
  }

  private func suggestionRow(_ suggestion: Suggestion) -> some View {
    Button(action: suggestion.open) {
      HStack(spacing: 12) {
        Image(systemName: suggestion.symbol).font(.system(size: 14))
          .foregroundStyle(BlitzUI.secondaryText).frame(width: 28)
        VStack(alignment: .leading, spacing: 2) {
          Text(suggestion.title).font(BlitzType.rowTitle)
          Text(suggestion.detail).font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
        }
        Spacer()
        BlitzChevron()
      }.blitzRow()
    }.buttonStyle(.plain).blitzPointingHand()
  }
}

private struct OverviewResourceCard: View {
  let title: String
  let value: String
  let detail: String
  let footnote: String
  let samples: [ResourceSample]
  let kind: ResourceKind
  let action: () -> Void

  var body: some View {
    Button(action: action) { card }.buttonStyle(BlitzCardButtonStyle()).help("Open \(title)")
  }

  private var ratio: Double? {
    guard let sample = samples.last else { return nil }
    return kind.value(sample)
  }

  private var card: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 10) {
        UsageDial(ratio: ratio, tone: ratio.map(MetricTone.forUsedRatio) ?? .neutral, size: 40)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(BlitzType.rowTitle)
          Text(value).font(BlitzType.face(20, .medium)).monospacedDigit()
          Text(detail).font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
        }
        Spacer(minLength: 8)
        BlitzChevron()
      }
      ResourcePlot(samples: samples, kind: kind, color: BlitzUI.mint, seconds: 300)
        .frame(height: 48)
      HStack {
        Text(footnote)
        Spacer()
        Text("5 min")
      }.font(BlitzType.caption).monospacedDigit().foregroundStyle(BlitzUI.secondaryText)
    }.frame(maxWidth: .infinity, alignment: .leading).panelCard(padding: 16)
  }
}

struct StorageHero: View {
  let snapshot: SystemSnapshot
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .center, spacing: 12) {
          UsageDial(
            ratio: snapshot.diskTotal > 0 ? snapshot.diskUsedRatio : nil,
            tone: MenuBarTones.disk(snapshot), size: 44)
          VStack(alignment: .leading, spacing: 2) {
            Text("Storage").font(BlitzType.rowTitle)
            Text(snapshot.diskTotal > 0 ? ByteText.full(snapshot.diskAvailable) : "—")
              .font(BlitzUI.valueFont).monospacedDigit()
            Text("available").font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
          }
          Spacer(minLength: 8)
          BlitzChevron()
        }
        VStack(alignment: .leading, spacing: 8) {
          CapacityBar(usedRatio: snapshot.diskUsedRatio, tone: MenuBarTones.disk(snapshot))
          HStack {
            Text("\(ByteText.full(snapshot.diskUsed)) used")
            Spacer()
            Text("\(ByteText.full(snapshot.diskTotal)) total")
          }.font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText).monospacedDigit()
        }
      }.frame(maxWidth: .infinity, alignment: .leading).panelCard(padding: 16)
    }.buttonStyle(BlitzCardButtonStyle()).help("Open Storage")
  }
}
