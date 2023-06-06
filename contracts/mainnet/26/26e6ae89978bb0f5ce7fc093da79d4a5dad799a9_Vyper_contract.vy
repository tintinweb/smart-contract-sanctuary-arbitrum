# @version 0.3.7

struct CoinPriceUSD:
    coin: address
    price: uint256

struct DepositWithdrawalParams:
    coinPositionInCPU: uint256
    _amount: uint256
    cpu: DynArray[CoinPriceUSD, 50]
    expireTimestamp: uint256

struct OracleParams:
    cpu: DynArray[CoinPriceUSD, 50]
    expireTimestamp: uint256

interface FeeOracle:
    def isInTarget(coin: address) -> bool: view

interface AddressRegistry:
    def getCoinToStrategy(a: address) -> DynArray[address,100]: view
    def feeOracle() -> FeeOracle: view

interface IERC20:
    def transferFrom(a: address, b: address, c: uint256) -> bool: nonpayable
    def balanceOf(a: address) -> uint256: view
    def transfer(a: address, c: uint256) -> bool: nonpayable

interface IVault:
    def deposit(dwp: DepositWithdrawalParams): nonpayable
    def withdraw(dwp: DepositWithdrawalParams): nonpayable
    def claimDebt(a: address, b: uint256): nonpayable
    def transferFrom(a: address, b: address, c: uint256) -> bool: nonpayable
    

struct MintRequest:
    inputTokenAmount: uint256
    minAlpAmount: uint256
    coin: IERC20
    requester: address
    expire: uint256

struct BurnRequest:
    maxAlpAmount: uint256
    outputTokenAmount: uint256
    coin: IERC20
    requester: address
    expire: uint256

mintQueue: HashMap[uint256, MintRequest]
burnQueue: HashMap[uint256, BurnRequest]
mintQueueFront: public(uint256)
mintQueueBack: public(uint256)
burnQueueFront: public(uint256)
burnQueueBack: public(uint256)
tokenDeposits: public(HashMap[address, uint256])
owner: public(address)
# dark oracle is an ethereum account hosted on the secure HSM on google cloud platform running the code to capture prices from coingecko pro price stream, coinAPI price stream and historic on chain pricing from the most traded dex for the particular coin.
# it will process mint and burn requests of users using the price it derived. 
# The dark oracle is opensourced and a real-only service account will be provided to the public to verify our claims any time.
darkOracle: public(address)
fee: public(uint256)
feeDenominator: public(constant(uint256)) = as_wei_value(1, "ether")
burntAmounts: public(HashMap[address, uint256])
vault: address
addressRegistry: AddressRegistry
event MintRequestAdded:
    mr: MintRequest
event BurnRequestAdded:
    br: BurnRequest
event MintRequestProcessed:
    op: OracleParams
event BurnRequestProcessed:
    op: OracleParams
event MintRequestCanceled:
    mr: MintRequest
event BurnRequestRefunded:
    br: BurnRequest
event Initialized:
    vault: indexed(address)
    addressRegistry: AddressRegistry
    darkOracle: indexed(address)
event SetFee:
    fee: indexed(uint256)
event Suicide: pass

@external
def __init__(_vault: address, _addressRegistry: AddressRegistry, _darkOracle: address):
    assert not _vault == convert(0, address), "Invalid _vault address"
    assert not _darkOracle == convert(0, address), "Invalid _darkOracle address"
    self.owner = msg.sender
    self.vault = _vault
    self.addressRegistry = _addressRegistry
    self.darkOracle = _darkOracle
    log Initialized(_vault, _addressRegistry, _darkOracle)

@external
def setFee(_fee: uint256):
    assert msg.sender == self.owner, "Not a permitted user"
    assert _fee <= as_wei_value(0.5, "ether"), "Invalid fee amount"
    self.fee = _fee
    log SetFee(_fee)

# request vault to mint ALP tokens and sends payment tokens to vault afterwards
@external 
@nonreentrant("router")
def processMintRequest(dwp: OracleParams):
    assert self.addressRegistry.feeOracle().isInTarget(dwp.cpu[0].coin), "Invalid coin for oracle"
    assert msg.sender == self.darkOracle, "Not a permitted user"
    assert self.mintQueueBack != 0, "No mint request"
    mr: MintRequest = self.popMintQueue()
    if block.timestamp > mr.expire:
        raise "Request expired"
    before_balance: uint256 = IERC20(self.vault).balanceOf(self)
    _amountToMint: uint256 = mr.inputTokenAmount
    # taken off protocol fee
    if self.fee > 0:
        _amountToMint = _amountToMint * (feeDenominator - self.fee) / feeDenominator
    IVault(self.vault).deposit(DepositWithdrawalParams({
        coinPositionInCPU: self.getCoinPositionInCPU(dwp.cpu, mr.coin.address),
        _amount: _amountToMint,
        cpu: dwp.cpu,
        expireTimestamp: dwp.expireTimestamp
    }))
    after_balance: uint256 = IERC20(self.vault).balanceOf(self)
    delta: uint256 = after_balance - before_balance
    if delta < mr.minAlpAmount:
        raise "Not enough ALP minted"
    assert mr.coin.transfer(self.vault, _amountToMint), "Coin transfer failed"
    assert IERC20(self.vault).transfer(mr.requester, delta, default_return_value=True), "ALP transfer failed"
    self.tokenDeposits[mr.coin.address] = self.tokenDeposits[mr.coin.address] - mr.inputTokenAmount
    log MintRequestProcessed(dwp)

@external
@nonreentrant("router")
def refundMintRequest():
    assert self.mintQueueBack != 0, "No mint request"
    mr: MintRequest = self.popMintQueue()
    assert msg.sender == self.darkOracle or mr.expire < block.timestamp, "Not a permitted user"
    assert mr.coin.transfer(mr.requester, mr.inputTokenAmount, default_return_value=True)
    self.tokenDeposits[mr.coin.address] = self.tokenDeposits[mr.coin.address] - mr.inputTokenAmount
    log MintRequestCanceled(mr)

# request vault to burn ALP tokens and mint debt tokens to requester afterwards.
@external 
@nonreentrant("router")
def processBurnRequest(dwp: OracleParams):
    assert self.addressRegistry.feeOracle().isInTarget(dwp.cpu[0].coin), "Invalid coin for oracle"
    assert msg.sender == self.darkOracle, "Not a permitted user"
    assert self.burnQueueBack != 0, "No burn request"
    br: BurnRequest = self.popBurnQueue()
    if block.timestamp > br.expire:
        raise "Request expired"
    before_balance: uint256 = IERC20(self.vault).balanceOf(self)
    coinPositionInCPU: uint256 = self.getCoinPositionInCPU(dwp.cpu, br.coin.address)
    IVault(self.vault).withdraw(DepositWithdrawalParams({
        coinPositionInCPU: coinPositionInCPU,
        _amount: br.outputTokenAmount,
        cpu: dwp.cpu,
        expireTimestamp: dwp.expireTimestamp
    }))
    after_balance: uint256 = IERC20(self.vault).balanceOf(self)
    delta: uint256 = before_balance - after_balance
    # taken off protocol fee
    if self.fee > 0:
        delta = delta * (feeDenominator + self.fee) / feeDenominator
    if delta > br.maxAlpAmount:
        raise "Too much ALP burned"
    IVault(self.vault).claimDebt(dwp.cpu[coinPositionInCPU].coin, br.outputTokenAmount)
    assert br.coin.transfer(br.requester, br.outputTokenAmount), "Coin transfer failed"
    assert IERC20(self.vault).transfer(br.requester, br.maxAlpAmount - delta, default_return_value=True), "ALP transfer failed"
    self.tokenDeposits[self.vault] = self.tokenDeposits[self.vault] - br.maxAlpAmount
    log BurnRequestProcessed(dwp)

@external
@nonreentrant("router")
def refundBurnRequest():
    assert self.burnQueueBack != 0, "No burn request"
    br: BurnRequest = self.popBurnQueue()
    assert msg.sender == self.darkOracle or br.expire < block.timestamp, "Not a permitted user"
    assert IERC20(self.vault).transfer(br.requester, br.maxAlpAmount, default_return_value=True), "ALP transfer failed"
    self.tokenDeposits[self.vault] = self.tokenDeposits[self.vault] - br.maxAlpAmount
    log BurnRequestRefunded(br)

@external
@nonreentrant("router")
def submitMintRequest(mr: MintRequest):
    assert self.addressRegistry.feeOracle().isInTarget(mr.coin.address), "Invalid coin for oracle"
    assert mr.requester == msg.sender, "Invalid requester"
    assert mr.coin.address != convert(0, address), "Eth deposit is not allowed"
    assert self.mintQueueBack - self.mintQueueFront + 1 < 100, "Mint queue limited"
    self.pushMintQueue(mr)
    assert mr.coin.transferFrom(msg.sender, self, mr.inputTokenAmount), "Coin transfer failed"
    self.tokenDeposits[mr.coin.address] = self.tokenDeposits[mr.coin.address] + mr.inputTokenAmount 
    log MintRequestAdded(mr)


@external
@nonreentrant("router")
def submitBurnRequest(br: BurnRequest):
    assert self.addressRegistry.feeOracle().isInTarget(br.coin.address), "Invalid coin for oracle"
    assert br.requester == msg.sender, "Invalid requester"
    assert br.coin.address != convert(0, address), "Eth withdraw is not allowed"
    assert self.burnQueueBack - self.burnQueueFront + 1 < 100, "Burn queue limited"
    self.pushBurnQueue(br)
    assert IERC20(self.vault).transferFrom(msg.sender, self, br.maxAlpAmount), "ALP transfer failed"
    self.tokenDeposits[self.vault] = self.tokenDeposits[self.vault] + br.maxAlpAmount
    log BurnRequestAdded(br)

@external
@nonreentrant("router")
def rescueStuckTokens(token: IERC20, amount: uint256):
    assert msg.sender == self.owner, "Not a permitted user"
    assert amount + self.tokenDeposits[token.address] <= token.balanceOf(self), "Too much amount to rescue"
    assert token.transfer(self.owner, amount, default_return_value=True), "Token transfer failed"

@external
def suicide():
    assert msg.sender == self.owner, "Not a permitted user"
    assert self.balance == 0, "Too many eth"
    assert self.mintQueueBack == 0, "Mint queue is not empty"
    assert self.burnQueueBack == 0, "Burn queue is not empty"
    log Suicide()
    selfdestruct(self.owner)

@external
@view
def mintQueueLength() -> uint256:
    if self.mintQueueBack != 0:
        return self.mintQueueBack - self.mintQueueFront + 1
    return 0

@external
@view
def burnQueueLength() -> uint256:
    if self.burnQueueBack != 0:
        return self.burnQueueBack - self.burnQueueFront + 1
    return 0


@internal
def getCoinPositionInCPU(cpu: DynArray[CoinPriceUSD, 50], coin: address) -> uint256:
    position: uint256 = 0

    for coinPrice in cpu:
        if coinPrice.coin == coin:
            return position
        position = position + 1
    raise "False"

@internal
def pushMintQueue(mr: MintRequest):
    if self.mintQueueBack == 0:
        self.mintQueueFront = 1
        self.mintQueueBack = 1
        self.mintQueue[1] = mr
    else:
        self.mintQueue[self.mintQueueBack + 1] = mr
        self.mintQueueBack = self.mintQueueBack + 1

@internal
def popMintQueue() -> MintRequest:
    if self.mintQueueBack != 0:
        mr: MintRequest = self.mintQueue[self.mintQueueFront]
        self.mintQueue[self.mintQueueFront] = empty(MintRequest)
        if self.mintQueueFront == self.mintQueueBack:
            self.mintQueueFront = 0
            self.mintQueueBack = 0
        else:
            self.mintQueueFront = self.mintQueueFront + 1
        return mr
    return empty(MintRequest)

@internal
def pushBurnQueue(br: BurnRequest):
    if self.burnQueueBack == 0:
        self.burnQueueFront = 1
        self.burnQueueBack = 1
        self.burnQueue[1] = br
    else:
        self.burnQueue[self.burnQueueBack + 1] = br
        self.burnQueueBack = self.burnQueueBack + 1

@internal
def popBurnQueue() -> BurnRequest:
    if self.burnQueueBack != 0:
        br: BurnRequest = self.burnQueue[self.burnQueueFront]
        self.burnQueue[self.burnQueueFront] = empty(BurnRequest)
        if self.burnQueueFront == self.burnQueueBack:
            self.burnQueueFront = 0
            self.burnQueueBack = 0
        else:
            self.burnQueueFront = self.burnQueueFront + 1
        return br
    return empty(BurnRequest)