# @version 0.3.10

from vyper.interfaces import ERC20

implements: ERC20

# ERC20 Token Metadata
NAME: constant(String[20]) = "proptes5"
SYMBOL: constant(String[8]) = "PROPTES5"
DECIMALS: constant(uint8) = 0

# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Interfaces
interface nft_contract_interface:
    def nft_tier(tokenId: uint256) -> uint8: view
    def level_up(tokenID: uint256) -> bool: nonpayable
    def mint_nft(owner: address) -> bool: nonpayable
    def ownerOf(tokenId: uint256) -> address: nonpayable

interface vault_contract_interface:
    def twenty_percent_tax_tracker(addr: address) -> uint256: view
    def _tokens_used_for_staking_rewards() -> uint256: view
    def update_tax_tracker_from_token_transfer(sender:address, receiver: address): nonpayable

interface UniswapV2Router02:
    def swapExactTokensForETHSupportingFeeOnTransferTokens(
        amountIn: uint256,
        amountOutMin: uint256,
        path: DynArray[address, 2], # Use an array of addresses instead of List
        to: address,
        deadline: uint256
    ):
        nonpayable
    def addLiquidityETH(
        token: address,
        amountTokenDesired: uint256,
        amountTokenMin: uint256,
        amountETHMin: uint256,
        to: address,
        deadline: uint256
    ) -> uint256[3]: payable
    def swapExactETHForTokensSupportingFeeOnTransferTokens(
        amountOut: uint256,
        path: DynArray[address, 2],
        to: address,
        deadline: uint256
    ): payable

# Events
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256

event Taxed:
    spender: indexed(address)
    amount: uint256

nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')

owner: public(address)
isMinter: public(HashMap[address, bool])


# hashmap of whitelisted addresses for transfer() operation
whitelisted_addresses: public(HashMap[address, bool])

# staking pool maps an address to an amount of staked tokens
staked_tokens_pool: public(HashMap[address, uint256])

# rewards maps an address to the amount of ETH to claim
staked_tokens_rewards: public(HashMap[address, uint256])

# list of users who have staked for tracking rewards
staking_users_reference_list: public(address[50000])

# address -> tax_rate
user_best_tier_nft: public(HashMap[address, uint8])

staked_users_count: public(uint256)
total_points_in_token_staking_pool: public(uint256)
eth_taxes_collected_in_wei_since_last_reward_call: public(uint256)

_time_til_next_token_staking_payout: public(uint256)
_nft_contract_address: public(address)
_vault_address: address
_weth_address: public(address)
_uniswap_pool_address: public(address)
_uniswap_router_address: public(address)
_swapping: bool
_untaxed_liquidity_contribution: bool
_latest_tax_reward: public(uint256)
_fundraising_wallet: public(address)
_memory_path: public(DynArray[address, 2])

_tokens_collected_for_next_sell: public(uint256)

@external
def __init__(nft_contract_address: address, fundraising_wallet: address, weth_address: address):
    self.owner = msg.sender
    self.totalSupply = 200000000000
    self.balanceOf[msg.sender] = 200000000000

    self._nft_contract_address = nft_contract_address

    self._time_til_next_token_staking_payout = block.timestamp
    self.eth_taxes_collected_in_wei_since_last_reward_call = 0

    self._fundraising_wallet = fundraising_wallet
    self._latest_tax_reward = 0

    self._weth_address = weth_address
    self._untaxed_liquidity_contribution = False
    self._memory_path = [self, self._weth_address]

    self._tokens_collected_for_next_sell = 0

    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(NAME),
            keccak256("1.0"),
            _abi_encode(chain.id, self)
        )
    )

# __default__ fires whenever ETH arrives to the token contract
@external
@payable
def __default__():
    # only update tax reward if sent via _swap_back()
    self._latest_tax_reward = msg.value
    
    log Taxed(msg.sender, msg.value)

## PURE FUNCTIONS
@pure
@external
def name() -> String[20]:
    return NAME

@pure
@external
def symbol() -> String[8]:
    return SYMBOL

@pure
@external
def decimals() -> uint8:
    return DECIMALS

## INTERNAL FUNCTIONS
@internal
def _approve(owner: address, spender: address, amount: uint256) -> bool:

    # assert owner != empty(address), "ERC20: approve from the zero address"
    # assert spender != empty(address), "ERC20: approve to the zero address"

    self.allowance[owner][spender] = amount

    return True

# execute swap to get taxation ETH
@internal
def _swap_back(taxation_amount: uint256):

    # add tax tokens collected from buys
    taxation_amount += self._tokens_collected_for_next_sell

    print("22")
    self._approve(self, self._uniswap_router_address, taxation_amount)

    print("33")
    UniswapV2Router02(self._uniswap_router_address).swapExactTokensForETHSupportingFeeOnTransferTokens(taxation_amount, 0, self._memory_path, self, block.timestamp)

    print("44")
    self._tokens_collected_for_next_sell = 0

@internal
def _burn(_amount: uint256, _sender_address: address) -> bool:
    """
    @notice Burns the supplied amount of tokens from the sender wallet.
    @param amount The amount of token to be burned.
    """

    assert self.balanceOf[_sender_address] >= _amount

    self.balanceOf[_sender_address] -= _amount
    self.totalSupply -= _amount

    log Transfer(_sender_address, empty(address), _amount)

    return True

@external
def set_contract_addresses(lp: address, router: address, vault: address):
    assert msg.sender == self.owner
    self._uniswap_pool_address = lp
    self._uniswap_router_address = router
    self._vault_address = vault

@external
def whitelist_address(contract: address) -> bool:
    assert msg.sender == self.owner, "only contract owner can white list"
    self.whitelisted_addresses[contract] = True
    return True

@external
def transfer(receiver: address, amount: uint256) -> bool:

    # assert receiver not in [empty(address), self], "reciever doesn't exist or is token contract address"
    assert receiver not in [empty(address)], "reciever doesn't exist or is token contract address"
    
    # assert no contract to contract interations (aka: EOA must be an off-chain wallet) and internal whitelist

    assert self.whitelisted_addresses[msg.sender] or not msg.sender.is_contract, "sender not in whitelist and using an on-chain contract address"

    # check how many tokens the user has available (staked tokens can't be transfered)
    assert self.balanceOf[msg.sender] >= amount + self.staked_tokens_pool[msg.sender], "sender doesn't have enough tokens to transfer"

    if receiver == self._vault_address:
        assert msg.sender == self.owner, "only the contract owner can transfer tokens to the vault"

    # check if pool is sending tokens from lp to user
    # TODO - revert this change
    if msg.sender == self._uniswap_pool_address:

        # assume highest default tax rate
        tax_rate: decimal = .13

        if self.user_best_tier_nft[receiver] > 0:
            tax_rate -= .02 * convert(self.user_best_tier_nft[receiver], decimal)

        # check if traunches have been emptied
        if self.balanceOf[self._vault_address] > 0:
            if self.balanceOf[self._vault_address] > vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards():
                if self.balanceOf[self._vault_address] - vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards() >= 0:
                    if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(receiver) > 0:
                        if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(receiver) - self.balanceOf[self._vault_address] < 20000000000:
                            tax_rate += .25

        # calculate token taxation amount based on tax_rate to sell off for ETH payout
        taxation_amount: decimal = convert(amount, decimal) * tax_rate
        assert taxation_amount + convert(amount, decimal) * (1.0 - tax_rate) == convert(amount, decimal), "tax_rate not taking the correct %"
        assert taxation_amount < convert(amount, decimal), "taxation more than original amount"
        assert amount - convert(taxation_amount, uint256) + convert(taxation_amount, uint256) == amount, "taxed amount not adding up to whole amount"
        assert self.balanceOf[msg.sender] >= convert(taxation_amount, uint256), "msg.sender doesn't have enough tokens"

        # pool passes tokens to the token contract for taxation and tracks amount for next _swap_back() operation
        self.balanceOf[msg.sender] -= convert(taxation_amount, uint256)
        self.balanceOf[self] += convert(taxation_amount, uint256)
        self._tokens_collected_for_next_sell += convert(taxation_amount, uint256)

        # finish transfering the tokens that weren't taxed
        self.balanceOf[msg.sender] -= amount - convert(taxation_amount, uint256)
        self.balanceOf[receiver] += amount - convert(taxation_amount, uint256)

        log Transfer(msg.sender, receiver, amount)

        return True

    # if user has a 25% tax, apply tax to receiver as well
    if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(msg.sender) > 0:
        vault_contract_interface(self._vault_address).update_tax_tracker_from_token_transfer(msg.sender, receiver)

    # normal finish transaction stuff
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)

    return True

@external
def transferFrom(sender:address, receiver: address, amount: uint256) -> bool:

    assert receiver not in [empty(address), self], "can't approve empty or owner address"
    
    # sender = boa.env.eoa or token contract
    # msg.sender = router02
    # receiver = pool

    print("amount: ", amount)
    print(" -> tax flag, sender, msg.sender: ", sender, msg.sender)
    assert self.allowance[sender][msg.sender] >= amount, "not enough approved for transferFrom"
    
    print("reciever, amount: ", receiver, amount)
    print(self.balanceOf[sender], self.staked_tokens_pool[sender])
    assert self.balanceOf[sender] >= amount + self.staked_tokens_pool[sender], "sender doesn't have enough tokens, or too many tokens staked"

    # _untaxed_liquidity_contribution will only be true when using self.add_liquidity_without_taxation
    if receiver == self._uniswap_pool_address and not self._untaxed_liquidity_contribution and not self._swapping:
        print("tax transferFrom trigger")
        # assume highest default tax rate
        tax_rate: decimal = .13

        if self.user_best_tier_nft[sender] > 0:
            tax_rate -= .02 * convert(self.user_best_tier_nft[sender], decimal)

        # check if traunches have been emptied
        if self.balanceOf[self._vault_address] > 0:
            if self.balanceOf[self._vault_address] > vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards():
                if self.balanceOf[self._vault_address] - vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards() >= 0:
                    if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(sender) > 0:
                        if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(sender) - self.balanceOf[self._vault_address] < 20000000000:
                            tax_rate += .25

        print("1")
        # calculate token taxation amount based on tax_rate to sell off for ETH payout
        taxation_amount: decimal = convert(amount, decimal) * tax_rate
        assert taxation_amount + convert(amount, decimal) * (1.0 - tax_rate) == convert(amount, decimal), "tax_rate not taking the correct %"
        assert taxation_amount < convert(amount, decimal), "taxation more than original amount"
        assert amount - convert(taxation_amount, uint256) + convert(taxation_amount, uint256) == amount, "taxed amount not adding up to whole amount"

        self.allowance[sender][msg.sender] -= convert(taxation_amount, uint256)  # router takes taxed allowance
        self.balanceOf[sender] -= convert(taxation_amount, uint256)              # uniswap contract loses tokens
        self.balanceOf[msg.sender] += convert(taxation_amount, uint256)          # router gets its tokens
        print("2")

        assert self.balanceOf[msg.sender] >= convert(taxation_amount, uint256), "msg.sender doesn't have enough tokens"

        # router passes its newly gained tokens to the token contract for taxation
        self.balanceOf[msg.sender] -= convert(taxation_amount, uint256)
        self.balanceOf[self] += convert(taxation_amount, uint256)

        print("3")
        self._swapping = True
        print("4")

        self._swap_back(convert(taxation_amount, uint256))

        print("4")
        # finish transfering the tokens that weren't taxed
        self.balanceOf[sender] -= amount - convert(taxation_amount, uint256)
        self.balanceOf[receiver] += amount - convert(taxation_amount, uint256)

        log Transfer(msg.sender, receiver, amount)

        self._swapping = False

        rewards_amount: uint256 = convert(convert(self._latest_tax_reward, decimal) * 0.9, uint256)
        treasury_amount: uint256 = convert(convert(self._latest_tax_reward, decimal) * 0.1, uint256)

        # update rewards collected and reset _latest_tax_reward so taxes can't be double counted
        self.eth_taxes_collected_in_wei_since_last_reward_call += rewards_amount
        self._latest_tax_reward = 0


        print("token contract ETH balance before: ", self.balance)
        # distribute taxes to treasury wallet
        send(self._fundraising_wallet, treasury_amount)
        print("token contract ETH balance after: ", self.balance)

        return True

    print("non - taxed transferFrom")
    self.allowance[sender][msg.sender] -= amount # router triggers transfer
    self.balanceOf[sender] -= amount             # uniswap contract loses tokens
    self.balanceOf[receiver] += amount           # pool gets tokens

    log Transfer(sender, receiver, amount)

    return True

@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @param spender The address that will execute on owner behalf.
    @param amount The amount of token to be transfered.
    """

    # make sure the user has enough tokens to approve approve
    assert self.balanceOf[msg.sender] >= amount, "sender can't supply the _approve"

    self._approve(msg.sender, spender, amount)

    log Approval(msg.sender, spender, amount)
    
    return True

@external
def burn(amount: uint256) -> bool:
    return self._burn(amount, msg.sender)

@payable
@external
def add_liquidity_without_taxation(amount: uint256) -> uint256[3]:
    assert msg.value >= 100000000000000 , "message must contain at least .0001 ETH (100000000000000 WEI)"
    assert self.balanceOf[msg.sender] >= amount , "user doesn't have enough tokens to provide liquidity"
    
    # approve router to perform transaction for contract
    self._approve(self, self._uniswap_router_address, amount)

    # move tokens from user to token contract for liquidity operation
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[self] += amount

    # disable taxes for the next operation
    self._untaxed_liquidity_contribution = True

    # add liquidity to the pool and forward lpt to user
    added_liquidity: uint256[3] = UniswapV2Router02(self._uniswap_router_address).addLiquidityETH(self, amount, 0, 0, msg.sender, block.timestamp, value=msg.value)

    # enable taxes again
    self._untaxed_liquidity_contribution = False

    return added_liquidity

@payable
@external
def test_swap(amount: uint256):

    memory_path: DynArray[address, 2] = [self._weth_address, self]
    # self._untaxed_liquidity_contribution = True

    # get some WETH?

    # swap WETH for Tokens with tax
    UniswapV2Router02(self._uniswap_router_address).swapExactETHForTokensSupportingFeeOnTransferTokens(amount, memory_path, msg.sender, block.timestamp, value=msg.value)

    # self._untaxed_liquidity_contribution = False

@payable
@external
def test_swap_back(sender:address, receiver: address, amount: uint256):
    print("start swap back")

    # assume highest default tax rate
    tax_rate: decimal = .13

    if self.user_best_tier_nft[sender] > 0:
        tax_rate -= .02 * convert(self.user_best_tier_nft[sender], decimal)

    # check if traunches have been emptied
    if self.balanceOf[self._vault_address] > 0:
        if self.balanceOf[self._vault_address] > vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards():
            if self.balanceOf[self._vault_address] - vault_contract_interface(self._vault_address)._tokens_used_for_staking_rewards() >= 0:
                if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(sender) > 0:
                    if vault_contract_interface(self._vault_address).twenty_percent_tax_tracker(sender) - self.balanceOf[self._vault_address] < 20000000000:
                        tax_rate += .25

    print("1")
    # calculate token taxation amount based on tax_rate to sell off for ETH payout
    taxation_amount: decimal = convert(amount, decimal) * tax_rate
    assert taxation_amount + convert(amount, decimal) * (1.0 - tax_rate) == convert(amount, decimal), "tax_rate not taking the correct %"
    assert taxation_amount < convert(amount, decimal), "taxation more than original amount"
    assert amount - convert(taxation_amount, uint256) + convert(taxation_amount, uint256) == amount, "taxed amount not adding up to whole amount"

    self.allowance[sender][msg.sender] -= convert(taxation_amount, uint256)  # router takes taxed allowance
    self.balanceOf[sender] -= convert(taxation_amount, uint256)              # uniswap contract loses tokens
    self.balanceOf[msg.sender] += convert(taxation_amount, uint256)          # router gets its tokens
    print("2")

    assert self.balanceOf[msg.sender] >= convert(taxation_amount, uint256), "msg.sender doesn't have enough tokens"

    # router passes its newly gained tokens to the token contract for taxation
    self.balanceOf[msg.sender] -= convert(taxation_amount, uint256)
    self.balanceOf[self] += convert(taxation_amount, uint256)

    print("3")
    self._swapping = True
    print("4")

    self._swap_back(convert(taxation_amount, uint256))

    print("4")
    # finish transfering the tokens that weren't taxed
    self.balanceOf[sender] -= amount - convert(taxation_amount, uint256)
    self.balanceOf[receiver] += amount - convert(taxation_amount, uint256)

    log Transfer(msg.sender, receiver, amount)

    self._swapping = False

    rewards_amount: uint256 = convert(convert(self._latest_tax_reward, decimal) * 0.9, uint256)
    treasury_amount: uint256 = convert(convert(self._latest_tax_reward, decimal) * 0.1, uint256)

    # update rewards collected and reset _latest_tax_reward so taxes can't be double counted
    self.eth_taxes_collected_in_wei_since_last_reward_call += rewards_amount
    self._latest_tax_reward = 0


    print("token contract ETH balance before: ", self.balance)
    # distribute taxes to treasury wallet
    send(self._fundraising_wallet, treasury_amount)
    print("token contract ETH balance after: ", self.balance)
    print("end swap back")

@external
def trigger_level_up(tokenId: uint256):

    # only owner of NFT can level it up
    assert nft_contract_interface(self._nft_contract_address).ownerOf(tokenId) == msg.sender, "only owner of NFT can level it up"

    # get tier of provided NFT
    tier: uint8 = nft_contract_interface(self._nft_contract_address).nft_tier(tokenId)

    assert tier >= 1, "NFT must above level 0"
    assert tier < 5, "NFT must be below level 5"
    
    # check if user has enough tokens to burn
    assert self.balanceOf[msg.sender] >= 400000, "not enough burnable tokens to level up!"

    # level up NFT
    nft_contract_interface(self._nft_contract_address).level_up(tokenId)
    
    # burn tokens after level_up in case of error
    self._burn(400000, msg.sender)

    # determine if best tier has been improved
    if tier + 1 > self.user_best_tier_nft[msg.sender]:
        self.user_best_tier_nft[msg.sender] = tier + 1

@external
def update_user_best_tier_nft_from_nft_contract(owner: address, tier_level: uint8) -> bool:
    assert msg.sender == self._nft_contract_address, "only the NFT contract can externally update best tier tracker"
    self.user_best_tier_nft[owner] = tier_level
    return True

@external
def trigger_mint():
    # check if user has enough tokens to burn
    assert self.balanceOf[msg.sender] >= 400000, "user doesn't have enough burnable tokens to mint!"
    
    # mint nft
    nft_contract_interface(self._nft_contract_address).mint_nft(msg.sender)

    # burn tokens
    self._burn(400000, msg.sender)

    # determine if this is the first NFT the user has minted and update tax tracker
    if 1 > self.user_best_tier_nft[msg.sender]:
        self.user_best_tier_nft[msg.sender] = 1

@internal
def _reward_token_stake_holders() -> bool:

    # make sure reward conditions are right
    if self.total_points_in_token_staking_pool > 0 and (block.timestamp - self._time_til_next_token_staking_payout) / 86400 >= 1 and self.eth_taxes_collected_in_wei_since_last_reward_call > 0:

        # iterate through users staking tokens
        for i in range(50000):

            # stop at end of minted NFTs
            if i > self.staked_users_count:
                break

            reward_ratio: decimal = (convert(self.staked_tokens_pool[self.staking_users_reference_list[i]], decimal) / convert(self.total_points_in_token_staking_pool, decimal))

            # distribute rewards to user (1 token = 1 point of the pool)
            self.staked_tokens_rewards[self.staking_users_reference_list[i]] += convert(convert(self.eth_taxes_collected_in_wei_since_last_reward_call, decimal) * reward_ratio, uint256)
    
        # reset ETH reward tracker
        self.eth_taxes_collected_in_wei_since_last_reward_call = 0
        self._time_til_next_token_staking_payout = block.timestamp
        
    return True

@external
def stake_tokens(amount: uint256) -> bool:
    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()

    # check balance of sender
    assert self.balanceOf[msg.sender] >= amount + self.staked_tokens_pool[msg.sender], "sender doesn't have enough tokens to stake"
    
    # if new staker, add to address tracking list for rewards
    if self.staked_tokens_pool[msg.sender] == 0:
        self.staking_users_reference_list[self.staked_users_count] = msg.sender
        self.staked_users_count += 1

    # add tokens to staking pool for tracking
    self.staked_tokens_pool[msg.sender] += amount

    # increment the total number of tokens in the rewards pool
    self.total_points_in_token_staking_pool += amount

    # TODO: update tokens in circulation?

    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()

    return True

# NOTE: vyper requires fixed values in for loops as a hardcoded protection
# mechanism to prevent memory overflow on chain so this logic looks excessive...
@external
def unstake_tokens(amount: uint256) -> bool:
    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()

    # make sure they aren't unstaking negative tokens
    assert self.staked_tokens_pool[msg.sender] >= amount, "unstaking more tokens than staked!"
    assert msg.sender in self.staking_users_reference_list, "something went wrong if user has tokens staked but not in reference list"

    # if staked properly, update hashmap
    self.staked_tokens_pool[msg.sender] -= amount

    # decrement total rewards in the pool
    self.total_points_in_token_staking_pool -= amount

    # only remove user from rewards pool if they completely unstake
    if self.staked_tokens_pool[msg.sender] == 0:
        # remove address from rewards tracker
        # iterate over all addresses to find user address
        for i in range(50000):
            
            # upper limit to make sure iterator doesn't go further than needed
            if i > self.staked_users_count:
                    break

            # move all addresses after user address down one index to preserve memory
            if self.staking_users_reference_list[i] == msg.sender:
            
                for j in range(50000):

                    # j needs to catch up to i
                    if j < i:
                        continue
                    
                    # upper limit to make sure iterator doesn't go further than needed
                    if j > self.staked_users_count:
                        break

                    # replace current address in list with next address
                    # (this effectively removes the user address)
                    self.staking_users_reference_list[j] = self.staking_users_reference_list[j + 1]
                
                # decrement user counts
                self.staked_users_count -= 1

                # don't break and continue through remaining addresses to make sure no duplicates

        assert msg.sender not in self.staking_users_reference_list

    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()

    return True

@external
def check_token_rewards() -> uint256:
    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()

    return self.staked_tokens_rewards[msg.sender]    

@external
def claim_token_staking_reward() -> bool:

    # attempt to trigger rewards cycle if conditions meet requirements
    self._reward_token_stake_holders()
    
    rewards_amount_in_wei: uint256 = self.staked_tokens_rewards[msg.sender]

    assert rewards_amount_in_wei > 0, "no rewards earned yet"

    # check if token contract has enough ETH to payout rewards
    assert self.balance >= rewards_amount_in_wei, "not enough ETH to reward user"

    # distribute ETH from token contract to user's wallet
    send(msg.sender, rewards_amount_in_wei)

    # reset rewards once claimed
    self.staked_tokens_rewards[msg.sender] = 0

    return True