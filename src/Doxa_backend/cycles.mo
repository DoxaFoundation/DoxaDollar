import Cycles "mo:base/ExperimentalCycles";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import MgtCanister "./Types/MgtCanisterTypes";

 actor class CycleBackup()={

let ownerCanister : Text = "cpmcr-yeaaa-aaaaa-qaala-cai";
  let IC : MgtCanister.IC = actor ("aaaaa-aa");


    //send out the cycles from this canister
    public shared({caller}) func redeemCycles(amount : Nat, canisterID:Text) :async Result.Result<Text,Text>{
        if(Principal.toText(caller) != ownerCanister) return #err("You are not authorized");
        if(Cycles.balance() < amount) return #err("amount exceeds the available cycles");

        Cycles.add(amount);

        let result = IC.deposit_cycles({canister_id = Principal.fromText(canisterID)});

        return #ok("Deposit successful")
    };

    //get the total cycle balance inside the canister

    public shared({caller}) func getCycleBalance() : async Result.Result<Nat,Text>{
      if(Principal.toText(caller) != ownerCanister) return #err("You are not authorized");

      return #ok(Cycles.balance())

    }


    //check if the caller os the owner. u
    //useful when trasfering the cycles out.

}