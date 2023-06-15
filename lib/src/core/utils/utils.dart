String? getFormattedHtmlText(
  String? value,
) {
  if (value == null) return null;

  return value
      .replaceAllMapped(
        RegExp(r'\\u([0-9a-fA-F]{4})'),
        (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
      )
      .replaceAll(
        "<p>",
        "\n\n",
      )
      .replaceAll(
        "<br>",
        "\n",
      )
      .replaceAll(
        "&quot;",
        "\"",
      )
      .replaceAll(
        "&apos;",
        "'",
      )
      .replaceAll(
        "&lt;",
        ">",
      )
      .replaceAll(
        "&gt;",
        "<",
      )
      .replaceAll(
        "&gt;",
        "<",
      )
      .replaceAll(
        "&#39;",
        "'",
      )
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .trim();
}
