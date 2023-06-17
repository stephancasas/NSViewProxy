///
///  View+NSViewProxy.swift
///
///  Created by Stephan Casas on 6/13/23.
///
///  `NSViewProxyView`, its associated structs, and function extensions on `View`
///  allow you to access the `NSView` and/or `NSWindow`/window members in which a
///  SwiftUI `View` will draw.
///
///  This is an improvement upon other accessor/proxy methods which rely on using
///  `DispatchQueue.main.async(execute:)` to modify content after the first drawcycle.
///
///  `NSViewProxyView` executes any logic given in `NSViewProxy` callbacks *prior*
///  to the first draw of modified SwiftUI `View`s — effectively eliminating any
///  occurrences of FOUC (flash of unstyled content).
///
///  NSViewProxyView is not a Swift package because I haven't figured out how to
///  make those yet.
///

import SwiftUI;
import AppKit;

public extension View {
    
    /// Access the `NSView` in which this Swift UI `View` will draw.
    /// - Parameter using: The callback which will receive the `NSView`.
    func proxy(
        using: @escaping NSViewProxyModifier<NSView>.NSViewProxy
    ) -> some View {
        self.modifier(NSViewProxyModifier(using))
    }
    
    /// Typecast and access the `NSView` in which this Swift UI `View` will draw.
    /// - Parameters:
    ///   - as: The type to which the `NSView` should cast.
    ///   - using: The callback which will receive the typecast `NSView`.
    func proxy<T: NSView>(
        as: T.Type,
        using: @escaping NSViewProxyModifier<T>.NSViewProxy
    ) -> some View {
        self.modifier(NSViewProxyModifier<T>(using))
    }
    
    /// Access an ancestor or descendant `NSView` of this SwiftUI `View`'s `NSView`.
    /// - Parameters:
    ///   - relationship: The relationship describing the `NSView` which should be accessed.
    ///   - proxy: The callback which will receive the targeted `NSView`.
    func proxy<T: NSView>(
        to relationship: NSViewProxyModifier<T>.ViewRelationship,
        using proxy: @escaping NSViewProxyModifier<T>.NSViewProxy
    ) -> some View {
        self.modifier(NSViewProxyModifier(relationship: relationship, proxy))
    }
    
    /// Access the `NSWindow` or a member of the `NSWindow` in which this SwiftUI `View` will draw.
    /// - Parameters:
    ///   - global: The member which should be accessed.
    ///   - proxy: The callback which should receive the member.
    func proxy<T: NSWindow>(
        to global: NSViewProxyModifier.GlobalElement<T>,
        using proxy: @escaping (_ window: T) -> Void
    ) -> some View {
        self.modifier(NSViewProxyModifier<NSView>({ view in
            guard let window = global.rawValue.callback(view) else { return }
            
            proxy(window);
        }))
    }
    
    /// Access the `NSWindow` or a member of the `NSWindow` in which this SwiftUI `View` will draw.
    /// - Parameters:
    ///   - global: The member which should be accessed.
    ///   - proxy: The callback which should receive the member.
    func proxy<T: NSWindowTab>(
        to global: NSViewProxyModifier.GlobalElement<T>,
        using proxy: @escaping (_ tab: T) -> Void
    ) -> some View {
        self.modifier(NSViewProxyModifier<NSView>({ view in
            guard let window = global.rawValue.callback(view) else { return }
            
            proxy(window);
        }))
    }
    
    /// Access the `NSWindow` or a member of the `NSWindow` in which this SwiftUI `View` will draw.
    /// - Parameters:
    ///   - global: The member which should be accessed.
    ///   - proxy: The callback which should receive the member.
    func proxy<T: NSView>(
        to global: NSViewProxyModifier.GlobalElement<T>,
        using proxy: @escaping (_ view: T) -> Void
    ) -> some View {
        self.modifier(NSViewProxyModifier<NSView>({ view in
            guard let view = global.rawValue.callback(view) else {
                return
            }
            
            proxy(view);
        }))
    }
    
    /// Access the `NSWindow` or a member of the `NSWindow` in which this SwiftUI `View` will draw.
    /// - Parameters:
    ///   - global: The member which should be accessed.
    ///   - proxy: The callback which should receive the member.
    func proxy<T: NSToolbar>(
        to global: NSViewProxyModifier.GlobalElement<T>,
        using proxy: @escaping (_ toolbar: T) -> Void
    ) -> some View {
        self.modifier(NSViewProxyModifier<NSView>({ view in
            guard let toolbar = global.rawValue.callback(view) else {
                return
            }
            
            proxy(toolbar);
        }))
    }
    
}

public extension NSViewProxyModifier where TargetView == NSView {
    typealias GlobalElement<T: NSObject> = NSViewProxyModifier<NSView>.GlobalViewRelative<T>;
}

public extension NSViewProxyModifier.GlobalViewRelative {
    
    /// The `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var window: NSViewProxyModifier<NSView>.GlobalViewRelative<NSWindow> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSWindow>(rawValue: (NSWindow.self, { view in
            view.window
        }))
    }
    
}

public extension NSViewProxyModifier.GlobalViewRelative {
    
    /// The uppermost `NSView` in the view hierarchy in which the proxied SwiftUI `View` will draw.
    static var contentView: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>(rawValue: (NSView.self, { view in
            return view.window?.contentView;
        }))
    }
    
    /// The `NSTitlebarView` of the `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var titlebar: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>(
            rawValue: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>.someView(like: /NSTitlebarView/).rawValue
        )
    }
    
    /// The `NSTitlebarContainerView` of the `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var titlebarContainer: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>(
            rawValue: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>.someView(like: /NSTitlebarContainerView/).rawValue
        )
    }
    
    /// The `NSTabBar` of the `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var tabBar: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>(
            rawValue: NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>.someView(like: /NSTabBar/).rawValue
        )
    }
    
    /// The first `NSView` in the view hierarchy of the `NSWindow` in which the proxied SwiftUI `View` will draw
    /// whose type name or debug description matches the given regular expression.
    /// - Parameter regex: The regular expression against which to compare each `NSView` in the hierarchy tree.
    static func someView(like regex: Regex<Substring>) -> NSViewProxyModifier<NSView>.GlobalViewRelative<NSView> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSView>(rawValue: (NSView.self, { view in
            var match: NSView? = nil;
            
            var traverse: (NSView) -> Void = { _ in };
            traverse = { (view: NSView) in
                if match != nil {
                    return;
                }
                
                if view.debugDescription.contains(regex) {
                    match = view;
                    return;
                }
                
                for subview in view.subviews {
                    if subview.debugDescription.contains(regex) {
                        match = subview;
                        return;
                    }
                    traverse(subview);
                }
            }
            
            for subview in (view.window?.contentView?.superview?.subviews ?? []) {
                traverse(subview);
            }
            
            return match;
        }))
    }
}

public extension NSViewProxyModifier.GlobalViewRelative {
    
    /// The `NSToolbar` of the `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var toolbar: NSViewProxyModifier<NSView>.GlobalViewRelative<NSToolbar> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSToolbar>(rawValue: (NSToolbar.self, { view in
            return view.window?.toolbar;
        }))
    }
    
}

public extension NSViewProxyModifier.GlobalViewRelative {
    
    /// The current `NSWindowTab` of the `NSWindow` in which the proxied SwiftUI `View` will draw.
    static var tab: NSViewProxyModifier<NSView>.GlobalViewRelative<NSWindowTab> {
        NSViewProxyModifier<NSView>.GlobalViewRelative<NSWindowTab>(rawValue: (NSWindowTab.self, { view in
            return view.window?.tab;
        }))
    }
    
}

// MARK: - Main View Modifier

public struct NSViewProxyModifier<TargetView: NSView>: ViewModifier {
    
    public struct GlobalViewRelative<T: NSObject>: RawRepresentable {
        public var rawValue: (type: T.Type, callback: (NSView) -> T?);
        public init(rawValue: (type: T.Type, callback: (NSView) -> T?)) {
            self.rawValue = rawValue
        }
    }
    
    // MARK: - Relationships
    
    public struct ViewRelationship: RawRepresentable {
        public var rawValue: (
            relation: Relative,
            distance: Distance,
            condition: RelationshipCondition
        );
        
        public init(rawValue: (relation: Relative, distance: Distance, condition: RelationshipCondition)) {
            self.rawValue = rawValue
        }
        
        public typealias RelationshipCondition = (_ view: NSView) -> Bool;
        
        public enum Distance {
            case closest;
            case furthest;
        }
        
        public enum Relative {
            case ancestor;
            case descendant;
        }
        
        // MARK: - Lazy Relative Matching
        
        public static var ancestor: ViewRelationship {
            .init(rawValue: (
                .ancestor,
                .closest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        public static var descendant: ViewRelationship {
            .init(rawValue: (
                .descendant,
                .closest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        // MARK: - Type-based Matching
        
        /// The first ancestor of the proxied SwiftUI `View` whose type is of the given
        /// represented type.
        /// - Parameter type: The type against which to compare ancestor views.
        public static func ancestor(
            representing type: TargetView.Type = NSView.self
        ) -> ViewRelationship {
            ViewRelationship(rawValue: (
                .ancestor,
                .closest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        /// The first descendant of the proxied SwiftUI `View` whose type is of the given
        /// represented type.
        /// - Parameter type: The type against which to compare descendant views.
        public static func descendant(
            representing type: TargetView.Type = NSView.self
        ) -> ViewRelationship {
            ViewRelationship(rawValue: (
                .descendant,
                .closest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        /// The furthest relative of the given relation of the proxied SwiftUI `View` whose
        /// type is of the given represented type.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - type: The type against which to compare the related views.
        public static func furthest(
            _ relative: Relative,
            representing type: TargetView.Type = NSView.self
        ) -> ViewRelationship {
            ViewRelationship(rawValue: (
                relative,
                .furthest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        /// The closest relative of the given relation of the proxied SwiftUI `View` whose
        /// type is of the given represented type.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - type: The type against which to compare the related views.
        public static func closest(
            _ relative: Relative,
            representing type: TargetView.Type = NSView.self
        ) -> ViewRelationship {
            ViewRelationship(rawValue: (
                relative,
                .closest,
                { view in (view as? TargetView ?? nil) != nil }
            ))
        }
        
        // MARK: - Regex-based Matching
        
        /// The first ancestor of the proxied SwiftUI `View` whose string-represented type
        /// matches the given regular expression.
        /// - Parameter type: The regular expression against which to compare ancestor views.
        public static func ancestor(
            like type: Regex<Substring>
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                .ancestor,
                .closest,
                { view in view.debugDescription.contains(type) }
            ))
        }
        
        /// The first descendant of the proxied SwiftUI `View` whose string-represented type
        /// matches the given regular expression.
        /// - Parameter type: The regular expression against which to compare descendant views.
        public static func descendant(
            like type: Regex<Substring>
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                .descendant,
                .closest,
                { view in view.debugDescription.contains(type) }
            ))
        }
        
        /// The furthest relative of the given relation of the proxied SwiftUI `View` whose
        /// string-represented type matches the given regular expression.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - type: The regular expression against which to compare the related views.
        public static func furthest(
            _ relative: Relative,
            like type: Regex<Substring>
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                relative,
                .furthest,
                { view in view.debugDescription.contains(type) }
            ))
        }
        
        /// The closest relative of the given relation of the proxied SwiftUI `View` whose
        /// string-represented type matches the given regular expression.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - type: The regular expression against which to compare the related views.
        public static func closest(
            _ relative: Relative,
            like type: Regex<Substring>
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                relative,
                .closest,
                { view in view.debugDescription.contains(type) }
            ))
        }
        
        // MARK: - Condition-based Matching
        
        /// The first ancestor of the proxied SwiftUI `View` whose instance passes conditions
        /// evaluated in the given callback.
        /// - Parameter condition: The callback used to evaluate each ancestor view.
        public static func ancestor(
            passing condition: @escaping RelationshipCondition
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                .ancestor,
                .closest,
                condition
            ))
        }
        
        /// The first descendant of the proxied SwiftUI `View` whose instance passes conditions
        /// evaluated in the given callback.
        /// - Parameter condition: The callback used to evaluate each ancestor view.
        public static func descendant(
            passing condition: @escaping RelationshipCondition
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                .descendant,
                .closest,
                condition
            ))
        }
        
        /// The furthest relative of the given relation of the proxied SwiftUI `View` whose
        /// instance passes conditions evaluated in the given callback.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - condition: The callback used to evaluate each related view.
        public static func furthest(
            _ relative: Relative,
            passing condition: @escaping RelationshipCondition
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                relative,
                .furthest,
                condition
            ))
        }
        
        /// The closest relative of the given relation of the proxied SwiftUI `View` whose
        /// instance passes conditions evaluated in the given callback.
        /// - Parameters:
        ///   - relative: The target `NSView`'s relation to the proxied SwiftUI `View`.
        ///   - condition: The callback used to evaluate each related view.
        public static func closest(
            _ relative: Relative,
            passing condition: @escaping RelationshipCondition
        ) -> ViewRelationship where TargetView == NSView {
            ViewRelationship(rawValue: (
                relative,
                .closest,
                condition
            ))
        }
        
    }
    
    // MARK: - View Modifier Members
    
    public typealias NSViewProxy = (_ view: TargetView) -> Void;
    
    private let proxy: NSViewProxy;
    private let relationship: ViewRelationship?;
    
    init(_ proxy: @escaping NSViewProxy) {
        self.proxy = proxy;
        self.relationship = nil;
    }
    
    init(relationship: ViewRelationship, _ proxy: @escaping NSViewProxy) {
        self.proxy = proxy;
        self.relationship = relationship;
    }
    
    public func body(content: Content) -> some View {
        content
            .background(NSViewProxyRepresentative(
                self.proxy,
                self.relationship))
    }
    
    // MARK: - NSViewProxyRepresentative (SwiftUI Wrapper)
    
    struct NSViewProxyRepresentative: NSViewRepresentable {
        
        private let proxy: NSViewProxy;
        private let relationship: ViewRelationship?;
        
        init(
            _ proxy: @escaping NSViewProxy,
            _ relationship: ViewRelationship?
        ) {
            self.proxy = proxy;
            self.relationship = relationship;
        }
        
        func makeNSView(context: Context) -> NSViewProxyView {
            let view = NSViewProxyView();
            
            view.proxy = self.proxy;
            if let relationship = self.relationship {
                view.relationship = relationship;
                view.canReturnSubjectEnvelope = false;
            }
            
            view.setAccessibilityHidden(true);
            
            return view;
        }
        
        func updateNSView(_ nsView: NSViewProxyView, context: Context) { }
        
        // MARK: - NSViewProxyView (Lifecycle)
        
        class NSViewProxyView: NSView {
            
            var proxyEnvelope: NSView? = nil;
            
            var preDrawStash: TargetView? = nil;
            
            var proxy: NSViewProxy = { _ in };
            
            var canReturnSubjectEnvelope = true;
            
            var relationship = ViewRelationship(rawValue: (
                relation: .descendant,
                distance: .closest,
                condition: { view in (view as? TargetView ?? nil) != nil }
            ));
            
            override func viewWillMove(toSuperview newSuperview: NSView?) {
                super.viewWillMove(toSuperview: newSuperview);
                
                if self.proxyEnvelope != nil {
                    return;
                }
                
                guard let superview = newSuperview else {
                    return;
                }
                
                /// The first time this function calls, it will be for the
                /// envelope/wrapper `NSView` applied by SwiftUI.
                ///
                /// We need to capture this so that we can identify it among
                /// sibling views.
                ///
                self.proxyEnvelope = superview;
            }
            
            /// The outermost system `NSView` of the proxied `SwiftUI.View`.
            ///
            private var subjectEnvelope: NSView? {
                guard let proxyEnvelope = self.proxyEnvelope else {
                    return nil;
                }
                
                guard let subjectEnvelope = proxyEnvelope.superview else {
                    return nil;
                }
                
                return subjectEnvelope;
            }
            
            override func viewWillDraw() {
                super.viewWillDraw();
                
                guard let subjectEnvelope = self.subjectEnvelope else {
                    return;
                }
                
                switch self.relationship.rawValue.relation {
                case .ancestor:
                    return self.ascend(
                        into: subjectEnvelope);
                case .descendant:
                    return self.descend(
                        into: subjectEnvelope.subviews)
                }
            }
            
            private func subjectDistance(
                from relative: ViewRelationship.Relative,
                _ view: NSView
            ) -> Int {
                var distance = 0;
                
                switch relative {
                case .ancestor:
                    var superview = self.subjectEnvelope;
                    while superview != view {
                        distance += 1;
                        superview = superview?.superview;
                    }
                case .descendant:
                    var superview = view.superview;
                    while superview != self.subjectEnvelope {
                        distance += 1;
                        superview = superview?.superview;
                    }
                }
                
                return distance;
            }
            
            private func descend(into subviews: [NSView]) {
                for subview in subviews {
                    // Typecast (for non-generic proxies)
                    guard let subview = subview as? TargetView else {
                        self.descend(into: subview.subviews);
                        continue;
                    }
                    
                    // Condition Test
                    if !self.relationship.rawValue.condition(subview) {
                        self.descend(into: subview.subviews);
                        continue;
                    }
                    
                    switch self.relationship.rawValue.distance {
                    case .closest: // Fire as soon as tripped.
                        return self.proxy(subview);
                    case .furthest: // Fire after traversal.
                        var overwrite = true;
                        if let existing = self.preDrawStash {
                            overwrite = self.subjectDistance(
                                from: .descendant, subview
                            ) >= self.subjectDistance(
                                from: .descendant, existing);
                        }
                        
                        if overwrite {
                            self.preDrawStash = subview;
                        }
                        
                        // Continue recursion until done.
                        self.descend(into: subview.subviews);
                    }
                }
                
                if let target = self.preDrawStash {
                    self.proxy(target);
                }
            }
            
            private func ascend(into view: NSView) {
                guard let superview = view.superview else {
                    return;
                }
                
                // Typecast (for non-generic proxies)
                guard let superview = superview as? TargetView else {
                    self.ascend(into: superview);
                    return;
                }
                
                // Condition Test
                if !self.relationship.rawValue.condition(superview) {
                    self.ascend(into: superview);
                    return;
                }
                
                switch self.relationship.rawValue.distance {
                case .closest: // Fire as soon as tripped.
                    return self.proxy(superview);
                case .furthest:
                    var overwrite = true;
                    if let existing = self.preDrawStash {
                        overwrite = self.subjectDistance(
                            from: .ancestor, superview
                        ) >= self.subjectDistance(
                            from: .ancestor, existing);
                    }
                    
                    if overwrite {
                        self.preDrawStash = superview;
                    }
                    
                    // Continue recursion until done.
                    self.ascend(into: superview);
                }
                
                if let target = self.preDrawStash {
                    self.proxy(target);
                }
            }
            
            
        }
        
    }
    
}

