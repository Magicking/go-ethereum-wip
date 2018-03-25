#!/bin/sh

DATA_DIR=/data
PASSWORD=THISISARANDOMPASSWORD
password_file=/signer.password
# See https://github.com/ethereum/EIPs/issues/225 for genesis specification
GENESIS_PATH=/genesis.json
CORS_DOMAIN="*"

modules="eth,shh,web3,net,admin,debug,miner,personal,txpool"
gethcmd="/usr/local/bin/geth --datadir ${DATA_DIR}"

echo "${PASSWORD}" > "${password_file}"

if ! [ -f ${GENESIS_PATH} ]; then
  echo "Genesis file not present, exiting"
  exit 1
fi

NETWORK_ID=`grep -i chainId ${GENESIS_PATH} | sed -e 's:[^0-9]*::g'`

import_genesis() {
  if [ -d "${DATA_DIR}"/geth/chaindata ]; then
    echo "Not importing genesis"
    return
  fi
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
  if [ x"${PRIVATE_KEY}" == "x" ]; then
    echo "Not importing private key"
    return
  fi
  pkey_file=$(mktemp)
  echo "${PRIVATE_KEY}" > "${pkey_file}"
  $gethcmd --datadir "${DATA_DIR}" --password "${password_file}" account import "${pkey_file}"
  rm "${pkey_file}"
}

usage ()
{
  echo "/run.sh proposer | collator | geth"
  exit 1
}

proposer ()
{
  proposerip=`nslookup "${PROPOSER_NAME}" 2>/dev/null | grep 'Address 1' | awk '{ print $3 }'`
  echo "Not yet implemented"
  exit 1
}

collator ()
{
  nodeip=`nslookup "${NODE_HOST}" 2>/dev/null | grep 'Address 1' | awk '{ print $3 }'`
  if [ x"${nodeip}" == x ]; then
    echo "NODE_HOST environment variable not set"
    exit 1
  fi
  import_key
  exec $gethcmd \
   sharding-collator --deposit \
   --networkid "${NETWORK_ID}" \
   --password ${password_file} \
   "ws://${nodeip}:8546/"
}

geth ()
{
  import_key
  import_genesis

  # Removing the 0x part
  ETHERBASE=`echo -n "${ETHERBASE}" | sed "s:\(0x\|^\)\(.*\):\2:"`
  keystore_file=`ls ${DATA_DIR}/keystore | grep -i "${ETHERBASE}"`
  if [ x"${keystore_file}" == "x" ]; then
    echo "Private key doesn't match Etherbase, not lauching Clique miner"
    exit 1
  fi

  exec $gethcmd \
   --etherbase "${ETHERBASE}" \
   --unlock "${ETHERBASE}" \
   --mine --minerthreads 1 \
   --networkid "${NETWORK_ID}" \
   --maxpeers 100 \
   --password ${password_file} \
   --ws \
   --wsaddr "0.0.0.0" \
   --wsapi "${modules}" \
   --wsorigins "${CORS_DOMAIN}"
}

case "$1" in 
  proposer) proposer ;;
  collator) collator ;;
  geth) geth ;;
  *)
  usage
;;
esac
