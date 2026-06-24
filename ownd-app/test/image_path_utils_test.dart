import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/shared/utils/image_path_utils.dart';

void main() {
  test('recognizes service image paths', () {
    expect(isRemoteImagePath('/ownd-items/item.png'), isTrue);
    expect(isRemoteImagePath('https://example.com/item.png'), isTrue);
    expect(isRemoteImagePath(r'C:\images\item.png'), isFalse);
  });

  test('builds image API URL from stored path', () {
    expect(
      imageUrlForPath('/ownd-items/item 1.png'),
      'http://10.0.2.2:3000/api/v1/items/images/item%201.png',
    );
  });
}
