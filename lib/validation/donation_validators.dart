final _titleWhitespacePattern = RegExp(r'\s+', unicode: true);
final _htmlTagPattern = RegExp(
  r'</?[a-z][^<>]*>',
  caseSensitive: false,
  unicode: true,
);
final _fencedCodePattern = RegExp(r'```', unicode: true);
final _markdownImagePattern = RegExp(
  r'!\[[^\]\r\n]*\]\([^\r\n)]+\)',
  unicode: true,
);
final _markdownLinkPattern = RegExp(
  r'(?<!!)\[[^\]\r\n]+\]\([^\r\n)]+\)',
  unicode: true,
);
final _markdownHeadingPattern = RegExp(
  r'^\s{0,3}#{1,6}\s+\S',
  multiLine: true,
  unicode: true,
);
final _markdownQuotePattern = RegExp(
  r'^\s{0,3}>\s+\S',
  multiLine: true,
  unicode: true,
);

String normalizeDonationTitle(String value) =>
    value.trim().replaceAll(_titleWhitespacePattern, ' ');

bool _isPlainDonationDescription(String value) =>
    !_htmlTagPattern.hasMatch(value) &&
    !_fencedCodePattern.hasMatch(value) &&
    !_markdownImagePattern.hasMatch(value) &&
    !_markdownLinkPattern.hasMatch(value) &&
    !_markdownHeadingPattern.hasMatch(value) &&
    !_markdownQuotePattern.hasMatch(value);

String? validateDonationTitle(String? value) {
  final normalized = normalizeDonationTitle(value ?? '');
  if (normalized.length < 5) {
    return 'El título debe tener al menos 5 caracteres.';
  }
  if (normalized.length > 100) {
    return 'El título no puede superar 100 caracteres.';
  }
  return null;
}

String? validateDonationDescription(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.length < 20) {
    return 'La descripción debe tener al menos 20 caracteres.';
  }
  if (normalized.length > 1000) {
    return 'La descripción no puede superar 1000 caracteres.';
  }
  if (!_isPlainDonationDescription(normalized)) {
    return 'Escribe la descripción como texto simple, sin etiquetas, enlaces ni formatos especiales.';
  }
  return null;
}

String? validateDonationCategory(int? value) =>
    value == null ? 'Selecciona una categoría.' : null;
