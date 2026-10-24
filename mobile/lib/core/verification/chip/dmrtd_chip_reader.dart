// The only file that imports `dmrtd` (LGPL-3.0 / commercial licence). Anything
// else talks to [ChipReader]; swapping the library means rewriting this file.
import 'dart:typed_data';

import 'package:dmrtd/dmrtd.dart';
import 'package:dmrtd/internal.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../models/verification.dart';
import '../mrz/mrz_data.dart';
import 'chip_read_procedure.dart';
import 'chip_reader.dart';

/// [ChipReader] backed by dmrtd (PACE, then BAC).
class DmrtdChipReader implements ChipReader {
  const DmrtdChipReader();

  @override
  Future<NfcAvailability> availability() async {
    try {
      return switch (await NfcProvider.nfcStatus) {
        NfcStatus.enabled => NfcAvailability.available,
        NfcStatus.disabled => NfcAvailability.disabled,
        NfcStatus.notSupported => NfcAvailability.unsupported,
      };
    } on Object {
      return NfcAvailability.unsupported;
    }
  }

  @override
  Future<ChipReadResult> read(
    MrzData mrz, {
    required ChipAlertTexts alerts,
    void Function(ChipReadProgress progress)? onProgress,
  }) => readChipFiles(DmrtdLink(), mrz, alerts: alerts, onProgress: onProgress);
}

/// dmrtd implementation of [EmrtdLink]. Uses [MrtdApi] directly: the higher
/// level `Passport` parses every file and would fail on layouts it does not
/// know, whereas the server only needs the raw bytes.
class DmrtdLink implements EmrtdLink {
  static const _pollTimeout = Duration(seconds: 30);

  final NfcProvider _nfc = NfcProvider();
  MrtdApi? _api;
  EfCardAccess? _cardAccess;
  bool _applicationSelected = false;

  MrtdApi get _session => _api ?? (throw const ChipReadException(ChipFailureKind.unknown));

  @override
  Future<void> connect(String alertMessage) async {
    await _guard(() => _nfc.connect(timeout: _pollTimeout, iosAlertMessage: alertMessage));
    // dmrtd silently drops tags that are not ISO 7816 (e.g. a transport card).
    if (!_nfc.isConnected()) throw const ChipReadException(ChipFailureKind.unsupportedDocument);
    _api = MrtdApi(_nfc);
  }

  @override
  Future<void> setAlertMessage(String message) => _nfc.setIosAlertMessage(message);

  @override
  Future<bool> readCardAccess() async {
    try {
      await _guard(() async {
        await _session.selectMasterFile();
        _applicationSelected = false;
        _cardAccess = EfCardAccess.fromBytes(await _session.readFileBySFI(EfCardAccess.SFI));
      });
      return _cardAccess?.isPaceInfoSet ?? false;
    } on ChipReadException catch (e) {
      // No EF.CardAccess (or an unreadable one): the chip is BAC-only.
      if (e.kind == ChipFailureKind.unsupportedDocument) return false;
      rethrow;
    }
  }

  @override
  Future<void> startPace(MrzData mrz) => _guard(() async {
        final cardAccess = _cardAccess;
        if (cardAccess == null) throw const ChipReadException(ChipFailureKind.unsupportedDocument);
        await _session.initSessionViaPACE(_key(mrz, pace: true), cardAccess);
        await _selectApplication();
      }, authentication: true);

  @override
  Future<void> startBac(MrzData mrz) => _guard(() async {
        _applicationSelected = false;
        await _selectApplication();
        await _session.initSessionViaBAC(_key(mrz, pace: false));
      }, authentication: true);

  @override
  Future<Uint8List> readDg1() => _readFile(EfDG1.SFI);

  @override
  Future<Uint8List> readDg2() => _readFile(EfDG2.SFI);

  @override
  Future<Uint8List> readSod() => _readFile(EfSOD.SFI);

  @override
  Future<void> disconnect({String? success, String? failure}) =>
      _guard(() => _nfc.disconnect(iosAlertMessage: success, iosErrorMessage: failure));

  DBAKey _key(MrzData mrz, {required bool pace}) =>
      DBAKey(mrz.documentNumber, mrz.birthDate(), mrz.expiryDate(), paceMode: pace);

  Future<void> _selectApplication() async {
    if (_applicationSelected) return;
    await _session.selectEMrtdApplication();
    _applicationSelected = true;
  }

  Future<Uint8List> _readFile(int sfi) async {
    late Uint8List bytes;
    await _guard(() async {
      await _selectApplication();
      bytes = await _session.readFileBySFI(sfi);
    });
    return bytes;
  }

  Future<T> _guard<T>(Future<T> Function() action, {bool authentication = false}) async {
    try {
      return await action();
    } on ChipReadException {
      rethrow;
    } on Object catch (e) {
      throw ChipReadException(mapDmrtdError(e, authentication: authentication));
    }
  }
}

// Wording the NFC plugins put in their errors, matched on the lower-cased text.
// Detection patterns, never shown to the member.
final _cancelledMessage = RegExp(r'cancel|invalidated by user|session invalidated');
final _timeoutMessage = RegExp(r'timeout|timed out');
final _noNfcMessage = RegExp(r'nfc not available|not supported by this device');
final _nfcOffMessage = RegExp(r'nfc is disabled|nfc disabled|nfc is off');
final _tagLostMessage = RegExp(r'tag was lost|tag lost|connection lost|communication error|ioexception');
final _notSupportedMessage = RegExp(r'not supported');
final _paceTypeName = RegExp(r'PACE|Pace');

/// Maps whatever dmrtd, its NFC plugin or the platform throws to a typed
/// failure. Only the error's type and message are inspected, never any data.
///
/// [authentication] is true while establishing the PACE / BAC channel: a
/// refusal there means the MRZ data does not match the document.
ChipFailureKind mapDmrtdError(Object error, {bool authentication = false}) {
  final text = _describe(error).toLowerCase();
  if (error is PlatformException && error.code == '408') return ChipFailureKind.timeout;

  if (_cancelledMessage.hasMatch(text)) return ChipFailureKind.cancelled;
  if (_timeoutMessage.hasMatch(text)) return ChipFailureKind.timeout;
  if (_noNfcMessage.hasMatch(text)) return ChipFailureKind.nfcUnavailable;
  if (_nfcOffMessage.hasMatch(text)) return ChipFailureKind.nfcDisabled;
  if (_tagLostMessage.hasMatch(text)) return ChipFailureKind.tagLost;

  if (error is ICCError || error is PassportError) {
    final sw = error is ICCError ? error.sw : (error as PassportError).code;
    return _fromStatusWord(sw, authentication);
  }
  final type = error.runtimeType.toString();
  if (authentication) {
    if (error is BACError || _paceTypeName.hasMatch(type)) {
      return _notSupportedMessage.hasMatch(text) ? ChipFailureKind.unsupportedDocument : ChipFailureKind.accessDenied;
    }
    return ChipFailureKind.accessDenied;
  }
  if (error is EfParseError || error is MrtdApiError || type == 'TLVError') {
    return ChipFailureKind.unsupportedDocument;
  }
  return ChipFailureKind.unknown;
}

ChipFailureKind _fromStatusWord(StatusWord? sw, bool authentication) {
  if (sw == null) return authentication ? ChipFailureKind.accessDenied : ChipFailureKind.unknown;
  final unsupported = sw == StatusWord.invalidInstructionCode ||
      sw == StatusWord.classNotSupported ||
      sw == StatusWord.notSupported ||
      sw == StatusWord.secureMessagingNotSupported ||
      sw == StatusWord.claFunctionNotSupported;
  if (unsupported) return ChipFailureKind.unsupportedDocument;
  if (authentication) return ChipFailureKind.accessDenied;
  if (sw == StatusWord.fileNotFound || sw == StatusWord.referencedDataNotFound) {
    return ChipFailureKind.unsupportedDocument;
  }
  final accessRefused = sw == StatusWord.securityStatusNotSatisfied ||
      sw == StatusWord.authenticationFailed ||
      (sw.sw1 == 0x63 && sw.sw2 == 0xCF); // some old passports answer this to a wrong key
  return accessRefused ? ChipFailureKind.accessDenied : ChipFailureKind.unknown;
}

String _describe(Object error) {
  if (error is PlatformException) {
    final details = error.details;
    return [error.code, error.message ?? '', if (details != null) details.toString()].join(' ');
  }
  return error.toString();
}
