#!/bin/sh

DATA_DIR=/data
PASSWORD=THISISARANDOMPASSWORD
password_file=/signer.password
# See https://github.com/ethereum/EIPs/issues/225 for genesis specification
GENESIS_PATH=/genesis.json
CORS_DOMAIN="*"

usage ()
{
  echo "/run.sh proposer | collator | full-node"
  exit 1
}

proposer ()
{
  echo "Not yet implemented"
  exit 1
}

collator ()
{
  collatorip=`nslookup "${COLLATOR_NAME}" 2>/dev/null | grep 'Address 1' | awk '{ print $3 }'`
  if [ x"${collatorip}" == x ]; then
    echo "COLLATOR environment variable not set"
    exit 1
  fi
}

fullnode ()
{
  echo "Not yet implemented"
  exit 1
}

case "$1" in 
  proposer) proposer ;;
  collator) ;;
  full-node) ;;
  *)
  usage
;;
esac

if [ x"${NETWORK_ID}" == x ]; then
  NETWORK_ID=29957
fi

gethcmd="/usr/local/bin/geth --datadir ${DATA_DIR}"

# TODO: 
proposerip=`nslookup "${PROPOSER_NAME}" 2>/dev/null | grep 'Address 1' | awk '{ print $3 }'`

echo "${PASSWORD}" > "${password_file}"

import_genesis() {
  file_size=$(wc -c < "$GENESIS_PATH")
  if [ $file_size -gt 1 ] && \
      $gethcmd init "${GENESIS_PATH}"; then
      echo "Genesis imported"
  else
      echo "Could not import init, bad genesis.json"
      exit 1
  fi
}

import_key() {
  pkey_file=$(mktemp)
  echo "${PRIVATE_KEY}" > "${pkey_file}"
  $gethcmd --datadir "${DATA_DIR}" --password "${password_file}" account import "${pkey_file}"
  rm "${pkey_file}"
}

if [ x"${PRIVATE_KEY}" != "x" ]; then
  echo "Importing private key"
  import_key
fi

if ! [ -d "${DATA_DIR}"/geth/chaindata ]; then
  echo "Importing genesis"
  import_genesis
fi

modules="eth,shh,web3,admin,debug,miner,personal,txpool"

echo exec $gethcmd \
 --networkid "${NETWORK_ID}" \
 --maxpeers 100 \
 --password ${password_file} \
 --ws \
 --wsaddr "0.0.0.0" \
 --wsapi "${modules}" \
 --wsorigins "${CORS_DOMAIN}"
