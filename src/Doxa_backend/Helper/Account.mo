import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import CRC32 "./CRC32";
import SHA224 "./SHA224";
import Buffer "mo:base/Buffer";
import Types "../Types/types";
import Hex "../Helper/Hex";
import Result "mo:base/Result";
import Error "mo:base/Error";

//subaccounts should of format Nat8.

module {
  // 32-byte array.
  public type AccountIdentifier = Blob;
  // 32-byte array.
  public type Subaccount = Blob;

  func beBytes(n : Nat32) : [Nat8] {
    func byte(n : Nat32) : Nat8 {
      Nat8.fromNat(Nat32.toNat(n & 0xff));
    };
    [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)];
  };

  //generate a default subaccount
  public func defaultSubaccount() : Subaccount {
    Blob.fromArrayMut(Array.init(32, 0 : Nat8));
  };

  //convert a principal and a subaccount to the hexadecimal format address
  //both the principal and the subaccount should be in text format
  public func PrincipalToHex(p : Text, sub : Text) : async Text {
    var sub2 : Blob = "";
    if (sub == "") {
      sub2 := defaultSubaccount();
    } else {
      sub2 := Principal.toBlob(Principal.fromText(sub));
    };

    return toText(accountIdentifier(Principal.fromText(p), sub2));
  };

  //convert the principal and subaccount to a blob type
  public func accountIdentifier(principal : Principal, subaccount : Blob) : AccountIdentifier {
    //blob type of accountIdentifier
    let hash = SHA224.Digest();

    hash.write([0x0A]);
    hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
    hash.write(Blob.toArray(Principal.toBlob(principal)));
    hash.write(Blob.toArray(subaccount));
    let hashSum = hash.sum();
    let crc32Bytes = beBytes(CRC32.ofArray(hashSum));

    let crc = Buffer.fromArray<Nat8>(crc32Bytes);
    let has = Buffer.fromArray<Nat8>(hashSum);
    crc.append(has);
    Blob.fromArray(Buffer.toArray<Nat8>(crc));
  };

  //validate whether the account identifier is correct
  public func validateAccountIdentifier(accountIdentifier : AccountIdentifier) : Bool {
    if (accountIdentifier.size() != 32) {
      return false;
    };
    let a = Blob.toArray(accountIdentifier);
    let accIdPart = Array.tabulate(28, func(i : Nat) : Nat8 { a[i + 4] });
    let checksumPart = Array.tabulate(4, func(i : Nat) : Nat8 { a[i] });
    let crc32 = CRC32.ofArray(accIdPart);
    Array.equal(beBytes(crc32), checksumPart, Nat8.equal);
  };

  // Hex string of length 64. The first 8 characters are the CRC-32 encoded
  // hash of the following 56 characters of hex.
  public func toText(accountId : AccountIdentifier) : Text {
    Hex.encode(Blob.toArray(accountId));
  };

  // Decodes the given hex encoded account identifier.
  // NOTE: does not validate if the hash/account identifier.
  public func fromText(accountId : Text) : Result.Result<AccountIdentifier, Text> {
    switch (Hex.decode(accountId)) {
      case (#err(e)) #err(e);
      case (#ok(bs)) #ok(Blob.fromArray(bs));
    };
  };

  //convert Principal and subaccount to Account type
  public func toAccount({ caller : Principal; canister : Principal }) : Types.Account {
    {
      owner = canister;
      subaccount = ?toSubaccount(caller);
    };
  };

  public func toSubaccount(p : Principal) : Types.Subaccount {
    // p blob size can vary, but 29 bytes as most. We preserve it'subaccount size in result blob
    // and it'subaccount data itself so it can be deserialized back to p
    let bytes = Blob.toArray(Principal.toBlob(p));
    let size = bytes.size();

    assert size <= 29;

    let a = Array.tabulate<Nat8>(
      32,
      func(i : Nat) : Nat8 {
        if (i + size < 31) {
          0;
        } else if (i + size == 31) {
          Nat8.fromNat(size);
        } else {
          bytes[i + size - 32];
        };
      },
    );
    Blob.toArray(Blob.fromArray(a));
  };

};
