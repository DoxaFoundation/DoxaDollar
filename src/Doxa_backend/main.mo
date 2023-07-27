import Types "./Types/types";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Hex "./Helper/Hex";
import Iter "mo:base/Iter";
import Cycles "mo:base/ExperimentalCycles";
import DTXCanister "canister:DTX";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import { toSubaccount; toAccount } "utils";
import MgtCanister "./Types/MgtCanisterTypes";
import Debug "mo:base/Debug";
import Account "./Helper/Account";
import Blob "mo:base/Blob";

//allow the user to to call the mint function with the deposited cycles.
//The amount of cycles deposited will be equivalent to the number of tokens to be minted (1 token = 1 Trillion cycles)
//Users can also withdraw their cycles by calling the withdraw function specifying the amount of tokens they want to withdraw

actor class DoxaEnd() = this {

  type Result<E, T> = Types.Result<E, T>;

  //All cycles deposites should be above this number(1 trillion).
  let base : Nat = 1000000000000;

  //initialize the mgt canister
  let IC : MgtCanister.IC = actor ("aaaaa-aa");

  public shared ({ caller }) func mint(owner : Text) : async Result<Types.MintSuccess, Text> {

    try {

      let realOwner = Principal.fromText(owner);

      let availableCycles = Cycles.available();
      if (availableCycles < base) {
        Debug.print(Nat.toText(availableCycles));
        return #err("Minimum cycles is 1 Trillion");

      };

      //acept the cycles sent on this function
      let rec = Cycles.accept(availableCycles);

      //calculate the number of tokens to mint for the user.
      let tokenToMint = availableCycles / base;

      //do the real minting of the token
      let result = await DTXCanister.icrc1_transfer({

        amount = tokenToMint;
        from_subaccount = null;
        created_at_time = null;
        fee = null;
        memo = null;
        to = {
          owner = realOwner;
          subaccount = null;
        };

      });

      switch (result) {

        case (#Err(transferError)) {
          #err("Minting of DTX tokens has failed. Try again later");
        };
        case (_) {
          #ok({
            message = "You have successfully minted DTX tokens :";
            amount = tokenToMint;
          });
        };
      };

    } catch (error) {
      #err(Error.message(error));
    }

  };

  //Burn the DTX tokens to retrieve back the cycles to your canister
  //Users have to deposit tokens to the account of this canister associated with their Principal before calling this function

  public shared ({ caller }) func Withdraw(tokens : Nat, canisterID : Text) : async Result<Text, Text> {

    try {
      //check the user balance in the special account
      let userBalance = await DTXCanister.icrc1_balance_of({
        owner = caller;
        subaccount = null;
      });

      //tansfer the tokens to the main account of this canister
      let transferResult = await DTXCanister.icrc1_transfer({
        amount = tokens;
        from_subaccount = ?toSubaccount(caller);
        created_at_time = null;
        fee = null;
        memo = null;
        to = {
          owner = Principal.fromActor(this);
          subaccount = null;
        };
      });

      switch (transferResult) {
        case (#Err(transferError)) {
          return #err("Error in processing your withdraw");
        };
        case (_) {

          //calculate the number of cycles to deposit
          let cyclesToDeposit = tokens * base;

          //Yow transfer the cycles to the cycles wallet of the caller that they specified
          //You have to add the cycles to the deposit function

          Cycles.add(cyclesToDeposit);
          let depC = await IC.deposit_cycles({
            canister_id = Principal.fromText(canisterID);
          });
          #ok("You have successfull redeemed your cycles back");

        };
      };

    } catch (error) {

      #err(Error.message(error));
    }

  };

  //get cycle balance of this canister
  public func getCycleBalance() : async Nat {
    return Cycles.balance();
  };

  public func getSubAccountFromPrincipal(p : Text) : async Types.Subaccount {
    return toSubaccount(Principal.fromText(p));
  };

  public func myAccountId() : async Account.AccountIdentifier {
    Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
  };

  public func myAccountIdHex(p : Text, sub : Text) : async Text {
    await Account.PrincipalToHex(p, sub);
    // let acc = Account.accountIdentifier(Principal.fromActor(this), ?Account.defaultSubaccount());
    // Hex.encode(Blob.toArray(acc));
  };

  public func deft() : async Account.Subaccount {
    Account.defaultSubaccount();
  };

  //convert form hex to principal

  public func fromHexToPricipal(s : Text) : async Result.Result<Principal, Text> {

    let result = Account.fromText(s);
    switch (result) {
      case (#err(value)) { return #err(value) };
      case (#ok(value)) {
        return #ok(Principal.fromBlob(value));
      };
    };

  };

  //initialize token canister actor and check for the balance of the caller

  // func initTokenCanister(caller : Principal, token : Text) : async Result<Text, Text> {
  //   let canisterToken = "";

  //   if (token == "ICP") {
  //     canisterToken := Types.ICPCanister;
  //   } else if (token == "CKBtc") {
  //     canisterToken := Types.CKBtcCanister;
  //   } else if (token == "OPENCHAT") {
  //     canisterToken := TYpes.OpenCHatCanister;
  //   } else {
  //     return #err("Specified Token not supported");
  //   };

  //   try {
  //     //iniializze the token actor
  //     let tokenActor : icrc1Interface = actor (canisterToken);

  //     //calculate the subaccount of the caller

  //     let callerSubAccount = toSubaccount(caller);

  //     //check for the balance of the caller
  //     let callerBalance = tokenActor.icrc1_balance_of({
  //       owner = Principal.fromActor(this);
  //       subaccount = callerSubAccount;
  //     });

  //     //calculate the amount of tokens to deposit for the user

  //   } catch (error) {
  //     #err(Error.message(error));
  //   }

  // };

};
