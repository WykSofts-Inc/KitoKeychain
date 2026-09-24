//
//  KitoRevealableSecret.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import KitoCore

/// A masked secret with an eye button: tap it, pass Face ID, and the value un-blurs, then hides
/// itself again after `autoHide` with a countdown ring on the button. Copy puts it on the
/// clipboard for this device only, and the clipboard clears itself after a minute.
public struct KitoRevealableSecret: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let label: String?
    let mask: KitoSecretMask
    let gate: KitoRevealGate
    let reason: String
    let autoHide: Duration
    let copyable: Bool
    let load: () -> String?

    @State private var revealed: String?
    @State private var isChecking = false
    @State private var remaining: Double = 1
    @State private var copied = false
    @State private var hideTask: Task<Void, Never>?
    @State private var denied = false

    /// Reveals a secret read on demand — `load` runs only after the gate passes.
    public init(
        _ label: String? = nil,
        mask: KitoSecretMask = .dots,
        gate: KitoRevealGate = .deviceOwner,
        reason: String = "Reveal your secret",
        autoHide: Duration = .seconds(20),
        copyable: Bool = true,
        load: @escaping () -> String?
    ) {
        self.label = label
        self.mask = mask
        self.gate = gate
        self.reason = reason
        self.autoHide = autoHide
        self.copyable = copyable
        self.load = load
    }

    /// Reveals a value you already hold.
    public init(
        _ label: String? = nil,
        value: String,
        mask: KitoSecretMask = .dots,
        gate: KitoRevealGate = .deviceOwner,
        reason: String = "Reveal your secret",
        autoHide: Duration = .seconds(20),
        copyable: Bool = true
    ) {
        self.init(label, mask: mask, gate: gate, reason: reason, autoHide: autoHide, copyable: copyable, load: { value })
    }

    private var placeholder: String { mask.apply(to: revealed ?? "••••••••••••") }

    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                if let label {
                    Text(label)
                        .font(theme.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                }
                ZStack(alignment: .leading) {
                    Text(revealed ?? placeholder)
                        .font(.system(.body, design: .monospaced).weight(.medium))
                        .foregroundStyle(theme.colors.onSurface)
                        .lineLimit(revealed == nil ? 1 : 3)
                        .blur(radius: revealed == nil && isChecking && !reduceMotion ? 3 : 0)
                        .textSelection(.enabled)
                        .contentTransition(.interpolate)
                        .privacySensitive()
                }
                if copied {
                    Label("Copied · clears in 60s", systemImage: "checkmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.colors.success)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if denied {
                    Text("Couldn't confirm it's you")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.colors.danger)
                        .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
            if copyable, revealed != nil {
                Button(action: copy) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.colors.onSurface.opacity(0.07)))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.colors.onSurface)
                .accessibilityLabel("Copy")
                .transition(.scale.combined(with: .opacity))
            }
            Button(action: toggle) {
                ZStack {
                    Circle().fill(revealed == nil ? theme.colors.onSurface : theme.colors.onSurface.opacity(0.07))
                    if revealed != nil {
                        Circle()
                            .trim(from: 0, to: remaining)
                            .stroke(theme.colors.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(2)
                    }
                    if isChecking {
                        ProgressView().controlSize(.small).tint(theme.colors.surface)
                    } else {
                        Image(systemName: revealed == nil ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(revealed == nil ? theme.colors.surface : theme.colors.onSurface)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(revealed == nil ? "Reveal \(label ?? "secret")" : "Hide \(label ?? "secret")")
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.82), value: revealed)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: copied)
        .onDisappear { hide() }
    }

    private func toggle() {
        if revealed != nil { hide(); return }
        guard !isChecking else { return }
        isChecking = true
        denied = false
        Task {
            let allowed = await gate.authenticate(reason)
            isChecking = false
            guard allowed, let value = load() else {
                denied = !allowed
                return
            }
            revealed = value
            startCountdown()
        }
    }

    private func startCountdown() {
        hideTask?.cancel()
        remaining = 1
        let seconds = Double(autoHide.components.seconds) + Double(autoHide.components.attoseconds) / 1e18
        withAnimation(.linear(duration: max(seconds, 0.1))) { remaining = 0 }
        hideTask = Task {
            try? await Task.sleep(for: autoHide)
            if !Task.isCancelled { hide() }
        }
    }

    private func hide() {
        hideTask?.cancel()
        hideTask = nil
        revealed = nil
        copied = false
    }

    private func copy() {
        guard let revealed else { return }
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: revealed]],
            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
        )
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            copied = false
        }
    }
}
