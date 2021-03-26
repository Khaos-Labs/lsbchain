#!/bin/bash

KEY="mykey"
TESTKEY="test"
CHAINID="lsbchain-100"
MONIKER="localtestnet"

# stop and remove existing daemon and client data and process(es)
rm -rf $PWD/.lsbchain*
pkill -f "lsbchain*"

make build-lsbchain

$PWD/build/lsbchaincli config keyring-backend test

# Set up config for CLI
$PWD/build/lsbchaincli config chain-id $CHAINID
$PWD/build/lsbchaincli config output json
$PWD/build/lsbchaincli config indent true
$PWD/build/lsbchaincli config trust-node true

# if $KEY exists it should be deleted
$PWD/build/lsbchaincli keys add $KEY

# Set moniker and chain-id for Lsbchain (Moniker can be anything, chain-id must be an integer)
$PWD/build/lsbchaind init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to aphoton
cat $HOME/.lsbchaind/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="aphoton"' > $HOME/.lsbchaind/config/tmp_genesis.json && mv $HOME/.lsbchaind/config/tmp_genesis.json $HOME/.lsbchaind/config/genesis.json
cat $HOME/.lsbchaind/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="aphoton"' > $HOME/.lsbchaind/config/tmp_genesis.json && mv $HOME/.lsbchaind/config/tmp_genesis.json $HOME/.lsbchaind/config/genesis.json
cat $HOME/.lsbchaind/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="aphoton"' > $HOME/.lsbchaind/config/tmp_genesis.json && mv $HOME/.lsbchaind/config/tmp_genesis.json $HOME/.lsbchaind/config/genesis.json
cat $HOME/.lsbchaind/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="aphoton"' > $HOME/.lsbchaind/config/tmp_genesis.json && mv $HOME/.lsbchaind/config/tmp_genesis.json $HOME/.lsbchaind/config/genesis.json

# Allocate genesis accounts (cosmos formatted addresses)
$PWD/build/lsbchaind add-genesis-account "$("$PWD"/build/lsbchaincli keys show "$KEY$i" -a)" 100000000000000000000aphoton

# Sign genesis transaction
$PWD/build/lsbchaind gentx --name $KEY --amount=1000000000000000000aphoton --keyring-backend test

# Collect genesis tx
$PWD/build/lsbchaind collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
$PWD/build/lsbchaind validate-genesis

# Start the node (remove the --pruning=nothing flag if historical queries are not needed) in background and log to file
$PWD/build/lsbchaind start --pruning=nothing --rpc.unsafe --log_level "main:info,state:info,mempool:info" --trace > lsbchaind.log &

sleep 1

# Start the rest server with unlocked key in background and log to file
$PWD/build/lsbchaincli rest-server --laddr "tcp://localhost:8545" --unlock-key $KEY --chain-id $CHAINID --trace --rpc-api="web3,eth,net,personal" > lsbchaincli.log &

solcjs --abi $PWD/tests-solidity/suites/basic/contracts/Counter.sol --bin -o $PWD/tests-solidity/suites/basic/counter
mv $PWD/tests-solidity/suites/basic/counter/*.abi $PWD/tests-solidity/suites/basic/counter/counter_sol.abi 2> /dev/null
mv $PWD/tests-solidity/suites/basic/counter/*.bin $PWD/tests-solidity/suites/basic/counter/counter_sol.bin 2> /dev/null

ACCT=$(curl --fail --silent -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545 | grep -o '\0x[^"]*' | head -1 2>&1)

echo $ACCT

curl -X POST --data '{"jsonrpc":"2.0","method":"personal_unlockAccount","params":["'$ACCT'", ""],"id":1}' -H "Content-Type: application/json" http://localhost:8545

PRIVKEY="$("$PWD"/build/lsbchaincli keys unsafe-export-eth-key $KEY)"

echo $PRIVKEY

## need to get the private key from the account in order to check this functionality.
cd tests-solidity/suites/basic/ && go get && sleep 5 && go run main.go $ACCT
