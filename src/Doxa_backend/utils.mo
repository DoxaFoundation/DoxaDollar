import Types "./Types/types";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";
import Hex "./Helper/Hex";
import Result "mo:base/Result";

module {

    // Represents an account identifier that was dirived from a principal.
    // NOTE: does include the hash, unlike in the default package.
    public type AccountIdentifier = Blob; // Size 32
    public type SubAccount = [Nat8]; // Size 4

    /// Convert Principal to ICRC1.Subaccount
    // from https://github.com/research-ag/motoko-lib/blob/2772d029c1c5087c2f57b022c84882f2ac16b79d/src/TokenHandler.mo#L51
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

    //convert Principal and subaccount to Account type
    public func toAccount({ caller : Principal; canister : Principal }) : Types.Account {
        {
            owner = canister;
            subaccount = ?toSubaccount(caller);
        };
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

};
