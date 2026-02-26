import 'package:codewalk/presentation/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand palette exposes deterministic labels and seed colors', () {
    expect(BrandColor.values, hasLength(5));
    expect(BrandColor.codewalkBlue.label, 'CodeWalk Blue');
    expect(BrandColor.deepPurple.label, 'Deep Purple');
    expect(BrandColor.codewalkBlue.seed, const Color(0xFF3A6EA5));
    expect(BrandColor.forestGreen.seed, const Color(0xFF386A20));
  });
}
