# TetherStack

A SwiftUI vertical container that distributes a linked horizontal pull across its rows.

## Overview

`TetherVStack` lays out rows like `LazyVStack`. Dragging one row sideways moves it under the finger, and the rows above and below follow with inverse-square falloff, producing a rope-ladder-on-elastic motion. Each row can declare passive reveal content beneath either edge that surfaces as the row is pulled. On release the rows spring back (peek behavior); the reveal content is for glancing, not interaction.

The container does not own a scroll. Place it inside a `ScrollView`; it behaves like `LazyVStack` and reports its height upward.

```swift
import SwiftUI
import TetherStack

ScrollView {
    TetherVStack(spacing: 10) {
        ForEach(items) { item in
            RowView(item)
                .tetherUnderlay(.leading)  { LeadingContent(item) }
                .tetherUnderlay(.trailing) { TrailingContent(item) }
        }
    }
}
```

## Requirements

- iOS 26.0+
- Swift 6.3+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MothyLoff/TetherStack.git", from: "1.0.0")
]
```

Then add `TetherStack` to your target's dependencies. In Xcode, use **File > Add Package Dependencies** and enter the repository URL.

## Usage

### Creating a container

Wrap row views in a `TetherVStack` inside a `ScrollView`. Each top-level view in the content is one row.

```swift
ScrollView {
    TetherVStack(alignment: .center, spacing: 10) {
        ForEach(items) { item in
            RowView(item)
        }
    }
}
```

Rows take their natural width and are positioned by `alignment`, like `LazyVStack`. For full-width rows, apply `.frame(maxWidth: .infinity)` to the row view.

### Adding reveal content

Attach `tetherUnderlay(_:verticalAlignment:content:)` to a row to declare content beneath an edge. The content is revealed as the row is pulled toward that edge. Attach it to both edges independently.

```swift
RowView(item)
    .tetherUnderlay(.leading) {
        Image(systemName: item.isPinned ? "pin.fill" : "pin")
            .foregroundStyle(.secondary)
            .padding(.leading, 24)
    }
    .tetherUnderlay(.trailing, verticalAlignment: .top) {
        Text(item.date, style: .relative)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.trailing, 24)
    }
```

The underlay is passive, peek-only content: it surfaces while the row is held aside and springs back when the pull is released. Use it for glanceable information such as status, metadata, or timestamps — not for interactive controls. The content does not receive taps; there is no committed-action state like `swipeActions`.

Content insets are set with standard modifiers such as `.padding` on the content itself. Edges follow `\.layoutDirection` and mirror automatically in right-to-left layouts.

A row is always pullable to both sides. An edge without an underlay simply has nothing to reveal on that side.

> Note: Use at most one `tetherUnderlay` per edge. Applying it more than once for the same edge is not additive — the underlays do not stack, and a single underlay is used per edge. To combine content, compose it inside one `tetherUnderlay` closure.

## Topics

### Container

```swift
public struct TetherVStack<Content: View>: View

public init(
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content
)
```

- `alignment`: horizontal alignment of rows narrower than the container. Defaults to `.center`.
- `spacing`: spacing between rows. Defaults to `nil`, the system's adaptive spacing, matching `VStack` and `LazyVStack`.
- `content`: the rows. Each top-level view is one row.

### Reveal content

```swift
func tetherUnderlay<Underlay: View>(
    _ edge: HorizontalEdge,
    verticalAlignment: TetherVerticalAlignment = .center,
    @ViewBuilder content: () -> Underlay
) -> some View
```

- `edge`: the reveal side, `.leading` or `.trailing`.
- `verticalAlignment`: vertical alignment of the content within the row's height. Defaults to `.center`.
- `content`: the view revealed beneath the row on that edge.

### Vertical alignment

```swift
public enum TetherVerticalAlignment {
    case top
    case center
    case bottom
}
```

The vertical alignment of underlay content within a row's height. The row's height is set by the front row view.

## License

TetherStack is available under the MIT License (see [LICENSE](LICENSE)). You may use, modify, and distribute it, including in commercial products, provided the copyright notice and license text are retained.

A credit to [@MothyLoff](https://github.com/MothyLoff) in commercial products is appreciated. For terms outside the MIT License, open an issue on the repository.
