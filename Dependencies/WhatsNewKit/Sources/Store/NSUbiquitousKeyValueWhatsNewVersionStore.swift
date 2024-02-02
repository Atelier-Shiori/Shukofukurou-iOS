import Foundation

/// The CloudKitWhatsNewVersionStore typealias representing a NSUbiquitousKeyValueWhatsNewVersionStore
public typealias CloudKitWhatsNewVersionStore = NSUbiquitousKeyValueWhatsNewVersionStore

// MARK: - NSUbiquitousKeyValueWhatsNewVersionStore

/// A NSUbiquitousKeyValue WhatsNewVersionStore
public struct NSUbiquitousKeyValueWhatsNewVersionStore {
    
    // MARK: Properties
    
    /// The NSUbiquitousKeyValueStore
    private let ubiquitousKeyValueStore: NSUbiquitousKeyValueStore
    
    // MARK: Initializer
    
    /// Creates a new instance of `NSUbiquitousKeyValueWhatsNewVersionStore`
    /// - Parameters:
    ///   - ubiquitousKeyValueStore: The NSUbiquitousKeyValueWhatsNewVersionStore. Default value `.default`
    public init(
        ubiquitousKeyValueStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.ubiquitousKeyValueStore = ubiquitousKeyValueStore
    }
    
}

// MARK: - WriteableWhatsNewVersionStore

extension NSUbiquitousKeyValueWhatsNewVersionStore: WriteableWhatsNewVersionStore {
    
    /// Save presented WhatsNew Version
    /// - Parameter version: The presented WhatsNew Version that should be saved
    public func save(
        presentedVersion version: WhatsNew.Version
    ) {
        self.ubiquitousKeyValueStore.set(
            version.description,
            forKey: version.key
        )
    }
    
}

// MARK: - ReadableWhatsNewVersionStore

extension NSUbiquitousKeyValueWhatsNewVersionStore: ReadableWhatsNewVersionStore {
    
    /// The WhatsNew Versions that have been already been presented
    public var presentedVersions: [WhatsNew.Version] {
        self.ubiquitousKeyValueStore
            .dictionaryRepresentation
            .filter { $0.key.starts(with: WhatsNew.Version.keyPrefix) }
            .compactMap { $0.value as? String }
            .map(WhatsNew.Version.init)
    }
    
}

// MARK: - Remove

public extension NSUbiquitousKeyValueWhatsNewVersionStore {
    
    /// Remove presented WhatsNew Version
    /// - Parameter version: The presented WhatsNew Version that should be removed
    func remove(
        presentedVersion version: WhatsNew.Version
    ) {
        self.ubiquitousKeyValueStore
            .removeObject(forKey: version.key)
    }
    
}

// MARK: - Remove all

public extension NSUbiquitousKeyValueWhatsNewVersionStore {
    
    /// Remove all presented Versions
    func removeAll() {
        self.presentedVersions
            .map(\.key)
            .forEach(self.ubiquitousKeyValueStore.removeObject)
    }
    
}
