import Foundation

/// Decides whether this watchOS build may be modified at all.
///
/// A build is supported only when it is watchOS 27 and its exact build number
/// has a verified MobileGestalt layout in the bundled `MGOffsets.plist`.
/// Anything else (a newer beta, a point release nobody has analyzed yet)
/// is treated as unsupported and every MobileGestalt write is blocked.
struct WatchOSSupport {
    static let supportedMajorVersion = 27

    let version: String
    let build: String
    let isSupported: Bool

    static let current = WatchOSSupport()

    private init() {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        version = os.patchVersion == 0
            ? "\(os.majorVersion).\(os.minorVersion)"
            : "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        build = Self.currentBuild() ?? "?"
        isSupported = os.majorVersion == Self.supportedMajorVersion
            && Self.knownBuilds().contains(build)
    }

    /// The same value BQCore uses to look up its offsets (`kern.osversion`).
    private static func currentBuild() -> String? {
        var size = 0
        guard sysctlbyname("kern.osversion", nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.osversion", &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private static func knownBuilds() -> Set<String> {
        guard let url = Bundle.main.url(forResource: "MGOffsets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let builds = plist["Builds"] as? [String: Any] else { return [] }
        return Set(builds.keys)
    }
}
