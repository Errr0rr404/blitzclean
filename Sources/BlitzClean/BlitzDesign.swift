import AppKit
import SwiftUI

enum BlitzType {
  /// Avenir Next, the same face Usage Monitor uses for the panel.
  static func face(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    let name: String
    if weight == .ultraLight || weight == .thin || weight == .light {
      name = "AvenirNext-UltraLight"
    } else if weight == .medium {
      name = "AvenirNext-Medium"
    } else if weight == .semibold {
      name = "AvenirNext-DemiBold"
    } else if weight == .bold {
      name = "AvenirNext-Bold"
    } else if weight == .heavy || weight == .black {
      name = "AvenirNext-Heavy"
    } else {
      name = "AvenirNext-Regular"
    }
    return .custom(name, size: size)
  }

  static let largeTitle = face(13, .bold)
  static let title = face(15, .semibold)
  static let headline = face(13, .semibold)
  static let section = face(13, .semibold)
  static let callout = face(13)
  static let rowTitle = face(12, .semibold)
  static let body = face(12)
  static let label = face(12, .medium)
  static let caption = face(11)
  static let captionEmphasis = face(11, .medium)
  static let numeric = Font.system(size: 12, weight: .medium, design: .monospaced)
  /// Tracked uppercase group label, matching Usage Monitor's service names.
  static let kicker = Font.system(size: 11, weight: .medium, design: .monospaced)
}

enum BlitzUI {
  /// Ion accent from Usage Monitor. The property keeps the historical name `mint`.
  static let mint = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255)
  static let lavender = mint
  static let warning = Color(red: 255 / 255, green: 177 / 255, blue: 90 / 255)
  static let recordRed = Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
  static let canvasBackground = Color(red: 7 / 255, green: 11 / 255, blue: 16 / 255)
  static let panelBackground = Color(red: 12 / 255, green: 18 / 255, blue: 24 / 255)
  static let sidebarBackground = panelBackground
  static let menuFill = Color(red: 10 / 255, green: 14 / 255, blue: 18 / 255)
  static let panelStroke = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.18)
  static let separator = panelStroke
  static let track = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.16)
  static let cardFill = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.045)
  static let quietFill = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.06)
  static let controlFill = panelBackground
  static let hoverFill = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.12)
  static let selectedFill = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.16)
  static let strongFill = Color(red: 94 / 255, green: 200 / 255, blue: 255 / 255).opacity(0.22)
  static let strongStroke = panelStroke
  static let primaryText = Color(red: 231 / 255, green: 246 / 255, blue: 255 / 255)
  static let supportingText = Color(red: 186 / 255, green: 214 / 255, blue: 230 / 255)
  static let secondaryText = Color(red: 138 / 255, green: 160 / 255, blue: 179 / 255)
  static let tertiaryText = Color(red: 138 / 255, green: 160 / 255, blue: 179 / 255).opacity(0.62)
  static let controlRadius: CGFloat = 8
  static let cardRadius: CGFloat = 10
  static let pagePadding: CGFloat = 28
  static let toolbarHeight: CGFloat = 52
  static let titleFont = BlitzType.largeTitle
  static let valueFont = BlitzType.face(28, .medium)
  /// Near-black used on top of the accent fill, matching Usage Monitor's ground.
  static let onAccent = Color(red: 7 / 255, green: 11 / 255, blue: 16 / 255)

  static func sectionLabel(_ title: String) -> some View {
    Text(title).font(BlitzType.kicker).tracking(1.76).textCase(.uppercase)
      .foregroundStyle(mint).lineLimit(1)
  }
}

/// Uppercase wordmark shared by the sidebar, page titles, and the menu-bar panel.
struct BlitzWordmark: View {
  var title: String = AppBrand.name
  var size: CGFloat = 12

  var body: some View {
    Text(title).font(BlitzType.face(size, .bold)).tracking(size * 0.06).textCase(.uppercase)
      .foregroundStyle(BlitzUI.primaryText).lineLimit(1)
  }
}

enum BlitzButtonEmphasis {
  case accent, emphasized, secondary, quiet
}

enum BlitzControlMetrics {
  static func height(_ size: ControlSize) -> CGFloat {
    switch size {
    case .mini: 24
    case .small: 28
    case .large, .extraLarge: 40
    default: 34
    }
  }

  static func fontSize(_ size: ControlSize) -> CGFloat {
    switch size {
    case .mini, .small: 11
    case .large, .extraLarge: 13
    default: 12
    }
  }

  static func horizontalPadding(_ size: ControlSize) -> CGFloat {
    switch size {
    case .mini, .small: 8
    case .large, .extraLarge: 16
    default: 10
    }
  }
}

struct BlitzButtonStyle: ButtonStyle {
  let emphasis: BlitzButtonEmphasis
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.controlSize) private var controlSize
  @State private var isHovered = false

  init(_ emphasis: BlitzButtonEmphasis) {
    self.emphasis = emphasis
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(BlitzType.face(BlitzControlMetrics.fontSize(controlSize), .medium))
      .lineLimit(1)
      .symbolRenderingMode(.monochrome)
      .padding(.horizontal, BlitzControlMetrics.horizontalPadding(controlSize))
      .padding(.vertical, 4)
      .frame(minHeight: BlitzControlMetrics.height(controlSize))
      .foregroundStyle(foreground(configuration.role))
      .background(fill, in: RoundedRectangle(cornerRadius: BlitzUI.controlRadius))
      .overlay {
        RoundedRectangle(cornerRadius: BlitzUI.controlRadius)
          .strokeBorder(stroke, lineWidth: 1)
          .allowsHitTesting(false)
      }
      .opacity(isEnabled ? (configuration.isPressed ? 0.76 : 1) : 0.4)
      .contentShape(RoundedRectangle(cornerRadius: BlitzUI.controlRadius))
      .onHover { isHovered = $0 }
      .blitzPointingHand()
  }

  private var stroke: Color {
    switch emphasis {
    case .secondary: BlitzUI.panelStroke
    case .emphasized: BlitzUI.mint
    case .accent, .quiet: .clear
    }
  }

  private func foreground(_ role: ButtonRole?) -> Color {
    if role == .destructive, emphasis != .accent { return BlitzUI.recordRed }
    switch emphasis {
    case .accent: return BlitzUI.onAccent
    case .emphasized: return BlitzUI.mint
    case .secondary, .quiet:
      return isHovered && isEnabled ? BlitzUI.primaryText : BlitzUI.secondaryText
    }
  }

  private var fill: Color {
    let hovered = isHovered && isEnabled
    switch emphasis {
    case .accent: return hovered ? BlitzUI.mint.opacity(0.88) : BlitzUI.mint
    case .emphasized: return hovered ? BlitzUI.hoverFill : .clear
    case .secondary: return hovered ? BlitzUI.hoverFill : .clear
    case .quiet: return hovered ? BlitzUI.quietFill : .clear
    }
  }
}

extension View {
  func blitzButton(_ emphasis: BlitzButtonEmphasis) -> some View {
    buttonStyle(BlitzButtonStyle(emphasis))
  }

  @ViewBuilder func blitzPointingHand() -> some View {
    if #available(macOS 15.0, *) {
      pointerStyle(.link).allowsWindowActivationEvents(true)
    } else {
      self
    }
  }

  func blitzInput() -> some View {
    textFieldStyle(.plain).font(BlitzType.callout)
      .padding(.horizontal, 12).frame(height: 38)
      .background(BlitzUI.controlFill, in: RoundedRectangle(cornerRadius: BlitzUI.controlRadius))
      .overlay {
        RoundedRectangle(cornerRadius: BlitzUI.controlRadius).strokeBorder(BlitzUI.panelStroke)
      }
  }

  func blitzTheme() -> some View {
    self
      .background {
        ZStack {
          BlitzUI.canvasBackground
          RadialGradient(
            colors: [BlitzUI.mint.opacity(0.12), .clear],
            center: UnitPoint(x: 1, y: 0),
            startRadius: 20,
            endRadius: 640
          )
        }
        .ignoresSafeArea()
      }
      .foregroundStyle(BlitzUI.primaryText)
      .tint(BlitzUI.mint)
      .buttonStyle(BlitzButtonStyle(.secondary))
      .toggleStyle(BlitzCheckboxStyle())
      .preferredColorScheme(.dark)
  }
}

struct BlitzSelectionButtonStyle: ButtonStyle {
  let isSelected: Bool
  @Environment(\.isEnabled) private var isEnabled
  @State private var isHovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(
        isSelected
          ? BlitzUI.onAccent
          : isHovered && isEnabled ? BlitzUI.primaryText : BlitzUI.secondaryText
      )
      .background(
        isSelected ? BlitzUI.mint : isHovered && isEnabled ? BlitzUI.hoverFill : .clear,
        in: RoundedRectangle(cornerRadius: 6)
      )
      .overlay {
        if !isSelected {
          RoundedRectangle(cornerRadius: 6)
            .strokeBorder(BlitzUI.panelStroke, lineWidth: 1)
            .allowsHitTesting(false)
        }
      }
      .contentShape(RoundedRectangle(cornerRadius: 6))
      .opacity(isEnabled ? configuration.isPressed ? 0.76 : 1 : 0.4)
      .onHover { isHovered = $0 }
      .blitzPointingHand()
  }
}

extension View {
  func blitzChipGroup() -> some View { self }
}

struct BlitzSegmentedPicker<Value: Hashable>: View {
  let title: String
  let options: [Value]
  @Binding var selection: Value
  let label: (Value) -> String
  var body: some View {
    HStack(spacing: 4) {
      ForEach(options, id: \.self) { value in
        Button {
          selection = value
        } label: {
          Text(label(value)).font(BlitzType.label).lineLimit(1).minimumScaleFactor(0.8)
            .padding(.horizontal, 6).frame(maxWidth: .infinity, minHeight: 28)
            .contentShape(Rectangle())
        }.buttonStyle(BlitzSelectionButtonStyle(isSelected: value == selection))
          .accessibilityAddTraits(selection == value ? .isSelected : [])
      }
    }.blitzChipGroup()
      .accessibilityElement(children: .contain).accessibilityLabel(title)
  }
}

struct BlitzChip: View {
  let title: String
  let symbol: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol).font(BlitzType.label).lineLimit(1).fixedSize()
        .padding(.horizontal, 10).frame(minHeight: 30).contentShape(Rectangle())
    }.buttonStyle(BlitzSelectionButtonStyle(isSelected: isSelected))
      .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

struct BlitzProcessButton: View {
  let title: String
  let label: String
  let isBusy: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if isBusy { ProgressView().controlSize(.mini) }
        Text(title)
      }.frame(minWidth: 42)
    }.blitzButton(.secondary).controlSize(.regular)
      .disabled(isBusy).accessibilityLabel(label)
  }
}

struct BlitzSearchField: View {
  let title: String
  @Binding var text: String
  @FocusState private var focused: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .medium))
        .foregroundStyle(BlitzUI.tertiaryText)
      TextField(title, text: $text).textFieldStyle(.plain).focused($focused)
        .font(BlitzType.body)
        .accessibilityLabel(title)
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill").foregroundStyle(BlitzUI.tertiaryText)
        }.buttonStyle(.plain).accessibilityLabel("Clear search").help("Clear search")
      }
    }.padding(.horizontal, 10).frame(height: 34)
      .background(BlitzUI.controlFill, in: RoundedRectangle(cornerRadius: BlitzUI.controlRadius))
      .overlay {
        RoundedRectangle(cornerRadius: BlitzUI.controlRadius)
          .strokeBorder(focused ? BlitzUI.mint.opacity(0.6) : BlitzUI.panelStroke, lineWidth: 1)
          .allowsHitTesting(false)
      }
  }
}

struct BlitzPageHeader<Actions: View>: View {
  let title: String
  var detail: String? = nil
  @ViewBuilder let actions: () -> Actions

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 3) {
        BlitzWordmark(title: title, size: 13)
        if let detail {
          Text(detail).font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 16)
      actions()
    }
    .padding(.horizontal, BlitzUI.pagePadding)
    .padding(.top, 16)
    .padding(.bottom, 12)
    .background {
      Color.clear.contentShape(Rectangle()).blitzWindowDrag()
    }
  }
}

enum BlitzStatusTone: Equatable {
  case good, working, warning, critical, muted

  var color: Color {
    switch self {
    case .good: BlitzUI.mint
    case .working: BlitzUI.supportingText
    case .warning: BlitzUI.warning
    case .critical: BlitzUI.recordRed
    case .muted: BlitzUI.tertiaryText
    }
  }
}

struct BlitzStatusDot: View {
  let tone: BlitzStatusTone
  var diameter: CGFloat = 6

  var body: some View {
    Circle().fill(tone.color).frame(width: diameter, height: diameter)
      .accessibilityHidden(true)
  }
}

struct BlitzStatusBadge: View {
  let title: String
  let tone: BlitzStatusTone

  var body: some View {
    HStack(spacing: 6) {
      BlitzStatusDot(tone: tone, diameter: 5)
      Text(title).font(BlitzType.captionEmphasis).lineLimit(1)
    }
    .foregroundStyle(tone == .muted || tone == .working ? BlitzUI.secondaryText : tone.color)
    .padding(.horizontal, 9)
    .frame(height: 24)
    .background(
      (tone == .muted || tone == .working ? Color.white : tone.color).opacity(0.08), in: .capsule)
  }
}

struct BlitzActionMenu<Content: View>: View {
  let label: String
  var title: String? = nil
  var symbol = "ellipsis"
  @ViewBuilder let content: () -> Content
  @State private var expanded = false
  @State private var menuHeight: CGFloat = 160
  @State private var hovered = false
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Button {
      expanded.toggle()
    } label: {
      HStack(spacing: 8) {
        if let title { Text(title).font(BlitzType.label) }
        Image(systemName: title == nil ? symbol : expanded ? "chevron.up" : "chevron.down")
          .font(.system(size: 12, weight: .semibold))
      }
      .foregroundStyle(hovered || expanded ? BlitzUI.primaryText : BlitzUI.secondaryText)
      .padding(.horizontal, 10).frame(minWidth: 34, minHeight: 34).contentShape(Rectangle())
      .background(
        expanded ? BlitzUI.selectedFill : hovered ? BlitzUI.quietFill : .clear,
        in: RoundedRectangle(cornerRadius: BlitzUI.controlRadius))
    }.buttonStyle(.plain).accessibilityLabel(label).help(label)
      .opacity(isEnabled ? 1 : 0.4)
      .onHover { hovered = $0 }
      .blitzPointingHand()
      .anchorPreference(key: BlitzDropdownPreference.self, value: .bounds) { anchor in
        expanded
          ? BlitzDropdownPresentation(
            anchor: anchor, width: 264, alignsLeading: title != nil, height: menuHeight,
            content: AnyView(
              VStack(alignment: .leading, spacing: 2) {
                content().buttonStyle(BlitzMenuActionStyle()).toggleStyle(BlitzMenuToggleStyle())
              }.padding(6)
                .environment(\.blitzDismissMenu, { expanded = false })
                .disabled(!isEnabled)
                .background {
                  GeometryReader { proxy in
                    Color.clear.onAppear { menuHeight = proxy.size.height }
                      .onChange(of: proxy.size.height) { _, height in menuHeight = height }
                  }
                }
            ), dismiss: { expanded = false }) : nil
      }
      .onExitCommand { expanded = false }
      .onChange(of: isEnabled) { _, enabled in if !enabled { expanded = false } }
      .onDisappear { expanded = false }
  }
}

private struct BlitzMenuToggleStyle: ToggleStyle {
  @Environment(\.blitzDismissMenu) private var dismiss

  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
      dismiss()
    } label: {
      HStack {
        configuration.label
        Spacer()
        Image(systemName: "checkmark").opacity(configuration.isOn ? 1 : 0)
      }
    }.buttonStyle(BlitzMenuItemStyle()).accessibilityValue(configuration.isOn ? "On" : "Off")
  }
}

private struct BlitzMenuDismissKey: EnvironmentKey {
  static let defaultValue: @MainActor @Sendable () -> Void = {}
}

extension EnvironmentValues {
  fileprivate var blitzDismissMenu: @MainActor @Sendable () -> Void {
    get { self[BlitzMenuDismissKey.self] }
    set { self[BlitzMenuDismissKey.self] = newValue }
  }
}

private struct BlitzMenuActionStyle: PrimitiveButtonStyle {
  @Environment(\.blitzDismissMenu) private var dismiss

  func makeBody(configuration: Configuration) -> some View {
    Button(role: configuration.role) {
      configuration.trigger()
      dismiss()
    } label: {
      configuration.label
    }.buttonStyle(BlitzMenuItemStyle())
  }
}

private struct BlitzMenuItemStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(BlitzType.callout)
      .foregroundStyle(
        configuration.role == .destructive ? BlitzUI.recordRed : BlitzUI.primaryText
      )
      .lineLimit(2).multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
      .padding(.horizontal, 10)
      .modifier(BlitzRowHighlight(isPressed: configuration.isPressed, radius: 6))
      .opacity(isEnabled ? 1 : 0.4)
  }
}

/// Hover and pressed fill shared by every full-row button: menus, browser rows, tray rows.
private struct BlitzRowHighlight: ViewModifier {
  let isPressed: Bool
  let radius: CGFloat
  @State private var hovered = false
  @Environment(\.isEnabled) private var isEnabled

  func body(content: Content) -> some View {
    content
      .background(
        isPressed ? BlitzUI.selectedFill : hovered && isEnabled ? BlitzUI.hoverFill : .clear,
        in: RoundedRectangle(cornerRadius: radius)
      )
      .contentShape(RoundedRectangle(cornerRadius: radius))
      .onHover { hovered = $0 }
      .blitzPointingHand()
  }
}

struct BlitzRowButtonStyle: ButtonStyle {
  var radius: CGFloat = 0

  func makeBody(configuration: Configuration) -> some View {
    configuration.label.modifier(
      BlitzRowHighlight(isPressed: configuration.isPressed, radius: radius))
  }
}

/// A whole card that opens something: faint hover wash and a small press scale.
struct BlitzCardButtonStyle: ButtonStyle {
  @State private var hovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .overlay {
        RoundedRectangle(cornerRadius: BlitzUI.cardRadius)
          .fill(Color.white.opacity(hovered ? 0.03 : 0)).allowsHitTesting(false)
      }
      .contentShape(RoundedRectangle(cornerRadius: BlitzUI.cardRadius))
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
      .onHover { hovered = $0 }
      .blitzPointingHand()
  }
}

struct BlitzChevron: View {
  var body: some View {
    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
      .foregroundStyle(BlitzUI.tertiaryText).accessibilityHidden(true)
  }
}

extension View {
  /// Severity-tinted surface for alerts.
  func blitzToneCard(_ tone: MetricTone, radius: CGFloat = BlitzUI.cardRadius) -> some View {
    background(tone.color.opacity(0.08), in: RoundedRectangle(cornerRadius: radius))
      .overlay {
        RoundedRectangle(cornerRadius: radius)
          .strokeBorder(tone.color.opacity(0.22), lineWidth: 1).allowsHitTesting(false)
      }
  }
}

private struct BlitzRowModifier: ViewModifier {
  @State private var hovered = false

  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 16).padding(.vertical, 10)
      .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
      .background(hovered ? BlitzUI.quietFill : .clear)
      .contentShape(Rectangle())
      .onHover { hovered = $0 }
  }
}

struct BlitzRowDivider: View {
  var leading: CGFloat = 56

  var body: some View {
    Rectangle().fill(BlitzUI.separator).frame(height: 1).padding(.leading, leading)
  }
}

private struct BlitzWindowDragModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(macOS 15.0, *) {
      content.gesture(WindowDragGesture()).allowsWindowActivationEvents(true)
    } else {
      content
    }
  }
}

extension View {
  func blitzRow() -> some View { modifier(BlitzRowModifier()) }

  func blitzWindowDrag() -> some View { modifier(BlitzWindowDragModifier()) }

  func blitzTable() -> some View {
    background(BlitzUI.cardFill)
      .clipShape(RoundedRectangle(cornerRadius: BlitzUI.cardRadius))
      .overlay {
        RoundedRectangle(cornerRadius: BlitzUI.cardRadius)
          .strokeBorder(BlitzUI.separator, lineWidth: 1).allowsHitTesting(false)
      }
  }
}

struct BlitzSwitchStyle: ToggleStyle {
  var showsLabel = true

  func makeBody(configuration: Configuration) -> some View {
    BlitzToggleBody(configuration: configuration, kind: .switch, showsLabel: showsLabel)
  }
}

struct BlitzCheckboxStyle: ToggleStyle {
  var showsLabel = true

  func makeBody(configuration: Configuration) -> some View {
    BlitzToggleBody(configuration: configuration, kind: .checkbox, showsLabel: showsLabel)
  }
}

private struct BlitzToggleBody: View {
  enum Kind { case `switch`, checkbox }

  let configuration: ToggleStyleConfiguration
  let kind: Kind
  let showsLabel: Bool
  @Environment(\.isEnabled) private var isEnabled
  @State private var hovered = false

  var body: some View {
    Button {
      withAnimation(.easeOut(duration: 0.14)) { configuration.isOn.toggle() }
    } label: {
      HStack(spacing: 10) {
        if kind == .checkbox { indicator }
        if showsLabel {
          configuration.label.frame(
            maxWidth: kind == .switch ? .infinity : nil, alignment: .leading)
        }
        if kind == .switch { indicator }
      }.frame(minWidth: 34, minHeight: 34).contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .opacity(isEnabled ? 1 : 0.4)
    .onHover { hovered = $0 }
    .blitzPointingHand()
    .accessibilityRepresentation {
      Toggle(isOn: configuration.$isOn) { configuration.label }
    }
  }

  @ViewBuilder private var indicator: some View {
    let on = configuration.isOn
    switch kind {
    case .switch:
      Capsule().fill(on ? BlitzUI.mint : hovered ? BlitzUI.strongFill : BlitzUI.selectedFill)
        .overlay(alignment: on ? .trailing : .leading) {
          Circle().fill(on ? BlitzUI.onAccent : BlitzUI.primaryText)
            .frame(width: 16, height: 16).padding(3)
        }
        .frame(width: 38, height: 22)
    case .checkbox:
      RoundedRectangle(cornerRadius: 5)
        .fill(on ? BlitzUI.mint : hovered ? BlitzUI.hoverFill : BlitzUI.controlFill)
        .overlay {
          RoundedRectangle(cornerRadius: 5)
            .strokeBorder(on ? .clear : BlitzUI.strongStroke, lineWidth: 1)
        }
        .overlay {
          Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
            .foregroundStyle(BlitzUI.onAccent).opacity(on ? 1 : 0)
        }
        .frame(width: 18, height: 18)
    }
  }
}
