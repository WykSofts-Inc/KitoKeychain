//
//  KitoSecureVaultView.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A secure notes and token vault screen over a `KitoSecureVault`: a header with the item count,
/// kind filters, one card per item whose secret reveals only after Face ID (and hides itself
/// again), an add sheet, and a friendly empty state.
public struct KitoSecureVaultView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var vault: KitoSecureVault
    let title: String
    let gate: KitoRevealGate

    @State private var filter: KitoSecureItem.Kind?
    @State private var isAdding = false
    @State private var pendingDelete: KitoSecureItem?

    public init(vault: KitoSecureVault, title: String = "Vault", gate: KitoRevealGate = .deviceOwner) {
        self.vault = vault
        self.title = title
        self.gate = gate
    }

    private var kindsInUse: [KitoSecureItem.Kind] {
        KitoSecureItem.Kind.allCases.filter { kind in vault.items.contains { $0.kind == kind } }
    }

    private var visibleItems: [KitoSecureItem] {
        vault.items.filter { filter == nil || $0.kind == filter }.sorted { $0.createdAt > $1.createdAt }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                header
                if vault.items.isEmpty {
                    emptyState
                } else {
                    if kindsInUse.count > 1 { filters }
                    LazyVStack(spacing: theme.spacing.md) {
                        ForEach(visibleItems) { item in
                            KitoSecureItemCard(item: item, vault: vault, gate: gate) { pendingDelete = item }
                                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                        }
                    }
                }
                if let error = vault.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.danger)
                }
            }
            .padding(theme.spacing.lg)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: vault.items)
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: filter)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .sheet(isPresented: $isAdding) {
            KitoSecureItemComposer { title, kind, secret, detail in
                vault.add(title, kind: kind, secret: secret, detail: detail)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete \(pendingDelete?.title ?? "item")?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let pendingDelete { vault.delete(pendingDelete) }
                pendingDelete = nil
            }
        } message: {
            Text("It's removed from this device's keychain. This can't be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: theme.spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.24), Color(red: 0.05, green: 0.06, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.55, green: 0.95, blue: 0.80), Color(red: 0.30, green: 0.70, blue: 1.0)], startPoint: .top, endPoint: .bottom))
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.titleLarge.weight(.bold))
                    .foregroundStyle(theme.colors.onBackground)
                Text("\(vault.items.count) \(vault.items.count == 1 ? "item" : "items") · Face ID to reveal")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
            }
            Spacer()
            Button { isAdding = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.colors.background)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(theme.colors.onBackground))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add item")
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                chip("All", symbol: "square.grid.2x2.fill", isOn: filter == nil) { filter = nil }
                ForEach(kindsInUse, id: \.self) { kind in
                    chip(kind.displayName, symbol: kind.systemImage, isOn: filter == kind) { filter = kind }
                }
            }
        }
    }

    private func chip(_ title: String, symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(theme.typography.label)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(Capsule().fill(isOn ? theme.colors.onBackground : theme.colors.onBackground.opacity(0.07)))
                .foregroundStyle(isOn ? theme.colors.background : theme.colors.onBackground)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var emptyState: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                Circle().fill(theme.colors.primary.opacity(0.08)).frame(width: 150, height: 150)
                Circle().stroke(theme.colors.primary.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [5, 6])).frame(width: 120, height: 120)
                Image(systemName: "key.viewfinder")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(theme.colors.primary)
            }
            .accessibilityHidden(true)
            Text("Nothing stored yet")
                .font(theme.typography.titleMedium)
                .foregroundStyle(theme.colors.onBackground)
            Text("Keep recovery codes, PINs and API keys here. They never leave this device's keychain.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                .multilineTextAlignment(.center)
            Button { isAdding = true } label: { Label("Add your first secret", systemImage: "plus") }
                .font(theme.typography.button)
                .foregroundStyle(theme.colors.background)
                .padding(.horizontal, 22)
                .frame(minHeight: 48)
                .background(Capsule().fill(theme.colors.onBackground))
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xxl)
    }
}

/// One vault item: its kind, title and detail, and the revealable secret.
struct KitoSecureItemCard: View {
    @Environment(\.kitoTheme) private var theme
    let item: KitoSecureItem
    let vault: KitoSecureVault
    let gate: KitoRevealGate
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: item.kind.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KitoSecureItemCard.tint(for: item.kind))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(KitoSecureItemCard.tint(for: item.kind).opacity(0.14)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(theme.typography.bodyEmphasized)
                        .foregroundStyle(theme.colors.onSurface)
                    Text(item.detail ?? item.kind.displayName)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                }
                Spacer()
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("More for \(item.title)")
            }
            KitoRevealableSecret(nil, mask: item.kind.defaultMask, gate: gate, reason: "Reveal \(item.title)") {
                vault.secret(for: item)
            }
            .padding(theme.spacing.md)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.colors.surfaceMuted))
        }
        .padding(theme.spacing.lg)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.colors.surface).shadow(color: .black.opacity(0.06), radius: 12, y: 6))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.colors.border.opacity(0.5), lineWidth: 1))
        .contextMenu { Button("Delete", systemImage: "trash", role: .destructive, action: onDelete) }
    }

    static func tint(for kind: KitoSecureItem.Kind) -> Color {
        switch kind {
        case .note: return Color(red: 0.98, green: 0.62, blue: 0.10)
        case .password: return Color(red: 0.36, green: 0.40, blue: 0.95)
        case .token: return Color(red: 0.10, green: 0.62, blue: 0.55)
        case .apiKey: return Color(red: 0.55, green: 0.30, blue: 0.95)
        case .card: return Color(red: 0.10, green: 0.50, blue: 0.95)
        case .pin: return Color(red: 0.93, green: 0.30, blue: 0.40)
        case .recoveryCode: return Color(red: 0.20, green: 0.70, blue: 0.35)
        }
    }
}

/// The add-a-secret sheet.
public struct KitoSecureItemComposer: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, KitoSecureItem.Kind, String, String?) -> Void

    @State private var title = ""
    @State private var kind: KitoSecureItem.Kind = .note
    @State private var secret = ""
    @State private var detail = ""
    @State private var showsSecret = false

    public init(onSave: @escaping (_ title: String, _ kind: KitoSecureItem.Kind, _ secret: String, _ detail: String?) -> Void) {
        self.onSave = onSave
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && !secret.isEmpty }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            HStack {
                Text("New secret").font(theme.typography.titleLarge.weight(.bold))
                Spacer()
                Button("Cancel") { dismiss() }.font(theme.typography.label)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(KitoSecureItem.Kind.allCases, id: \.self) { option in
                        Button { kind = option } label: {
                            Label(option.displayName, systemImage: option.systemImage)
                                .font(theme.typography.label)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 34)
                                .background(Capsule().fill(kind == option ? theme.colors.onSurface : theme.colors.onSurface.opacity(0.07)))
                                .foregroundStyle(kind == option ? theme.colors.surface : theme.colors.onSurface)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            field("Title", text: $title, prompt: "e.g. KRA iTax PIN")
            VStack(alignment: .leading, spacing: 6) {
                Text("Secret").font(theme.typography.caption.weight(.semibold)).foregroundStyle(theme.colors.onSurface.opacity(0.6))
                HStack {
                    Group {
                        if showsSecret {
                            TextField("", text: $secret, prompt: Text("Paste or type it"))
                        } else {
                            SecureField("", text: $secret, prompt: Text("Paste or type it"))
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Button { showsSecret.toggle() } label: { Image(systemName: showsSecret ? "eye.slash" : "eye") }
                        .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                        .accessibilityLabel(showsSecret ? "Hide secret" : "Show secret")
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.colors.surfaceMuted))
            }
            field("Note (not secret)", text: $detail, prompt: "e.g. Renews March")
            Spacer(minLength: 0)
            Button {
                onSave(title.trimmingCharacters(in: .whitespaces), kind, secret, detail.isEmpty ? nil : detail)
                dismiss()
            } label: {
                Label("Save to keychain", systemImage: "lock.fill").frame(maxWidth: .infinity)
            }
            .font(theme.typography.button)
            .foregroundStyle(theme.colors.surface)
            .frame(minHeight: 52)
            .background(Capsule().fill(theme.colors.onSurface.opacity(canSave ? 1 : 0.3)))
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(theme.spacing.xl)
        .background(theme.colors.surface.ignoresSafeArea())
    }

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(theme.typography.caption.weight(.semibold)).foregroundStyle(theme.colors.onSurface.opacity(0.6))
            TextField("", text: text, prompt: Text(prompt))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.colors.surfaceMuted))
        }
    }
}
