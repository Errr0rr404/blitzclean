import SwiftUI

enum MetricTone: Equatable {
  case neutral
  case good
  case warning
  case critical

  var color: Color {
    switch self {
    case .neutral:
      .secondary
    case .good:
      BlitzUI.mint
    case .warning:
      BlitzUI.warning
    case .critical:
      BlitzUI.recordRed
    }
  }

  static func forUsedRatio(_ ratio: Double) -> MetricTone {
    if ratio >= 0.95 {
      return .critical
    }

    if ratio >= 0.85 {
      return .warning
    }

    return .good
  }

  static func forAvailableRatio(_ ratio: Double) -> MetricTone {
    if ratio <= 0.1 {
      return .critical
    }

    if ratio <= 0.2 {
      return .warning
    }

    return .good
  }

  static func forDisk(_ input: DiskCapacityInput) -> MetricTone {
    switch DiskSpacePolicy.status(input) {
    case .healthy: .good
    case .warning: .warning
    case .critical: .critical
    case .unknown: .neutral
    }
  }
}

enum PanelMetrics {
  static let cardRadius: CGFloat = BlitzUI.cardRadius
  static let cardPadding: CGFloat = 16
  static let innerRadius: CGFloat = 6
}

private struct PanelCardModifier: ViewModifier {
  let padding: CGFloat

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(
        BlitzUI.cardFill,
        in: RoundedRectangle(cornerRadius: PanelMetrics.cardRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: PanelMetrics.cardRadius, style: .continuous)
          .strokeBorder(BlitzUI.separator, lineWidth: 1)
          .allowsHitTesting(false)
      }
  }
}

extension View {
  func panelCard(padding: CGFloat = PanelMetrics.cardPadding) -> some View {
    modifier(PanelCardModifier(padding: padding))
  }
}

struct CapacityBar: View {
  let usedRatio: Double
  let tone: MetricTone

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(BlitzUI.track)
        Capsule()
          .fill(tone == .neutral ? BlitzUI.secondaryText : tone.color)
          .frame(width: max(6, geometry.size.width * min(1, max(0, usedRatio))))
      }
    }
    .frame(height: 6)
    .animation(.easeOut(duration: 0.25), value: usedRatio)
  }
}

/// Ring gauge used by Usage Monitor: accent arc, quiet track, mono figure.
struct UsageDial: View {
  /// 0...1. Nil draws an empty track.
  let ratio: Double?
  var tone: MetricTone = .good
  var size: CGFloat = 36

  private var clamped: Double { min(1, max(0, ratio ?? 0)) }

  private var stroke: Color {
    switch tone {
    case .neutral: BlitzUI.secondaryText
    case .good: BlitzUI.mint
    case .warning: BlitzUI.warning
    case .critical: BlitzUI.recordRed
    }
  }

  var body: some View {
    ZStack {
      Circle().stroke(BlitzUI.track, lineWidth: 3)
      Circle()
        .trim(from: 0, to: ratio == nil ? 0 : clamped)
        .stroke(stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .shadow(color: tone == .good ? BlitzUI.mint.opacity(0.55) : .clear, radius: 3)
      Text(figure)
        .font(.system(size: max(9, size * 0.25), weight: .medium, design: .monospaced))
        .tracking(-0.4)
        .foregroundStyle(BlitzUI.primaryText)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
    }
    .frame(width: size, height: size)
    .accessibilityLabel(ratio.map { PercentText.make($0) } ?? "No reading")
  }

  private var figure: String {
    guard let ratio else { return "—" }
    return (ratio * 100).formatted(.number.precision(.fractionLength(0)))
  }
}

struct UsageDialItem: View {
  let ratio: Double?
  var tone: MetricTone = .good
  var size: CGFloat = 36
  let title: String
  let note: String

  var body: some View {
    HStack(spacing: 6) {
      UsageDial(ratio: ratio, tone: tone, size: size)
      VStack(alignment: .leading, spacing: 1) {
        Text(title).font(BlitzType.body).foregroundStyle(BlitzUI.primaryText).lineLimit(1)
        Text(note).font(BlitzType.caption).foregroundStyle(BlitzUI.secondaryText).lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

enum PercentText {
  static func make(_ ratio: Double) -> String {
    (ratio * 100).formatted(.number.precision(.fractionLength(0))) + "%"
  }
}
