/// Provides immutable storage and comparison of semantic-like version numbers,
/// extended to handle additional numeric components and flexible parsing.
///
/// This [Version] class is designed to parse and compare a wide range of version strings,
/// from strict Semantic Versioning (SemVer) like "1.2.3-alpha.1+build.456" to the
/// multi-part numeric versions commonly seen in large applications like WhatsApp,
/// Facebook, and Google (e.g., "2.25.18.80", "519.0.0.44.92", "3.122.764106578.release").
///
/// It offers flexible parsing to extract major, minor, patch, and any additional
/// numeric components, defaulting missing parts to `0`. It also supports standard
/// SemVer pre-release and build metadata, while gracefully ignoring other non-numeric
/// tags in the core version string.
///
/// The class implements [Comparable], allowing for robust comparison using operators
/// (<, <=, ==, >=, >) and sorting. Comparison follows a strict precedence based on
/// numeric components and SemVer rules for pre-release identifiers, ignoring build metadata.
///
/// Additionally, it provides methods for incrementing major, minor, patch, and
/// pre-release versions, and a canonical `toString()` representation.
class Version implements Comparable<Version> {
  // Regex to identify the main version core, optional pre-release, and optional build metadata.
  // This regex is designed to capture the core numeric part, and then separately
  // the pre-release (starting with -) and build (starting with +) sections.
  // Any other non-numeric parts in the core will be handled by splitting and filtering.
  static final RegExp _fullVersionRegex =
      RegExp(r"^(.*?)(?:-([0-9A-Za-z\-.]+))?(?:\+([0-9A-Za-z\-.]+))?$");

  // Regex for validating individual pre-release segments (e.g., "alpha", "1")
  static final RegExp _preReleaseSegmentRegex = RegExp(r"^[0-9A-Za-z\-]+$");

  // Regex for validating build metadata (e.g., "build.info", "001")
  static final RegExp _buildRegex = RegExp(r"^[0-9A-Za-z\-.]+$");

  /// The major number of the version.
  final int major;

  /// The minor number of the version.
  final int minor;

  /// The patch number of the version.
  final int patch;

  /// Additional numeric components beyond major.minor.patch.
  /// For example, in "2.25.18.80", `additionalComponents` would be `[80]`.
  /// In "519.0.0.44.92", `additionalComponents` would be `[44, 92]`.
  final List<int> additionalComponents;

  /// Pre-release information (e.g., "alpha.1"). Does not include the leading hyphen.
  final String preRelease;

  /// Build information (e.g., "001"). Does not include the leading plus sign.
  final String build;

  /// Indicates that the version is a pre-release. Returns true if preRelease is not empty.
  bool get isPreRelease => preRelease.isNotEmpty;

  /// Creates a new instance of [Version].
  ///
  /// [major], [minor], and [patch] are required and must be non-negative.
  /// [additionalComponents] is an optional list of non-negative integers for extra version segments.
  /// [preRelease] is optional, but if specified, must be a string containing only [0-9A-Za-z-]
  ///   and dot-separated segments (e.g., "alpha.1").
  /// [build] is optional, but if specified, must be a string containing only [0-9A-Za-z-.]
  ///   (e.g., "build.info").
  ///
  /// Throws a [FormatException] if string content violates character constraints.
  /// Throws an [ArgumentError] if numeric components are negative.
  Version(
    this.major,
    this.minor,
    this.patch, {
    this.additionalComponents = const <int>[],
    this.preRelease = "",
    this.build = "",
  }) {
    if (major < 0 || minor < 0 || patch < 0) {
      throw ArgumentError(
          "Major, minor, and patch numbers must be non-negative.");
    }
    if (additionalComponents.any((c) => c < 0)) {
      throw ArgumentError("Additional components must be non-negative.");
    }

    if (preRelease.isNotEmpty) {
      for (var segment in preRelease.split('.')) {
        if (segment.trim().isEmpty) {
          throw ArgumentError("Pre-release segments must not be empty.");
        }
        if (!_preReleaseSegmentRegex.hasMatch(segment)) {
          throw FormatException(
              "Pre-release segments must only contain [0-9A-Za-z-]. Invalid segment: '$segment'");
        }
      }
    }

    if (build.isNotEmpty && !_buildRegex.hasMatch(build)) {
      throw FormatException("Build metadata must only contain [0-9A-Za-z-.].");
    }
  }

  @override
  int get hashCode => toString().hashCode;

  /// Determines whether the left-hand [Version] represents a lower precedence than the right-hand [Version].
  bool operator <(covariant Version o) => _compare(this, o) < 0;

  /// Determines whether the left-hand [Version] represents an equal or lower precedence than the right-hand [Version].
  bool operator <=(covariant Version o) => _compare(this, o) <= 0;

  /// Determines whether the left-hand [Version] represents an equal precedence to the right-hand [Version].
  @override
  bool operator ==(covariant Version o) => _compare(this, o) == 0;

  /// Determines whether the left-hand [Version] represents a greater precedence than the right-hand [Version].
  bool operator >(covariant Version o) => _compare(this, o) > 0;

  /// Determines whether the left-hand [Version] represents an equal or greater precedence than the right-hand [Version].
  bool operator >=(covariant Version o) => _compare(this, o) >= 0;

  @override
  int compareTo(Version other) {
    return _compare(this, other);
  }

  /// Creates a new [Version] with the [major] version number incremented.
  ///
  /// Also resets the [minor], [patch], and [additionalComponents] numbers to 0,
  /// and clears the [preRelease] and [build] information.
  Version incrementMajor() => Version(major + 1, 0, 0,
      additionalComponents: [], preRelease: "", build: "");

  /// Creates a new [Version] with the [minor] version number incremented.
  ///
  /// Also resets the [patch] and [additionalComponents] numbers to 0,
  /// and clears the [preRelease] and [build] information.
  Version incrementMinor() => Version(major, minor + 1, 0,
      additionalComponents: [], preRelease: "", build: "");

  /// Creates a new [Version] with the [patch] version number incremented.
  ///
  /// Also resets the [additionalComponents] to empty,
  /// and clears the [preRelease] and [build] information.
  Version incrementPatch() => Version(major, minor, patch + 1,
      additionalComponents: [], preRelease: "", build: "");

  /// Creates a new [Version] with the right-most numeric [preRelease] segment incremented.
  /// If no numeric segment is found, one will be added with the value "1".
  ///
  /// If this [Version] is not a pre-release version, an [ArgumentError] will be thrown.
  Version incrementPreRelease() {
    if (!isPreRelease) {
      throw ArgumentError(
          "Cannot increment pre-release on a non-pre-release Version. "
          "Consider adding an initial pre-release tag (e.g., 'alpha.1') first.");
    }
    final List<String> preReleaseSegments = preRelease.split('.');
    bool foundNumeric = false;

    for (int i = preReleaseSegments.length - 1; i >= 0; i--) {
      final String segment = preReleaseSegments[i];
      if (_isNumeric(segment)) {
        final int intVal = int.parse(segment);
        preReleaseSegments[i] = (intVal + 1).toString();
        foundNumeric = true;
        break;
      }
    }

    if (!foundNumeric) {
      preReleaseSegments.add("1");
    }

    return Version(
      major,
      minor,
      patch,
      additionalComponents: additionalComponents,
      preRelease: preReleaseSegments.join('.'),
      build: "", // Clear build info as per SemVer when incrementing pre-release
    );
  }

  /// Returns a [String] representation of the [Version].
  ///
  /// Uses the format "$major.$minor.$patch".
  /// If [additionalComponents] exist, they are appended as ".component1.component2".
  /// If [preRelease] has segments available they are appended as "-segmentOne.segmentTwo".
  /// If [build] is specified, it is appended as "+build.info".
  @override
  String toString() {
    final StringBuffer output = StringBuffer("$major.$minor.$patch");
    if (additionalComponents.isNotEmpty) {
      output.write(".${additionalComponents.join('.')}");
    }
    if (preRelease.isNotEmpty) {
      output.write("-$preRelease");
    }
    if (build.isNotEmpty) {
      output.write("+$build");
    }
    return output.toString();
  }

  /// Creates a [Version] instance from a string.
  ///
  /// This parser is flexible:
  /// - It extracts major, minor, patch, and any additional numeric components.
  /// - Missing numeric components default to 0.
  /// - It correctly identifies SemVer-style pre-release (e.g., `-alpha.1`) and build (`+build.info`).
  /// - Any other non-numeric segments in the core version string (e.g., `.release` in `3.122.764106578.release`)
  ///   are ignored as "tags" as per the requirement.
  ///
  /// Throws [FormatException] if the string is empty or cannot be parsed.
  static Version parse(String versionString) {
    if (versionString.trim().isEmpty) {
      throw FormatException("Cannot parse empty string into version.");
    }

    final Match? fullMatch = _fullVersionRegex.firstMatch(versionString);
    if (fullMatch == null) {
      throw FormatException(
          "Not a properly formatted version string: '$versionString'");
    }

    String coreString = fullMatch.group(1)!;
    String preReleasePart = fullMatch.group(2) ?? "";
    String buildPart = fullMatch.group(3) ?? "";

    // Process the core string to extract numeric components
    final List<int> numericComponents = [];
    final List<String> coreSegments = coreString.split('.');

    for (String segment in coreSegments) {
      final int? num = int.tryParse(segment);
      if (num != null) {
        numericComponents.add(num);
      } else {
        // If it's not a number, and not part of pre-release/build already captured,
        // it's considered an "ignored tag" as per requirement. Stop processing numeric parts.
        break;
      }
    }

    int major = numericComponents.isNotEmpty ? numericComponents[0] : 0;
    int minor = numericComponents.length > 1 ? numericComponents[1] : 0;
    int patch = numericComponents.length > 2 ? numericComponents[2] : 0;

    List<int> additional = [];
    if (numericComponents.length > 3) {
      additional = numericComponents.sublist(3);
    }

    return Version(
      major,
      minor,
      patch,
      additionalComponents: additional,
      preRelease: preReleasePart,
      build: buildPart,
    );
  }

  /// Tries to create a [Version] instance from a string.
  /// Returns `null` if the string does not conform to any parsable format.
  static Version? tryParse(String versionString) {
    try {
      return Version.parse(versionString);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  // Internal comparison logic
  static int _compare(Version a, Version b) {
    // Compare major, minor, patch
    if (a.major != b.major) return a.major.compareTo(b.major);
    if (a.minor != b.minor) return a.minor.compareTo(b.minor);
    if (a.patch != b.patch) return a.patch.compareTo(b.patch);

    // Compare additional components
    final int maxAdditionalLen =
        a.additionalComponents.length > b.additionalComponents.length
            ? a.additionalComponents.length
            : b.additionalComponents.length;

    for (int i = 0; i < maxAdditionalLen; i++) {
      final int aComp =
          i < a.additionalComponents.length ? a.additionalComponents[i] : 0;
      final int bComp =
          i < b.additionalComponents.length ? b.additionalComponents[i] : 0;
      if (aComp != bComp) return aComp.compareTo(bComp);
    }

    // Compare pre-release (SemVer rules)
    if (a.isPreRelease && !b.isPreRelease) {
      return -1; // A is pre-release, B is not, so A < B
    }
    if (!a.isPreRelease && b.isPreRelease) {
      return 1; // A is not pre-release, B is, so A > B
    }
    if (a.isPreRelease && b.isPreRelease) {
      final List<String> aPreReleaseSegments = a.preRelease.split('.');
      final List<String> bPreReleaseSegments = b.preRelease.split('.');

      final int maxPreReleaseLen =
          aPreReleaseSegments.length > bPreReleaseSegments.length
              ? aPreReleaseSegments.length
              : bPreReleaseSegments.length;

      for (int i = 0; i < maxPreReleaseLen; i++) {
        // If one has fewer pre-release identifiers, it has lower precedence
        if (bPreReleaseSegments.length <= i)
          return 1; // B ran out of segments, A is longer, so A > B
        if (aPreReleaseSegments.length <= i)
          return -1; // A ran out of segments, B is longer, so A < B

        final String aSegment = aPreReleaseSegments[i];
        final String bSegment = bPreReleaseSegments[i];

        final bool aNumeric = _isNumeric(aSegment);
        final bool bNumeric = _isNumeric(bSegment);

        if (aNumeric && bNumeric) {
          final int aNum = int.parse(aSegment);
          final int bNum = int.parse(bSegment);
          if (aNum != bNum) {
            return aNum.compareTo(bNum);
          }
        } else if (!aNumeric && bNumeric) {
          return 1; // Non-numeric has higher precedence than numeric (e.g., "alpha" > "1")
        } else if (aNumeric && !bNumeric) {
          return -1; // Numeric has lower precedence than non-numeric (e.g., "1" < "alpha")
        } else {
          // Both are non-numeric, compare alphabetically
          final int comparison = aSegment.compareTo(bSegment);
          if (comparison != 0) {
            return comparison;
          }
        }
      }
    }

    // Build metadata does not affect precedence, so if all else is equal, versions are equal.
    return 0;
  }

  // Helper to check if a string segment is purely numeric
  static bool _isNumeric(String s) {
    return int.tryParse(s) != null;
  }
}
