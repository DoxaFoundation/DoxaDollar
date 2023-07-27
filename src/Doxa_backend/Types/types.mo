import Result "mo:base/Result";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";

module {

    //CKBtc canister id
    let CKBtcCanister = "";

    //ICP canister ID
    let ICPCanister = "";

    //OpenChat Canister ID
    let OpenCHatCanister = "";

    public type Result<E, T> = Result.Result<E, T>;

    public type Subaccount = [Nat8];

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type MintSuccess = {
        message : Text;
        amount : Nat;
    };

};
