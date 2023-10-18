## Doxa Dollar Project

This is the official repo of the Doxa dollar project, a cycles backed stable coin on the Internet Computer.

The project is still in the development stages, and all the progress will be documented here.

## Testing

To run the project locally, ensure that the `dfx` is already installed on your machine;

- Clone the repo locally.

  ```bash
  git clone https://github.com/DoxaFoundation/DoxaDollar
  ```

- Deploy the USDx ledger canister.

  Follow the guide to set up the icrc ledger token. Remember to set the minter as the Principal ID of the `Doxa_backend` as this will be the one minting the tokens.

- Deploy the Cycles backup canister
  ```bash
  dfx deploy Cycles_backup
  ```
- Deploy the Doxa backend canister

  ```bash
    dfx deploy Doxa_backend
  ```

- To mint USDx token, you need to call the mint function and attach some cycles that will be converted into USDx, and you need to specify the Principal ID that will receive the minted tokens

  ```bash
  dfx canister call Doxa_backend mint "utvbn-hhmsq-vxs5n-pg2kr-rhurv-jjeww-fiyhh-3exfb-tqjk7-lsk4b-3qe" --wallet bkyz2-fmaaa-aaaaa-qaaaq-cai --with-cycles 2000000000000
  ```

  You can now check the USDx balance of the Principal ID

  ```bash
  dfx canister call USDx icrc1_balance_of  '(record{
    owner = principal "utvbn-hhmsq-vxs5n-pg2kr-rhurv-jjeww-fiyhh-3exfb-tqjk7-lsk4b-3qe";
    subaccount=null;
  })'
  ```
