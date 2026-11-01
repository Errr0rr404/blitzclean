import AppKit
import SwiftUI

struct BlitzCleanApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var monitor = SystemMonitor()
  @StateObject private var launchAtLogin = LaunchAtLoginController()
  @StateObject private var storageBreakdown = StorageBreakdownModel()
  @StateObject private var dockerStorage = DockerStorageModel()
  @StateObject private var memoryRescue = MemoryRescueModel()
  @StateObject private var appRecovery = AppRecoveryModel()
  @StateObject private var permissions = PermissionsModel()
  @StateObject private var devProcesses = DevProcessModel()
  @StateObject private var folderExplorer = FolderExplorerModel()
  @StateObject private var workspaces = WorkspaceController()
  @StateObject private var developerBrowser = DeveloperBrowserModel()

  @StateObject private var quickClean = QuickCleanModel()
  @StateObject private var cleanNavigation = CleanNavigation()

  var body: some Scene {
    MenuBarExtra {
      BlitzTrayView(
        monitor: monitor, memory: memoryRescue, recovery: appRecovery,
        navigation: cleanNavigation)
    } label: {
      MenuBarHealthLabel(
        snapshot: monitor.snapshot, risk: max(memoryRescue.risk, memoryRescue.capacity.risk)
      )
      .environmentObject(cleanNavigation)
    }
    .menuBarExtraStyle(.window)

    Window(AppBrand.name, id: "dashboard") {
      BlitzDashboardView(
        monitor: monitor, memory: memoryRescue, cleanup: quickClean,
        storage: storageBreakdown, navigation: cleanNavigation,
        developerBrowser: developerBrowser, processes: devProcesses, workspaces: workspaces,
        services: .init(
          recovery: appRecovery, permissions: permissions, docker: dockerStorage,
          folders: folderExplorer,
          launchAtLogin: launchAtLogin))
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 1080, height: 820)
    .opensOnlyOnRequest()
    .commands {
      CommandGroup(replacing: .sidebar) {}
      CommandGroup(replacing: .appTermination) {
        Button("Close dashboard") { NSApp.terminate(nil) }.keyboardShortcut("q")
      }
      CommandGroup(replacing: .newItem) {
        Button("Open BlitzClean") {
          NotificationCenter.default.post(name: .openWorkspace, object: nil)
        }.keyboardShortcut("0")
      }
      CommandGroup(replacing: .appSettings) {
        Button("Settings…") {
          cleanNavigation.page = .settings
          NotificationCenter.default.post(name: .openWorkspace, object: nil)
        }.keyboardShortcut(",")
      }
      CommandMenu("Tools") {
        Button("Revive frozen app…") {
          NotificationCenter.default.post(name: .openAppRecovery, object: nil)
        }.keyboardShortcut("r", modifiers: [.command, .shift])
      }
    }

  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard
      AppQuitPolicy.keepsMonitoring(
        .init(
          explicitStop: AppLifetime.explicitStop,
          event: NSAppleEventManager.shared().currentAppleEvent))
    else { return .terminateNow }
    AppLifetime.closeDashboard(sender)
    return .terminateCancel
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    NotificationCenter.default.post(name: .openWorkspace, object: nil)
    return true
  }

  func applicationShouldSaveSecureApplicationState(_ app: NSApplication) -> Bool {
    false
  }

  func applicationShouldRestoreSecureApplicationState(_ app: NSApplication) -> Bool {
    false
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
    NSApp.setActivationPolicy(.regular)
  }
}

extension Scene {
  fileprivate func opensOnlyOnRequest() -> some Scene {
    if #available(macOS 15.0, *) {
      return SceneBuilder.buildOptional(
        SceneBuilder.buildLimitedAvailability(
          defaultLaunchBehavior(.suppressed).restorationBehavior(.disabled)))
    } else {
      return SceneBuilder.buildOptional(SceneBuilder.buildLimitedAvailability(self))
    }
  }
}

struct InitialWindowRequest {
  private var pending: String?

  init(_ arguments: [String]) {
    if arguments.contains("--workspace") {
      pending = "workspace"
    } else if arguments.contains("--storage") {
      pending = "storage-breakdown"
    } else if arguments.contains("--memory-rescue") {
      pending = "memory-rescue"
    } else if arguments.contains("--app-recovery") {
      pending = "app-recovery"
    } else if !arguments.contains("--background") {
      pending = "dashboard"
    }
  }

  mutating func consume() -> String? {
    defer { pending = nil }
    return pending
  }
}

@MainActor
enum AppLaunch {
  static var initialWindow = InitialWindowRequest(CommandLine.arguments)
}

/// 0 is a solid window. 100 is as clear as the window stays readable (50% opacity).
enum WindowOpacity {
  static let storageKey = "appearance.transparency"
  static let minimumOpacity = 0.5

  static func clamp(_ transparency: Double) -> Double {
    let value = transparency.isFinite ? transparency : 0
    return min(100, max(0, (value / 5).rounded() * 5))
  }

  static func alpha(transparency: Double) -> Double {
    1 - clamp(transparency) / 100 * (1 - minimumOpacity)
  }

  static func label(transparency: Double) -> String {
    let percent = Int(clamp(transparency))
    return percent == 0 ? "Solid" : "\(percent)% clear"
  }
}

/// Applies the saved transparency to the window that hosts this view.
struct WindowOpacityAnchor: View {
  @AppStorage(WindowOpacity.storageKey) private var transparency = 0.0

  var body: some View {
    WindowOpacityRepresentable(alpha: WindowOpacity.alpha(transparency: transparency))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(false)
  }
}

private struct WindowOpacityRepresentable: NSViewRepresentable {
  var alpha: Double

  func makeNSView(context: Context) -> NSView {
    let view = WindowOpacityView()
    view.alpha = alpha
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    guard let view = nsView as? WindowOpacityView else { return }
    view.alpha = alpha
    view.apply()
  }
}

private final class WindowOpacityView: NSView {
  var alpha = 1.0

  override func hitTest(_ point: NSPoint) -> NSView? { nil }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    apply()
  }

  /// The hosting view is not in a window during the first SwiftUI update.
  func apply(attempt: Int = 0) {
    guard let window else {
      guard attempt < 8 else { return }
      DispatchQueue.main.async { [weak self] in self?.apply(attempt: attempt + 1) }
      return
    }
    let value = CGFloat(min(1, max(WindowOpacity.minimumOpacity, alpha)))
    window.alphaValue = value
    window.isOpaque = value > 0.99
    if abs(window.alphaValue - value) > 0.01, attempt < 8 {
      DispatchQueue.main.async { [weak self] in self?.apply(attempt: attempt + 1) }
    }
  }
}
