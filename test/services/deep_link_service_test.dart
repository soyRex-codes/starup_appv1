import 'package:flutter_test/flutter_test.dart';
// import 'package:app_links/app_links.dart';

// We just test the static logic helper_normalizeSegments from DeepLinkService
// Since _normalizeSegments is private, we will create a small wrapper or test public handle logic
// But since handleIncomingLink depends on context/nav, we'll verify URI parsing logic by replicating the scheme check logic
// or accessing any public logic.
// Actually, `generatePostLink` and `generateProfileLink` are public and testable.

import 'package:foundervers/services/deep_link_service.dart';

void main() {
  group('DeepLinkService Utility', () {
    const host = 'foundervers.com';

    test('generatePostLink creates correct URL', () {
      final link = DeepLinkService.generatePostLink(123);
      expect(link, contains('https://$host/posts/123'));
      expect(link, contains('utm_source=app'));
    });

    test('generatePostLink includes referrer', () {
      final link = DeepLinkService.generatePostLink(123, userId: 'user-abc');
      expect(link, contains('ref=user-abc'));
    });

    test('generateProfileLink creates correct URL', () {
      final link = DeepLinkService.generateProfileLink('user-123');
      expect(link, contains('https://$host/profile/user-123'));
    });

    // To test parsing logic without mocking the whole app, we'd essentially be testing Uri.parse
    // but let's verifying our expected URL structure matches standard URI parsing
    test('standard URI parsing works for our scheme', () {
      final uri = Uri.parse('https://foundervers.com/posts/123');
      expect(uri.pathSegments[0], 'posts');
      expect(uri.pathSegments[1], '123');
    });

    test('custom scheme URI parsing', () {
      // scheme://host/path -> foundervers://posts/123
      // DeepLinkService logic treats host as first segment for custom schemes if path is not empty?
      // Actually standard: foundervers://posts/123 -> host=posts, path=/123 ?
      // No: URL 'foundervers://posts/123'. 
      // host=posts. pathSegments=['123']. 
      
      final uri = Uri.parse('foundervers://posts/123');
      // If logic is:
      // if (link.host.isNotEmpty) segments.add(link.host); // 'posts'
      // segments.addAll(link.pathSegments); // ['123']
      // Result: ['posts', '123']. Correct.
      expect(uri.host, 'posts');
      expect(uri.pathSegments, ['123']);
    });
  });
}
