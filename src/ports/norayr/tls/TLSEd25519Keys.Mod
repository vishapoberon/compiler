MODULE TLSEd25519Keys;

(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Key generation through the existing Linux entropy boundary. *)

IMPORT SYSTEM, TLSEd25519, TLS13Random;

(** Writes a fresh 32-byte seed and its 32-byte public key. Output arrays must
    be distinct and exactly 32 bytes. Failure clears both outputs. *)
PROCEDURE Generate*(VAR seed, publicKey: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT; okay: BOOLEAN;
BEGIN
  okay := (LEN(seed) = TLSEd25519.seedBytes) & (LEN(publicKey) = TLSEd25519.publicKeyBytes);
  IF okay THEN okay := SYSTEM.ADR(seed[0]) # SYSTEM.ADR(publicKey[0]) END;
  IF okay THEN okay := TLS13Random.Fill(seed, TLSEd25519.seedBytes) END;
  IF okay THEN okay := TLSEd25519.PublicKey(seed, publicKey) END;
  IF ~okay THEN
    i := 0; WHILE i < LEN(seed) DO seed[i] := 0X; INC(i) END;
    i := 0; WHILE i < LEN(publicKey) DO publicKey[i] := 0X; INC(i) END
  END;
  RETURN okay
END Generate;

END TLSEd25519Keys.
