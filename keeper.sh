#!/usr/bin/env bash
# Yieldr keeper: one run = check whether a rebalance is due and send it if so.
# Once a day (the run during 12:00 UTC) it also refreshes the Steakhouse rate snapshots with pokeRates().
#
# Needs: ROBINHOOD_RPC_URL, YIELDR_VAULT, KEEPER_PRIVATE_KEY  (and Foundry's `cast` on PATH)
# The keeper wallet can only trigger rebalances and rate pokes. It can never move funds anywhere else.
set -euo pipefail

: "${ROBINHOOD_RPC_URL:?ROBINHOOD_RPC_URL is not set}"
: "${YIELDR_VAULT:?YIELDR_VAULT is not set}"
: "${KEEPER_PRIVATE_KEY:?KEEPER_PRIVATE_KEY is not set}"

RPC="$ROBINHOOD_RPC_URL"
VAULT="$YIELDR_VAULT"

echo "Yieldr keeper run at $(date -u '+%Y-%m-%d %H:%M UTC') for vault $VAULT"

NEEDED=$(cast call "$VAULT" "checkUpkeep(bytes)(bool,bytes)" 0x --rpc-url "$RPC" | head -1)
if [ "$NEEDED" = "true" ]; then
  echo "Rebalance due, sending rebalance()"
  cast send "$VAULT" "rebalance()" --private-key "$KEEPER_PRIVATE_KEY" --rpc-url "$RPC"
else
  echo "No rebalance needed"
fi

if [ "${POKE_RATES:-auto}" = "always" ] || [ "$(date -u +%H)" = "12" ]; then
  echo "Daily rate refresh, sending pokeRates()"
  cast send "$VAULT" "pokeRates()" --private-key "$KEEPER_PRIVATE_KEY" --rpc-url "$RPC"
fi
