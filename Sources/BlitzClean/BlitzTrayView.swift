import AppKit
import SwiftUI

struct BlitzTrayView: View {
  @ObservedObject var monitor: SystemMonitor
  @ObservedObject var memory: MemoryRescueModel
  @ObservedObject var recovery: AppRecoveryModel
  @ObservedObject var navigation: CleanNavigation
  @Environment(\.openWindow) private var openWindow
  @AppStorage(MenuBarPreferenceKey.memoryDisplay) private var memoryDisplay = MenuBarMemoryDisplay
    .available

  private var snapshot: SystemSnapshot { monitor.snapshot }

  var body: some View {
    let topApps = memory.apps.largest(.init(count: 3, key: \.memoryBytes))
    VStack(alignment: .leading, spacing: 0) {
      header
      VStack(alignment: .leading, spacing: 8) {
        if memory.capacity.risk > .normal { pressureAlert }
        systemGroup
        if !topApps.isEmpty { appsGroup(topApps) }
      }
      footer
    }
    .padding(.horizontal, 8)
    .padding(.top, 8)
    .padding(.bottom, 7)
    .frame(width: 340)
    .blitzTheme()
    .background(WindowOpacityAnchor())
    .overlay {
      RoundedRectangle(cornerRadius: 10).strokeBorder(BlitzUI.panelStroke).allowsHitTesting(false)
    }
    .blitzDropdownHost()
  }

  private var header: some View {
    HStack(spacing: 8) {
      BlitzWordmark()
      Spacer()
      BlitzActionMenu(label: "BlitzClean settings", symbol: "gearshape") {
        Button("Settings…") { open(.settings) }
        Divider()
        Button("Stop monitoring and quit") { AppLifetime.stopMonitoringAndQuit() }
      }
    }.padding(.bottom, 6)
  }

  private var systemGroup: some View {
    VStack(alignment: .leading, spacing: 0) {
      BlitzUI.sectionLabel("System")
      VStack(alignment: .leading, spacing: 8) {
        Text("This Mac").font(BlitzType.rowTitle).lineLimit(1)
        HStack(alignment: .top, spacing: 10) {
          meterLink(.memory) {
            UsageDialItem(
              ratio: snapshot.ramTotal > 0 ? snapshot.ramUsedRatio : nil,
              tone: memoryTone, title: "Memory", note: memoryNote)
          }
          meterLink(.cpu) {
            UsageDialItem(
              ratio: snapshot.cpuUsage, tone: cpuTone, title: "CPU",
              note: "\(ProcessInfo.processInfo.activeProcessorCount) cores")
          }
        }
        meterLink(.storage) {
          UsageDialItem(
            ratio: snapshot.diskTotal > 0 ? snapshot.diskUsedRatio : nil,
            tone: MenuBarTones.disk(snapshot), title: "Storage",
            note: snapshot.diskTotal > 0
              ? "\(ByteText.compact(snapshot.diskAvailable)) free" : "Reading storage…")
        }
      }
      .padding(.top, 6)
      .padding(.bottom, 2)
      .overlay(alignment: .top) {
        Rectangle().fill(BlitzUI.separator).frame(height: 1).allowsHitTesting(false)
      }
    }
  }

  private var memoryTone: MetricTone {
    switch memory.pressure {
    case .critical: .critical
    case .warning: .warning
    case .normal: snapshot.ramTotal > 0 ? .good : .neutral
    case .unknown: .neutral
    }
  }

  private var cpuTone: MetricTone {
    snapshot.cpuUsage.map(MenuBarTones.cpu) ?? .neutral
  }

  private var memoryNote: String {
    guard snapshot.ramTotal > 0 else { return "Reading memory…" }
    return memoryDisplay == .available
      ? "\(ByteText.compact(snapshot.ramAvailable)) free"
      : "\(ByteText.compact(snapshot.ramUsed)) used"
  }

  private func meterLink<Label: View>(_ page: CleanPage, @ViewBuilder label: () -> Label)
    -> some View
  {
    Button {
      open(page)
    } label: {
      label().frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, alignment: .leading)
    .blitzPointingHand()
    .help("Open \(page.rawValue)")
  }

  private func appsGroup(_ topApps: [MemoryApp]) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      BlitzUI.sectionLabel("Apps").padding(.bottom, 2)
      ForEach(topApps) { app in
        Button {
          open(.memory)
        } label: {
          HStack(spacing: 8) {
            ApplicationIcon(source: .file(app.bundleURL.path), size: 16, fallback: "app")
            Text(app.name).font(BlitzType.rowTitle).lineLimit(1)
            Spacer(minLength: 8)
            Text(ByteText.compact(app.memoryBytes)).font(BlitzType.numeric)
              .foregroundStyle(BlitzUI.secondaryText)
          }
          .padding(.vertical, 5)
          .overlay(alignment: .top) {
            Rectangle().fill(BlitzUI.separator).frame(height: 1).allowsHitTesting(false)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(BlitzRowButtonStyle(radius: 4))
        .help("Open Memory")
      }
    }
  }

  private var pressureAlert: some View {
    let capacity = memory.capacity
    let isDisk = capacity.limit == .disk
    return Button {
      navigation.review(capacity)
      openWindow.dashboard()
    } label: {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12))
          .foregroundStyle(capacity.risk.tone.color).padding(.top, 1)
        VStack(alignment: .leading, spacing: 3) {
          Text(capacity.title).font(BlitzType.label)
          Text(
            isDisk
              ? "Avoid large downloads and builds. Free up space."
              : "Avoid new threads or builds. Pause or quit unused projects."
          )
          .font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
          .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 4)
        BlitzChevron().padding(.top, 3)
      }
      .padding(12).frame(maxWidth: .infinity, alignment: .leading)
      .blitzToneCard(capacity.risk.tone)
    }.buttonStyle(BlitzCardButtonStyle()).help(capacity.reviewTitle)
  }

  private var footer: some View {
    HStack(spacing: 8) {
      Button {
        open(.recovery)
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "waveform.path.ecg")
          Text("Revive apps")
          if recovery.attentionCount > 0 {
            BlitzCountBadge(
              count: recovery.attentionCount,
              label: "\(recovery.attentionCount) apps need attention")
          }
        }.frame(maxWidth: .infinity)
      }.blitzButton(.secondary).controlSize(.regular)
      Button {
        open(.overview)
      } label: {
        Text("Open dashboard").frame(maxWidth: .infinity)
      }.blitzButton(.accent).controlSize(.regular)
    }
    .padding(.top, 6)
    .overlay(alignment: .top) {
      Rectangle().fill(BlitzUI.separator).frame(height: 1).allowsHitTesting(false)
    }
  }

  private func open(_ page: CleanPage) {
    navigation.page = page
    openWindow.dashboard()
  }
}

struct TransparencyControls: View {
  @AppStorage(WindowOpacity.storageKey) private var transparency = 0.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        BlitzUI.sectionLabel("Transparency")
        Spacer()
        Text(WindowOpacity.label(transparency: transparency))
          .font(BlitzType.numeric)
          .foregroundStyle(BlitzUI.secondaryText)
      }
      Slider(
        value: $transparency,
        in: 0...100,
        step: 5
      )
      .accessibilityLabel("Transparency")
      .accessibilityValue(WindowOpacity.label(transparency: transparency))
      HStack {
        Text("Solid")
        Spacer()
        Text("Clear")
      }
      .font(BlitzType.caption)
      .foregroundStyle(BlitzUI.tertiaryText)
    }
    .panelCard(padding: 16)
    .onChange(of: transparency) { _, value in
      let snapped = WindowOpacity.clamp(value)
      if snapped != value { transparency = snapped }
    }
    .help("Drag toward Clear to see through the window. The clearest setting is half opacity.")
  }
}

struct BlitzSettingsView: View {
  @ObservedObject var memory: MemoryRescueModel
  @ObservedObject var launchAtLogin: LaunchAtLoginController
  @ObservedObject var storage: StorageBreakdownModel
  @ObservedObject var recovery: AppRecoveryModel
  @ObservedObject var permissions: PermissionsModel
  @State private var roots = DeveloperLocations.additionalProjectRoots

  private var projectFolders: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          BlitzUI.sectionLabel("Project folders")
          Text("Home folders are always scanned. Add projects that live elsewhere.")
            .font(BlitzType.body).foregroundStyle(BlitzUI.secondaryText)
        }
        Spacer()
        Button("Add folder…") { addRoot() }.blitzButton(.secondary).controlSize(.small)
      }
      ForEach(roots, id: \.self) { root in
        HStack {
          Text(root).font(BlitzType.body).lineLimit(1).truncationMode(.middle).help(root)
          Spacer()
          Button("Remove") { setRoots(roots.filter { $0 != root }) }
            .blitzButton(.quiet).controlSize(.small)
        }
      }
    }.panelCard(padding: 16)
  }

  private func addRoot() {
    guard let path = Finder.chooseFolder(), !roots.contains(path) else { return }
    setRoots(roots + [path])
  }

  private func setRoots(_ value: [String]) {
    roots = value
    UserDefaults.standard.set(value, forKey: "locations.projectRoots")
    if !storage.isScanning { storage.scan() }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        PermissionSetupSection(memory: memory, recovery: recovery, permissions: permissions)
        VStack(alignment: .leading, spacing: 16) {
          BlitzUI.sectionLabel("Show in menu bar")
          MenuBarDisplayControls()
          Text(
            "Closing the window or pressing ⌘Q keeps monitoring. To exit, choose Stop monitoring and quit from the menu bar’s gear menu."
          )
          .font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
        }.panelCard(padding: 16)
        TransparencyControls()
        Toggle(
          "Launch at login",
          isOn: Binding(get: { launchAtLogin.enabled }, set: { launchAtLogin.setEnabled($0) })
        )
        .panelCard(padding: 16)
        MemoryGuardControls(model: memory)
        projectFolders
        VStack(alignment: .leading, spacing: 8) {
          Text("BlitzClean \(AppBrand.version) · by BlitzReels")
            .font(BlitzType.rowTitle)
          Text("Open source under MIT. Metrics and cleanup history stay on your Mac.")
            .font(BlitzType.body).foregroundStyle(BlitzUI.secondaryText)
          Link("Source code and issues", destination: AppBrand.repositoryURL)
        }
      }.font(BlitzType.callout).toggleStyle(BlitzSwitchStyle())
        .frame(maxWidth: .infinity, alignment: .leading).padding(BlitzUI.pagePadding)
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
