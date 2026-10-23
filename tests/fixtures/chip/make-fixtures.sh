#!/usr/bin/env bash
# Generates the ICAO passive-authentication fixtures with OpenSSL ONLY, so they
# are independent of the TypeScript code under test. Everything is fictitious
# (state "UTO", ICAO 9303 sample holder). Re-running replaces the fixtures
# (random keys, so the binary files change; the tests do not depend on values).
#
#   tests/fixtures/chip/make-fixtures.sh
#
# Output per variant dir: csca.pem dsc.pem sod.bin dg1.bin dg2.bin
set -euo pipefail

OPENSSL=${OPENSSL:-/opt/homebrew/opt/openssl@4/bin/openssl}
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

CSCA_VALID=(-not_before 20200101000000Z -not_after 20400101000000Z)
# The DSC is deliberately EXPIRED at test time (2026): only the CSCA validity is checked.
DSC_VALID=(-not_before 20250101000000Z -not_after 20250401000000Z)

# ---- data groups (python only assembles bytes; the crypto stays in OpenSSL) ----
build_dg() { # $1 = jpeg, $2 = out dir
  python3 -I - "$1" "$2" <<'PY'
import sys, struct
jpeg = open(sys.argv[1], 'rb').read()
out = sys.argv[2]

def tlv(tag, content):
    t = tag if isinstance(tag, bytes) else bytes([tag])
    n = len(content)
    if n < 0x80: l = bytes([n])
    elif n < 0x100: l = bytes([0x81, n])
    else: l = bytes([0x82, n >> 8, n & 0xff])
    return t + l + content

def cd(s):
    w = [7, 3, 1]; v = lambda c: int(c) if c.isdigit() else (0 if c == '<' else ord(c) - 55)
    return str(sum(v(c) * w[i % 3] for i, c in enumerate(s)) % 10)

# ICAO 9303 Part 4 sample holder, with a modern expiry date.
l1 = ("P<UTOERIKSSON<<ANNA<MARIA" + "<" * 44)[:44]
doc, birth, expiry, pers = "L898902C3", "740812", "320415", "ZE184226B<<<<<"
l2 = doc + cd(doc) + "UTO" + birth + cd(birth) + "F" + expiry + cd(expiry) + pers + cd(pers)
l2 += cd(l2[0:10] + l2[13:20] + l2[21:43])
import os
if os.environ.get('BAD_MRZ'):  # validly signed but with a wrong composite check digit
    l2 = l2[:43] + str((int(l2[43]) + 1) % 10)
assert len(l1) == 44 and len(l2) == 44, (len(l1), len(l2))
open(out + '/dg1.bin', 'wb').write(tlv(0x61, tlv(b'\x5f\x1f', (l1 + l2).encode())))

# ISO/IEC 19794-5 face record: header 14, facial info 20 (0 feature points), image info 12.
facial = struct.pack('>IHBBB', 0, 0, 1, 0, 0) + b'\x00\x00\x00' + b'\x00\x00' + b'\x00\x00\x00' + b'\x00\x00\x00'
assert len(facial) == 20, len(facial)
image_info = bytes([0, 0]) + struct.pack('>HH', 24, 32) + bytes([0, 0]) + b'\x00\x00' + b'\x00\x00'
assert len(image_info) == 12
body = facial + image_info + jpeg
rec = b'FAC\x00' + b'010\x00' + struct.pack('>IH', 14 + len(body), 1) + body
inst = tlv(b'\x7f\x60', tlv(0xa1, tlv(0x81, b'\x02')) + tlv(b'\x5f\x2e', rec))
group = tlv(b'\x7f\x61', tlv(0x02, b'\x01') + inst)
open(out + '/dg2.bin', 'wb').write(tlv(0x75, group))
PY
}

build_lds() { # $1 = dir ; writes lds.der
  local dg1 dg2
  dg1=$("$OPENSSL" dgst -sha256 -binary "$1/dg1.bin" | xxd -p -c 256)
  dg2=$("$OPENSSL" dgst -sha256 -binary "$1/dg2.bin" | xxd -p -c 256)
  cat >"$WORK/lds.cnf" <<CNF
asn1 = SEQUENCE:lds
[lds]
version = INTEGER:0
hashAlg = SEQUENCE:alg
dgs = SEQUENCE:dgs
[alg]
oid = OID:2.16.840.1.101.3.4.2.1
null = NULL
[dgs]
dg1 = SEQUENCE:dg1
dg2 = SEQUENCE:dg2
[dg1]
n = INTEGER:1
h = FORMAT:HEX,OCTETSTRING:$dg1
[dg2]
n = INTEGER:2
h = FORMAT:HEX,OCTETSTRING:$dg2
CNF
  "$OPENSSL" asn1parse -genconf "$WORK/lds.cnf" -noout -out "$1/lds.der"
}

gen_key() { # $1 = kind, $2 = out
  case "$1" in
    rsa) "$OPENSSL" genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$2" 2>/dev/null ;;
    p256) "$OPENSSL" genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$2" ;;
    bp256x) "$OPENSSL" genpkey -algorithm EC -pkeyopt ec_paramgen_curve:brainpoolP256r1 -pkeyopt ec_param_enc:explicit -out "$2" ;;
  esac
}

gen_csca() { # $1 = key kind, $2 = dir, $3 = CN, $4... = extra req options (sigopt)
  local kind=$1 dir=$2 cn=$3; shift 3
  gen_key "$kind" "$dir/csca.key"
  "$OPENSSL" req -x509 -new -key "$dir/csca.key" -sha256 -set_serial 1 "${CSCA_VALID[@]}" \
    -subj "/C=UT/O=Utopia Ministry of Interior/CN=$cn" \
    -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign \
    -addext subjectKeyIdentifier=hash "$@" -out "$dir/csca.pem"
}

gen_dsc() { # $1 = key kind, $2 = dir, $3 = serial, $4... = x509 sigopts
  local kind=$1 dir=$2 serial=$3; shift 3
  gen_key "$kind" "$dir/dsc.key"
  "$OPENSSL" req -new -key "$dir/dsc.key" -subj "/C=UT/O=Utopia Passport Office/CN=Utopia DSC $serial" -out "$dir/dsc.csr"
  printf 'subjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid\nkeyUsage=critical,digitalSignature\n' >"$WORK/dsc.ext"
  "$OPENSSL" x509 -req -in "$dir/dsc.csr" -CA "$dir/csca.pem" -CAkey "$dir/csca.key" -sha256 -set_serial "$serial" \
    "${DSC_VALID[@]}" -extfile "$WORK/dsc.ext" "$@" -out "$dir/dsc.pem" 2>/dev/null
}

wrap_sod() { # $1 = dir ; DER CMS in dir/sod.cms -> 0x77 wrapped sod.bin
  python3 -I - "$1/sod.cms" "$1/sod.bin" <<'PY'
import sys
d = open(sys.argv[1], 'rb').read(); n = len(d)
l = bytes([n]) if n < 0x80 else bytes([0x81, n]) if n < 0x100 else bytes([0x82, n >> 8, n & 0xff])
open(sys.argv[2], 'wb').write(b'\x77' + l + d)
PY
}

sign_sod() { # $1 = dir ; $2... = extra cms options
  local dir=$1; shift
  "$OPENSSL" cms -sign -binary -nodetach -econtent_type 2.23.136.1.1.1 -md sha256 -nosmimecap \
    -signer "$dir/dsc.pem" -inkey "$dir/dsc.key" -in "$dir/lds.der" -outform DER -out "$dir/sod.cms" "$@"
  wrap_sod "$dir"
}

finish() { rm -f "$1"/*.key "$1"/*.csr "$1"/lds.der "$1"/sod.cms; }

variant() { # $1 = name, $2 = key kind, $3 = jpeg, $4... = cms options
  local name=$1 kind=$2 jpeg=$3; shift 3
  local dir=$HERE/$name
  rm -rf "$dir"; mkdir -p "$dir"
  gen_csca "$kind" "$dir" "Utopia CSCA $name"
  gen_dsc "$kind" "$dir" 1001
  build_dg "$HERE/$jpeg" "$dir"; build_lds "$dir"
  sign_sod "$dir" "$@"
  finish "$dir"
  echo "built $name"
}

variant rsa-pkcs1 rsa face-a.jpg
variant rsa-pss rsa face-b.jpg -keyopt rsa_padding_mode:pss -keyopt rsa_pss_saltlen:32
variant ecdsa-p256 p256 face-a.jpg -keyid
variant ecdsa-brainpool-explicit bp256x face-b.jpg

# (5) PSS for the DSC certificate as well (CSCA signs the DSC with RSASSA-PSS).
dir=$HERE/rsa-pss-cert; rm -rf "$dir"; mkdir -p "$dir"
gen_csca rsa "$dir" "Utopia CSCA rsa-pss-cert"
gen_dsc rsa "$dir" 1002 -sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:32
build_dg "$HERE/face-a.jpg" "$dir"; build_lds "$dir"; sign_sod "$dir"; finish "$dir"; echo "built rsa-pss-cert"

# (5b) Validly signed data whose MRZ composite check digit is wrong.
dir=$HERE/bad-mrz; rm -rf "$dir"; mkdir -p "$dir"
gen_csca rsa "$dir" "Utopia CSCA bad-mrz"; gen_dsc rsa "$dir" 1003
BAD_MRZ=1 build_dg "$HERE/face-a.jpg" "$dir"; build_lds "$dir"; sign_sod "$dir"; finish "$dir"; echo "built bad-mrz"

# (6) A DSC signed by a CA that is NOT in the trust store (rogue/other country).
dir=$HERE/untrusted-csca; rm -rf "$dir"; mkdir -p "$dir"
gen_csca rsa "$dir" "Rogue CSCA"
gen_dsc rsa "$dir" 2001
build_dg "$HERE/face-a.jpg" "$dir"; build_lds "$dir"; sign_sod "$dir"; finish "$dir"; echo "built untrusted-csca"

# (7) ICAO master list (CMS, content type 2.23.136.1.1.2) signed by a list signer
# issued by a root CSCA that is itself in the list; plus a "rogue" list whose
# signer is issued by a CA that is NOT in the list.
build_master_list() { # $1 = out dir, $2 = signer CA dir (has csca.pem/key + dsc.pem/key), $3... = certs (PEM) to list
  local dir=$1 signer_dir=$2; shift 2
  : >"$WORK/ml-certs.der"
  for pem in "$@"; do "$OPENSSL" x509 -in "$pem" -outform DER >>"$WORK/ml-certs.der"; done
  python3 -I - "$WORK/ml-certs.der" "$dir/ml-content.der" <<'PY'
import sys
def tlv(tag, c):
    n = len(c)
    l = bytes([n]) if n < 0x80 else bytes([0x81, n]) if n < 0x100 else bytes([0x82, n >> 8, n & 0xff])
    return bytes([tag]) + l + c
certs = open(sys.argv[1], 'rb').read()
open(sys.argv[2], 'wb').write(tlv(0x30, tlv(0x02, b'\x00') + tlv(0x31, certs)))
PY
  "$OPENSSL" cms -sign -binary -nodetach -econtent_type 2.23.136.1.1.2 -md sha256 -nosmimecap \
    -signer "$signer_dir/dsc.pem" -inkey "$signer_dir/dsc.key" -in "$dir/ml-content.der" -outform DER -out "$dir/ml.der"
  rm -f "$dir/ml-content.der"
}

ML_VALID=(-not_before 20250101000000Z -not_after 20400101000000Z)
dir=$HERE/master-list; rm -rf "$dir"; mkdir -p "$dir"
gen_csca rsa "$dir" "Utopia Root CSCA"
DSC_VALID=("${ML_VALID[@]}"); gen_dsc rsa "$dir" 3001
build_master_list "$dir" "$dir" "$dir/csca.pem" "$HERE/rsa-pkcs1/csca.pem" "$HERE/ecdsa-p256/csca.pem" "$HERE/ecdsa-brainpool-explicit/csca.pem" "$HERE/rsa-pss/csca.pem"
mv "$dir/ml.der" "$dir/ml-good.der"
rogue=$WORK/rogue; mkdir -p "$rogue"
gen_csca rsa "$rogue" "Rogue Root CSCA"; gen_dsc rsa "$rogue" 3002
build_master_list "$dir" "$rogue" "$dir/csca.pem" "$HERE/rsa-pkcs1/csca.pem"
mv "$dir/ml.der" "$dir/ml-rogue.der"
rm -f "$dir"/*.key "$dir"/*.csr "$dir"/dsc.pem; echo "built master-list"
