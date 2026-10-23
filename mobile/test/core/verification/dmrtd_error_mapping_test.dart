import 'package:dmrtd/dmrtd.dart';
import 'package:dmrtd/internal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/verification/chip/dmrtd_chip_reader.dart';

void main() {
  group('failures outside authentication', () {
    test('Android poll timeout (plugin code 408)', () {
      expect(mapDmrtdError(PlatformException(code: '408', message: 'Polling tag timeout')), ChipFailureKind.timeout);
    });

    test('dmrtd wraps the plugin message', () {
      expect(mapDmrtdError(NfcProviderError('Tag was lost.')), ChipFailureKind.tagLost);
    });

    test('Android IO error while transceiving means the document moved', () {
      expect(mapDmrtdError(PlatformException(code: '500', message: 'Communication error')), ChipFailureKind.tagLost);
    });

    test('iOS lost connection', () {
      expect(mapDmrtdError(NfcProviderError('Tag connection lost')), ChipFailureKind.tagLost);
    });

    test('user closes the iOS sheet', () {
      expect(mapDmrtdError(PlatformException(code: '409', message: 'Session invalidated by user')), ChipFailureKind.cancelled);
    });

    test('no NFC hardware', () {
      expect(mapDmrtdError(PlatformException(code: '404', message: 'NFC not available')), ChipFailureKind.nfcUnavailable);
    });

    test('missing file means an unsupported document', () {
      expect(mapDmrtdError(ICCError('x', StatusWord.fileNotFound, null)), ChipFailureKind.unsupportedDocument);
      expect(mapDmrtdError(PassportError('File not found', code: StatusWord.fileNotFound)), ChipFailureKind.unsupportedDocument);
    });

    test('unparsable card access is an unsupported document', () {
      expect(mapDmrtdError(EfParseError('bad')), ChipFailureKind.unsupportedDocument);
    });

    test('status word 63CF is a refused key even on old passports', () {
      expect(mapDmrtdError(ICCError('x', const StatusWord(sw1: 0x63, sw2: 0xCF), null)), ChipFailureKind.accessDenied);
    });

    test('anything else is unknown', () {
      expect(mapDmrtdError(StateError('boom')), ChipFailureKind.unknown);
    });

    test('a status word containing 408 is not mistaken for a timeout', () {
      expect(mapDmrtdError(ICCError('x', const StatusWord(sw1: 0x64, sw2: 0x08), null)), ChipFailureKind.unknown);
    });
  });

  group('failures during authentication', () {
    test('security status not satisfied is a refused key', () {
      expect(mapDmrtdError(PassportError('Security status not satisfied', code: StatusWord.securityStatusNotSatisfied), authentication: true), ChipFailureKind.accessDenied);
    });

    test('BAC mac mismatch', () {
      expect(mapDmrtdError(BACError('mac mismatch'), authentication: true), ChipFailureKind.accessDenied);
    });

    test('instruction not supported means the chip lacks the protocol', () {
      expect(mapDmrtdError(ICCError('x', StatusWord.invalidInstructionCode, null), authentication: true), ChipFailureKind.unsupportedDocument);
    });

    test('tag lost stays tag lost during authentication', () {
      expect(mapDmrtdError(NfcProviderError('Tag was lost.'), authentication: true), ChipFailureKind.tagLost);
    });
  });
}
