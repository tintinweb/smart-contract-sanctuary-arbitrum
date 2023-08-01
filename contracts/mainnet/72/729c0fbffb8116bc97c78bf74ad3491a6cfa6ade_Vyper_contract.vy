from vyper.interfaces import ERC20

interface VRFConsumerInterface:
  def requestRandomWords(): payable
  def getRandomNumber() -> uint256: view

event Deposit:
  player: indexed(address)
  godfather: indexed(address)
  amount: uint256

event Withdraw:
  player: indexed(address)
  amount: uint256

event Bet:
  player: indexed(address)
  pick: indexed(uint256)
  round: indexed(uint256)
  amount: uint256

event PickingClosed:
  round: indexed(uint256)

event PickingOpened:
  round: indexed(uint256)

event WinnerPicked:
  round: indexed(uint256)
  winner: indexed(uint256)

event PlayerWon:
  player: indexed(address)
  amount: uint256

event PlayerLost:
  player: indexed(address)
  amount: uint256

event DustCollected:
  amount: uint256

MAX_PLAYERS_PER_ROUND: constant(uint256) = 1000

name: public(String[32])
balanceOf: public(HashMap[address, uint256])
owner: public(address)

currentRound: public(uint256)
isPickingClosed: public(bool)

roundsPlayersPicks: public(HashMap[uint256, HashMap[address, uint256[4]]])
roundsWinners: public(HashMap[uint256, uint256])

winnersTax: public(uint256)
winnersTaxWallet: public(address)

hasAlreadyDeposited: HashMap[address, bool]
godfathers: HashMap[address, address]
godfatherTax: public(uint256)

usdtContract: ERC20
VRFConsumer: VRFConsumerInterface

currentRoundPlayersCount: uint256
currentRoundPlayers: address[MAX_PLAYERS_PER_ROUND]

playersLockedBalances: HashMap[address, uint256]
lastRandomNumber: uint256

@external
def __init__(_vrfConsumerAddress: address, _usdtAddress: address):
  self.name = "VroomGame"
  self.owner = msg.sender
  self.currentRound = 0
  self.lastRandomNumber = 0
  self.currentRoundPlayersCount = 0
  self.isPickingClosed = True
  self.VRFConsumer = VRFConsumerInterface(_vrfConsumerAddress)
  self.usdtContract = ERC20(_usdtAddress)
  self.godfatherTax = 1
  self.winnersTax = 5
  self.winnersTaxWallet = 0x00357AeAD4fd588339a9E5aEA411F0356d085FbB

@external
@nonreentrant("deposit")
def deposit(_amount: uint256, _godfather: address = empty(address)) -> bool:
  assert _amount > 0, "Deposit must be greater than 0"

  # godfather is optional
  # - check its not 0x0, check its not the sender, check the sender has not already a godfather, and its first deposit
  if _godfather != empty(address) and _godfather != msg.sender and self.godfathers[msg.sender] == empty(address) and self.hasAlreadyDeposited[msg.sender] == False:
    self.godfathers[msg.sender] = _godfather

  # keep track if first deposit or not
  self.hasAlreadyDeposited[msg.sender] = True
  self.balanceOf[msg.sender] += _amount
  self.usdtContract.transferFrom(msg.sender, self, _amount)
  log Deposit(msg.sender, _godfather, _amount)
  return True

@external
@nonreentrant("withdraw")
def withdraw(_amount: uint256) -> bool:
  assert _amount > 0, "Withdraw must be greater than 0"
  assert self.balanceOf[msg.sender] >= _amount, "Insufficient balance"
  self.balanceOf[msg.sender] -= _amount
  self.usdtContract.transfer(msg.sender, _amount)
  log Withdraw(msg.sender, _amount)
  return True

@external
def bet(_pick: uint256, _amount: uint256) -> bool:
  assert self.currentRound > 0, "Game has not started yet"
  assert self.isPickingClosed == False, "Round is closed"
  assert _pick >= 1 and _pick <= 4, "Pick must be between 1 and 4"
  assert _amount > 0, "Amount must be greater than 0"
  assert self.balanceOf[msg.sender] >= _amount, "Insufficient balance"

  if self._hasPlayerPicked(msg.sender) == False:
    self.currentRoundPlayers[self.currentRoundPlayersCount] = msg.sender
    self.currentRoundPlayersCount += 1

  # we pass _pick - 1, because the pick is 1 based but the array is 0 based
  self.roundsPlayersPicks[self.currentRound][msg.sender][_pick - 1] += _amount
  self.playersLockedBalances[msg.sender] += _amount
  self.balanceOf[msg.sender] -= _amount
  log Bet(msg.sender, _pick, self.currentRound, _amount)

  return True

@external
def start() -> bool:
  assert msg.sender == self.owner, "Only owner can start a new round"
  assert self.currentRound == 0, "Game has already started"
  self.currentRound += 1
  self.isPickingClosed = False
  return True

@external
def closeRound() -> bool:
  assert msg.sender == self.owner, "Only owner can close a round"
  assert self.currentRound > 0, "Game has not started yet"
  assert self.isPickingClosed == False, "Round is already closed"
  self.isPickingClosed = True
  self.VRFConsumer.requestRandomWords()
  log PickingClosed(self.currentRound)
  return True

@external
def pickWinner() -> uint256:
  assert msg.sender == self.owner, "Only owner can pick a winner"
  assert self.currentRound > 0, "Game has not started yet"
  assert self.isPickingClosed == True, "Round is not closed yet"
  assert self.roundsWinners[self.currentRound] == 0, "Winner has already been picked"

  randomNumber: uint256 = self.VRFConsumer.getRandomNumber()
  assert randomNumber != self.lastRandomNumber, "Chainlink VRF returned the same number"

  winner: uint256 = randomNumber % 4 + 1

  self.lastRandomNumber = randomNumber
  self.roundsWinners[self.currentRound] = winner
  log WinnerPicked(self.currentRound, winner)

  # we need to credit the winners balances
  # we pass winner - 1, because the pick is 1 based but the array is 0 based
  self._creditWinners(winner - 1)

  # we only reset the `currentRoundPlayersCount`
  # because we will overide the `currentRoundPlayers` array when needed
  # this saves a lot of gas
  self.currentRoundPlayersCount = 0

  self.isPickingClosed = False
  self.currentRound += 1
  log PickingOpened(self.currentRound)

  return winner

@external
def ownerSetTaxWallet(_address: address) -> bool:
  assert msg.sender == self.owner, "Only owner can set tax wallet"
  self.winnersTaxWallet = _address
  return True

@external
def ownerSetWinnersTax(_amount: uint256) -> bool:
  assert msg.sender == self.owner, "Only owner can set winners tax"
  assert _amount >= 0 and _amount <= 100, "Winners tax must be between 0 and 100"
  self.winnersTax = _amount
  return True

@external
def ownerSetGodfatherTax(_amount: uint256) -> bool:
  assert msg.sender == self.owner, "Only owner can set godfather tax"
  assert _amount >= 0 and _amount <= 100, "Godfather tax must be between 0 and 100"
  self.godfatherTax = _amount
  return True

@external
def emergencyOwnerRetryRandomNumber() -> bool:
  # for some reason if Chainlink VRF fails and returns same random number
  # we can call this method to just retry the random number generation
  assert msg.sender == self.owner, "Only owner can retry random number"
  assert self.currentRound > 0, "Game has not started yet"
  self.VRFConsumer.requestRandomWords()
  return True

@external
def emergencyOwnerUnlockGame() -> bool:
  # this method is used to refund player balances stuck in a betting-round
  # for instance if `pickWinner()` runs out of gas, we can call this method (bug in contract?)
  # or if Chainlink VRF fails for some reason, we are relying on external services
  # better be safe than sorry, right?
  assert msg.sender == self.owner, "Only owner can unlock the game"
  assert self.currentRound > 0, "Game has not started yet"

  # unsure we pause the game
  self.isPickingClosed = True

  for i in range(MAX_PLAYERS_PER_ROUND):
    if i >= self.currentRoundPlayersCount:
      break

    player: address = self.currentRoundPlayers[i]
    lockedBalance: uint256 = self.playersLockedBalances[player]

    if lockedBalance > 0:
      self.balanceOf[player] += lockedBalance
      self.playersLockedBalances[player] = 0

  return True

@external
def emergencyOwnerWithdraw() -> bool:
  # for what-ever reason, if something goes wrong and game is stuck or player balance are stuck
  # we have this method to withdraw all the USDT and then handle the issue manually, or to rebalance
  # onto an updated a fixed contract (this is meant to be used in real case of emergency)
  assert msg.sender == self.owner, "Only owner can emergency withdraw"
  self.usdtContract.transfer(self.owner, self.usdtContract.balanceOf(self))
  return True

@internal
def _hasPlayerPicked(_player: address) -> bool:
  arr: uint256[4] = self.roundsPlayersPicks[self.currentRound][_player]
  return arr[0] > 0 or arr[1] > 0 or arr[2] > 0 or arr[3] > 0

@internal
def _creditWinners(winner: uint256) -> bool:
  # first we need to calculate the total amount of USDT in the winning picks
  # and the total amount of losers picks
  totalWinnersBetAmount: uint256 = 0
  totalLosersBetAMount: uint256 = 0

  for i in range(MAX_PLAYERS_PER_ROUND):
    # stop loop if we reached the end of number of players in this round
    if i >= self.currentRoundPlayersCount:
      break

    # unlock the player balance
    self.playersLockedBalances[self.currentRoundPlayers[i]] = 0

    # sum the total amount of USDT in the winning picks
    player: address = self.currentRoundPlayers[i]
    playerPicks: uint256[4] = self.roundsPlayersPicks[self.currentRound][player]
    totalWinnersBetAmount += playerPicks[winner]

    #  sum the total amount of USDT in the losers picks
    playerLosses: uint256 = 0

    for i2 in range(4):
      if i2 != winner:
        playerLosses += playerPicks[i2]

    if playerLosses > 0:
      totalLosersBetAMount += playerLosses
      log PlayerLost(player, playerLosses)

  # now we need to take the winners tax
  winnersTaxAmount: uint256 = totalLosersBetAMount * self.winnersTax / 100
  totalLosersBetAMount -= winnersTaxAmount
  self.balanceOf[self.winnersTaxWallet] += winnersTaxAmount

  totalCredited: uint256 = 0

  # now re-loop to credit the winners from their percentage of the losers picks
  for i in range(MAX_PLAYERS_PER_ROUND):
    if i >= self.currentRoundPlayersCount:
      break

    player: address = self.currentRoundPlayers[i]
    playerPicks: uint256[4] = self.roundsPlayersPicks[self.currentRound][player]

    if playerPicks[winner] != 0:
      percentage: uint256 = playerPicks[winner] * 100 / totalWinnersBetAmount
      amountWon: uint256 = totalLosersBetAMount * percentage / 100

      # check for godfather
      # we remove the godfather tax from the amount won only
      # we must keep track of totalCredited for dust collection
      if self.godfathers[player] != empty(address):
        godfatherAmount: uint256 = amountWon * self.godfatherTax / 100
        amountWon -= godfatherAmount
        totalCredited += godfatherAmount
        self.balanceOf[self.godfathers[player]] += godfatherAmount

      amountToCredit: uint256 = playerPicks[winner] + amountWon
      totalCredited += amountWon
      self.balanceOf[player] += amountToCredit
      log PlayerWon(player, amountToCredit)

  # check if we have some left-overs
  if totalCredited < totalLosersBetAMount:
    dust: uint256 = totalLosersBetAMount - totalCredited
    self.balanceOf[self.winnersTaxWallet] += dust
    log DustCollected(dust)

  return True