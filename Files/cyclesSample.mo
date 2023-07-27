import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Cycles "mo:base/ExperimentalCycles";

actor HelloCycles {

  let limit = 10_000_000;

  public func wallet_balance() : async Nat {
    return Cycles.balance();
  };

  public func wallet_receive() : async { accepted : Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, limit));
    { accepted = Nat64.fromNat(accepted) };
  };

  public func transfer(
    receiver : shared () -> async (),
    amount : Nat,
  ) : async { refunded : Nat } {
    Cycles.add(amount);
    await receiver();
    { refunded = Cycles.refunded() };
  };

};

import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";

actor {
  public func main() : async () {
    Debug.print("Main balance: " # debug_show (Cycles.balance()));
    Cycles.add(15_000_000);
    await operation(); // accepts 10_000_000 cycles
    Debug.print("Main refunded: " # debug_show (Cycles.refunded())); // 5_000_000
    Debug.print("Main balance: " # debug_show (Cycles.balance())); // decreased by around 10_000_000
  };

  func operation() : async () {
    Debug.print("Operation balance: " # debug_show (Cycles.balance()));
    Debug.print("Operation available: " # debug_show (Cycles.available()));
    let obtained = Cycles.accept(10_000_000);
    Debug.print("Operation obtained: " # debug_show (obtained)); // => 10_000_000
    Debug.print("Operation balance: " # debug_show (Cycles.balance())); // increased by 10_000_000
    Debug.print("Operation available: " # debug_show (Cycles.available())); // decreased by 10_000_000
  };
};
