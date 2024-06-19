#pragma version 0.3.10
#pragma evm-version cancun
"""
@title Adapter Fund Allocation Logic
@license Copyright 2023, 2024 Biggest Lab Co Ltd, Benjamin Scherrey, Sajal Kayan, and Eike Caldeweyher
@author BiggestLab (https://biggestlab.io) Benjamin Scherrey
"""

##
## Must match AdapterVault.vy
##

MAX_ADAPTERS : constant(uint256) = 5 

ADAPTER_BREAKS_LOSS_POINT : constant(decimal) = 0.05


# This structure must match definition in AdapterVault.vy
struct BalanceTX:
    qty: int256
    adapter: address

# This structure must match definition in AdapterVault.vy
struct BalanceAdapter:
    adapter: address
    current: uint256
    last_value: uint256
    max_deposit: int256
    max_withdraw: int256 # represented as a negative number
    ratio: uint256
    target: uint256 
    delta: int256


@internal
@pure
def _getTargetBalancesWithdrawOnly(_vault_balance: uint256, _d4626_asset_target: uint256, _total_assets: uint256, _total_ratios: uint256, _adapter_balances: BalanceAdapter[MAX_ADAPTERS]) -> (int256, uint256, BalanceAdapter[MAX_ADAPTERS], address[MAX_ADAPTERS]):
    d4626_delta : int256 = 0
    tx_count: uint256 = 0

    # adapters is our final list of txs to be executed.
    adapters : BalanceAdapter[MAX_ADAPTERS] = empty(BalanceAdapter[MAX_ADAPTERS])

    blocked_adapters : address[MAX_ADAPTERS] = empty(address[MAX_ADAPTERS])
    blocked_pos : uint256 = 0

    if _vault_balance >= _d4626_asset_target:
        # Vault has adequate funds to fulfill the withdraw. Nothing left to do.
        return d4626_delta, tx_count, adapters, blocked_adapters

    # How much more do we need to withdraw (aspirational)?
    target_withdraw_balance : uint256 = _d4626_asset_target - _vault_balance        

    # We're just going to walk through and empty adapters until we have 
    # adequate funds in the vault for this withdraw.
    for pos in range(MAX_ADAPTERS):
        # Anything left to withdraw?
        if target_withdraw_balance == 0: break
        adapter : BalanceAdapter = _adapter_balances[pos]

        # End of adapters?
        if adapter.adapter == empty(address): break

        # If the adapter has been removed from the strategy then we must empty it!
        if adapter.ratio == 0 and adapter.current > 0:
            adapter.target = 0
            adapter.delta = min(convert(adapter.current, int256)*-1, adapter.max_withdraw) # Withdraw it all!
            target_withdraw_balance -= min(convert(adapter.delta * -1, uint256),target_withdraw_balance)

        elif adapter.current > 0:
            withdraw : uint256 = min(target_withdraw_balance, adapter.current)
            target_withdraw_balance = target_withdraw_balance - withdraw
            adapter.delta = convert(withdraw, int256) * -1

        if adapter.delta != 0:                
            d4626_delta += adapter.delta * -1
            adapters[tx_count] = adapter
            tx_count += 1

        # NEW
        adapter_result : int256 = convert(adapter.current, int256) + adapter.delta
        assert adapter_result >= 0, "Adapter resulting balance can't be less than zero!"

    assert target_withdraw_balance == 0, "ERROR - Unable to fulfill this withdraw!"

    return d4626_delta, tx_count, adapters, blocked_adapters


@internal
@pure
def _getTargetBalances(_vault_balance: uint256, _d4626_asset_target: uint256, _total_assets: uint256, _total_ratios: uint256, _adapter_balances: BalanceAdapter[MAX_ADAPTERS], _min_outgoing_tx: uint256, _withdraw_only : bool = False) -> (int256, uint256, BalanceAdapter[MAX_ADAPTERS], address[MAX_ADAPTERS]):
    # BDM TODO : enforce ADAPTER_BREAKS_LOSS_POINT more completely than just during deposits.
    assert _d4626_asset_target <= _total_assets, "Not enough assets to fulfill d4626 target goals!"

    if _withdraw_only == True:
        return self._getTargetBalancesWithdrawOnly(_vault_balance, _d4626_asset_target, _total_assets, _total_ratios, _adapter_balances)

    total_adapter_target_assets : uint256 = _total_assets - _d4626_asset_target

    d4626_delta : int256 = 0
    tx_count: uint256 = 0

    # out_txs holds the txs that will deposit to the adapters.
    out_txs : DynArray[BalanceAdapter, MAX_ADAPTERS] = empty(DynArray[BalanceAdapter, MAX_ADAPTERS])

    # adapters is our final list of txs to be executed. withdraws from adapters happen first.    
    adapters : BalanceAdapter[MAX_ADAPTERS] = empty(BalanceAdapter[MAX_ADAPTERS])

    blocked_adapters : address[MAX_ADAPTERS] = empty(address[MAX_ADAPTERS])
    blocked_pos : uint256 = 0

    for pos in range(MAX_ADAPTERS):
        adapter : BalanceAdapter = _adapter_balances[pos]
        if adapter.adapter == empty(address): break

        # If the adapter has been removed from the strategy then we must empty it!
        if adapter.ratio == 0 and adapter.current > 0:
            adapter.target = 0
            adapter.delta = max(convert(adapter.current, int256)*-1, adapter.max_withdraw) # Withdraw it all! (max_withdraw is a negative number)
        else:
            adapter.target = (total_adapter_target_assets * adapter.ratio) / _total_ratios      
            adapter.delta = convert(adapter.target, int256) - convert(adapter.current, int256)

            # Ensure the adapters will handle a deposit or withdrawl of the size requested.
            if adapter.delta > 0:
                adapter.delta = min(adapter.delta, adapter.max_deposit) 
            elif adapter.delta < 0:                
                adapter.delta = max(adapter.delta, adapter.max_withdraw) # (max_withdraw is a negative number)        

            # Check for valid outgoing txs here.
            if adapter.delta > 0:

                # Is an outgoing tx > min size?
                if adapter.delta < convert(_min_outgoing_tx, int256):         
                    adapter.delta = 0

                # Is the LP possibly compromised for an outgoing tx?
                adapter_brakes_limit : uint256 = adapter.last_value - convert(convert(adapter.last_value, decimal) * ADAPTER_BREAKS_LOSS_POINT, uint256)
                if adapter.current < adapter_brakes_limit:
                    # We've lost value in this adapter! Don't give it more money!
                    blocked_adapters[blocked_pos] = adapter.adapter
                    blocked_pos += 1
                    adapter.delta = 0 # This will result in no tx being generated.

        adapter_result : int256 = convert(adapter.current, int256) + adapter.delta
        assert adapter_result >= 0, "Adapter resulting balance can't be less than zero!"

        d4626_delta += adapter.delta * -1

        # Don't insert a tx if there's nothing to transfer.
        if adapter.delta == 0: continue

        if adapter.delta < 0:
            # This is a withdraw.
            adapters[tx_count] = adapter
            tx_count += 1
        else:
            # This is a deposit.
            # txs depositing to adapters go last.
            out_txs.append(adapter)            

    # Stick outbound txs at the end.
    for adapter in out_txs:
        adapters[tx_count] = adapter
        tx_count+=1 

    return d4626_delta, tx_count, adapters, blocked_adapters


@external
@pure
def getTargetBalances(_vault_balance: uint256, _d4626_asset_target: uint256, _total_assets: uint256, _total_ratios: uint256, _adapter_balances: BalanceAdapter[MAX_ADAPTERS], _min_outgoing_tx: uint256, _withdraw_only : bool = False) -> (int256, uint256, BalanceAdapter[MAX_ADAPTERS], address[MAX_ADAPTERS]): 
    """
    @dev    Returns: 
            # REMOVED 1) uint256 - the total asset allocation across all adapters (less _d4626_asset_target),
            2) int256 - the total delta of local d4626 assets that would be moved across
            all transactions, 
            3) uint256 - the total number of planned txs to achieve these targets,
            4) BalanceAdapter[MAX_ADAPTERS] - the updated list of transactions required to
            meet the target goals sorted in ascending order of BalanceAdapter.delta.
            5) A list of any adapters that should be blocked because they lost funds.

    @param  _vault_balance current balance of the vault itself.

    @param  _d4626_asset_target minimum asset target goal to be made available
            for withdraw from the 4626 contract.

    @param  _total_assets the sum of all assets held by the d4626 plus all of
            its adapter adapters.

    @param _total_ratios the total of all BalanceAdapter.ratio values in _adapter_balances.

    @param _adapter_balances current state of the adapter adapters. BDM TODO Specify TYPES!

    @param _min_outgoing_tx the minimum size of a tx depositing funds to an adapter (as set by the current strategy).

    """    
    return self._getTargetBalances(_vault_balance, _d4626_asset_target, _total_assets, _total_ratios, _adapter_balances, _min_outgoing_tx, _withdraw_only)


@internal
@pure
def _getBalanceTxs(_vault_balance: uint256, _target_asset_balance: uint256, _min_proposer_payout: uint256, _total_assets: uint256, _total_ratios: uint256, _adapter_states: BalanceAdapter[MAX_ADAPTERS], _withdraw_only : bool = False) -> (BalanceTX[MAX_ADAPTERS], address[MAX_ADAPTERS]): 
    # _BDM TODO : max_txs is ignored for now.    
    adapter_txs : BalanceTX[MAX_ADAPTERS] = empty(BalanceTX[MAX_ADAPTERS])
    blocked_adapters : address[MAX_ADAPTERS] = empty(address[MAX_ADAPTERS])
    adapter_states: BalanceAdapter[MAX_ADAPTERS] = empty(BalanceAdapter[MAX_ADAPTERS])
    d4626_delta : int256 = 0
    tx_count : uint256 = 0

    d4626_delta, tx_count, adapter_states, blocked_adapters = self._getTargetBalances(_vault_balance, _target_asset_balance, _total_assets, _total_ratios, _adapter_states, _min_proposer_payout, _withdraw_only)

    pos : uint256 = 0
    for tx_bal in adapter_states:
        adapter_txs[pos] = BalanceTX({qty: tx_bal.delta, adapter: tx_bal.adapter})
        pos += 1

    return adapter_txs, blocked_adapters


@external
@view
def getBalanceTxs(_vault_balance: uint256, _target_asset_balance: uint256, _min_proposer_payout: uint256, _total_assets: uint256, _total_ratios: uint256, _adapter_states: BalanceAdapter[MAX_ADAPTERS], _withdraw_only : bool = False) -> (BalanceTX[MAX_ADAPTERS], address[MAX_ADAPTERS]):  
    return self._getBalanceTxs(_vault_balance, _target_asset_balance, _min_proposer_payout, _total_assets, _total_ratios, _adapter_states, _withdraw_only )