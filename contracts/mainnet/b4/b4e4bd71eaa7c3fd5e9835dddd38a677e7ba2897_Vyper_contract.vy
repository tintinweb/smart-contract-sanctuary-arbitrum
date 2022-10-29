# The XEN Fork: A modified & simplified version of XEN, written in Vyper.
#
# @dev The following portion of ERC-20 code was adapted from Takayuki Jimba's ERC-20 token contract
#   @dev Implementation of ERC-20 token standard.
#   @author Takayuki Jimba (@yudetamago)
#   https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
#   https://github.com/vyperlang/vyper/blob/master/examples/tokens/ERC20.vy 

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Redeemed:
    user: indexed(address)
    xenContract: indexed(address)
    tokenContract: indexed(address)
    xenAmount: uint256
    tokenAmount: uint256

event RankClaimed:
    user: indexed(address)
    term: uint256
    rank: uint256

event MintClaimed:
    user: indexed(address)
    rewardAmount: uint256

name: public(String[32])
symbol: public(String[32])
decimals: public(uint8)
globalRank: public(uint256)
genesisTs: public(uint256)
activeMinters: public(uint256)
REWARD_AMPLIFIER_START: constant(uint256) = 3000
REWARD_AMPLIFIER_END: constant(uint256) = 1

ONE_ETHER: constant(uint256) = 10**18

SECONDS_IN_AN_HOUR: constant(uint256) = 3600
SECONDS_IN_DAY: constant(uint256) = 86400
MIN_TERM: constant(uint256) = 0
WITHDRAWAL_WINDOW_DAYS: constant(uint256) = 7

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
balanceOf: public(HashMap[address, uint256])
# By declaring `allowance` as public, vyper automatically generates the `allowance()` getter
allowance: public(HashMap[address, HashMap[address, uint256]])
# By declaring `totalSupply` as public, we automatically create the `totalSupply()` getter
totalSupply: public(uint256)
minter: address


struct MintInfo:
    user: address
    term: uint256 
    maturityTs: uint256 
    rank: uint256 
    amplifier: uint256 
    eaaRate: uint256

userMints: public(HashMap[address, MintInfo])

@external
def __init__(_name: String[32], _symbol: String[32], _decimals: uint8, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** convert(_decimals, uint256)
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = msg.sender
    self.genesisTs = block.timestamp
    self.globalRank = 1
    log Transfer(empty(address), msg.sender, init_supply)



@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@internal
def _mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert _to != empty(address)
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)

@internal
def _calculateRewardAmplifier() -> uint256:
    amplifierDecrease: uint256 = (block.timestamp - self.genesisTs) / SECONDS_IN_DAY
    if (amplifierDecrease < REWARD_AMPLIFIER_START):
        return max(REWARD_AMPLIFIER_START - amplifierDecrease, REWARD_AMPLIFIER_END)
    else:
        return REWARD_AMPLIFIER_END


@internal
def _calculateMintReward(
        cRank: uint256,
        term: uint256,
        maturityTs: uint256,
        amplifier: uint256,
        eeaRate: uint256,
    ) -> (uint256):
        secsLate: uint256 = block.timestamp - maturityTs
        penalty: uint256 =  (2 ** (secsLate / SECONDS_IN_DAY + 3 - 1)) / WITHDRAWAL_WINDOW_DAYS
        rankDelta: uint256 = max(self.globalRank - cRank, 2)
        EAA: uint256 = (1000 + eeaRate)
        reward: uint256 = self._getGrossReward(rankDelta, amplifier, term, EAA)
        return (reward * (100 - penalty)) / 100

@internal
@view
def _getGrossReward(
    rankDelta: uint256 ,
    amplifier: uint256,
    term: uint256,
    eaa: uint256,
) -> (uint256):
    log128: uint256 = isqrt(rankDelta)
    reward128: uint256 = log128 * amplifier * term * eaa
    return reward128 / 1000

@internal
def _cleanUpUserMint():
    self.userMints[msg.sender] = empty(MintInfo)
    self.activeMinters -= 1

@external
@view
def getGrossReward (
        rankDelta: uint256 ,
        amplifier: uint256,
        term: uint256,
        eaa: uint256,
    ) -> (uint256):
    return self._getGrossReward(rankDelta, amplifier, term, eaa)


@external
def claimRank(termInSeconds: uint256):
    termSec: uint256 = termInSeconds
    assert termSec > MIN_TERM, "CRank: Term less than min"
    assert termSec < 8640000, "CRank: Term more than current max term"
    assert self.userMints[msg.sender].rank == 0, "CRank: Mint already in progress"

    mintInfo: MintInfo = MintInfo({
        user: msg.sender,
        term: termInSeconds,
        maturityTs: block.timestamp + termSec,
        rank: self.globalRank,
        amplifier: self._calculateRewardAmplifier(),
        eaaRate: 1
    })
    self.userMints[msg.sender] = mintInfo
    self.activeMinters += 1
    self.globalRank += 1
    log RankClaimed(msg.sender, termInSeconds, self.globalRank)


@external
def claimMintReward():
    mintInfo: MintInfo = self.userMints[msg.sender]
    assert mintInfo.rank > 0, "CRank: No mint exists"
    assert block.timestamp > mintInfo.maturityTs, "CRank: Mint maturity not reached"

    rewardAmount: uint256 = self._calculateMintReward(
        mintInfo.rank,
        mintInfo.term,
        mintInfo.maturityTs,
        mintInfo.amplifier,
        mintInfo.eaaRate
    ) * (ONE_ETHER / (tx.gasprice + 1))
    self._mint(msg.sender, rewardAmount)

    self._cleanUpUserMint()
    log MintClaimed(msg.sender, rewardAmount)

@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != empty(address)
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, empty(address), _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)