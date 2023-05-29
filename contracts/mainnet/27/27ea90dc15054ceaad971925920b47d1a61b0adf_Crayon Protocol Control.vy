# @version ^0.3.7
# (c) Crayon Protocol Authors, 2023

"""
@title Crayon Protocol Control
"""


MAX_NUM_DESKS: constant(int128) = 20
MAX_SNAPSHOTS: constant(int128) = 5
MIN_WAITING_PERIOD: constant(uint256) = 40320

interface Desk:
    def deposit_cumul_reward() -> uint256: view
    def borrow_cumul_reward() -> uint256: view
    def user_loans(_user: address) -> uint256: view
    def balanceOf(_user: address) -> uint256: view
    def horizons(_horizon: uint256) -> uint256: view
    def update_cumul_rewards(): nonpayable
    def set_flashloan_fee(_new_flashloan_fee: uint256): nonpayable
    def set_liquidation_bonus(_new_liquidation_bonus: uint256): nonpayable
    def set_fee(
        _horizon: uint256,
        _new_fee: uint256
    ): nonpayable

interface XCtoken:
    def mint(
        _to: address,
        _value: uint256
    ): nonpayable

event NewAdmin:
    new_admin: address

event NewFee:
    desk: indexed(address)
    horizon: indexed(uint256)
    new_fee: uint256
    from_block: uint256

event NewFlashFee:
    desk: indexed(address)
    new_flash_fee: uint256
    from_block: uint256

event NewLiquidationBonus:
    desk: indexed(address)
    new_liquidation_bonus: uint256
    from_block: uint256

struct DeskRates:
    borrow_rate: uint256
    deposit_rate: uint256

struct Provider:
    is_registered: bool
    percentage: uint256 # percentage of reward Provider keeps; percentage = 5 means 5%

struct Snapshot:
    amount: uint256
    reward_index: uint256
    provider: address

struct New_desk_setting:
    is_active: bool
    setting: uint256
    from_block: uint256

is_c_control: public(bool)

admin: public(address)
token_contract: public(address)

# registered desks
num_desks: public(uint256)
is_registered_desk: public(HashMap[address, bool])
desk_rates: HashMap[address, DeskRates]

# desk updates
new_desk_fee: HashMap[address, HashMap[uint256, New_desk_setting]]
new_desk_flashloan_fee: HashMap[address, New_desk_setting]
new_desk_liquidation_bonus: HashMap[address, New_desk_setting]

# registered front-end providers. after un-registering, providers cannot register again with the same address. recall the address is only used for reward token attribution and transfer. if it's the address of a smart contract then the provider will have to re-deploy the smart contract or collect the rewards in a wallet outside the smart contract
providers: HashMap[address, Provider]
unregistered_providers: public(HashMap[address, bool])

# user_desks holds keys of target HashMap in user snapshots
user_desks: HashMap[address, DynArray[address, MAX_NUM_DESKS]]
# user snapshots are user => desk => snapshots
deposit_snapshots: HashMap[address, HashMap[address, DynArray[Snapshot, MAX_SNAPSHOTS]]]
borrow_snapshots: HashMap[address, HashMap[address, DynArray[Snapshot, MAX_SNAPSHOTS]]]
# earned tokens are user => amount
earned_tokens: public(HashMap[address, uint256])

@external
def __init__(
    _admin: address,
    _token: address
):
    # yes, redundant. only here because some conversions depend on this being true
    assert MAX_NUM_DESKS <= max_value(int128)
    # make sure token contract address was set
    assert _token != empty(address)

    self.admin = _admin
    self.token_contract = _token
    
    self.is_c_control = True

    # 0x provider is the "provider" for users not dependent on a third party
    self.providers[empty(address)] = Provider({is_registered: True, percentage: 0})

@external
def register_desk(
    _desk: address,
    _borrow_rate: uint256,
    _deposit_rate: uint256
):
    """
    @dev Register new desk. _borrow_rates[i] and _deposit_rates[i] apply to _desks[i]
    @param _desk New desk to be registered
    @param _borrow_rate Total amount of XCRAY to be awarded to _desk borrowers per block
    @param _deposit_rate Total amount of XCRAY to be awarded to _desk depositors per block
    """

    assert msg.sender == self.admin
    # the list of new rates should include rates for the new desk as well as all existing ones
    self.num_desks += 1  
    self.is_registered_desk[_desk] = True
    self.desk_rates[_desk] = DeskRates({borrow_rate: _borrow_rate, deposit_rate: _deposit_rate})

@external
def unregister_desk(
    _desk: address
):
    """
    @dev Remove _desk from the desks that receive XCRAY awards
    @param _desk The desk to be removed
    """

    assert msg.sender == self.admin

    self.is_registered_desk[_desk] = False
    self.num_desks -= 1

@external
def register_provider(
    _provider_percentage: uint256
):
    """
    @notice Register msg.sender as a provider (of front end in most common use case). Reverts if msg.sender is already registered or had registered in the past and then unregistered
    @param _provider_percentage The percentage of reward tokens earned by its users that the provider will keep. A value of 2 means the provider keeps 2% of the rewards earned by its users
    """
    # make sure (a) it's not already registered (b) it had not un-registered in the past
    assert not self.providers[msg.sender].is_registered and not self.unregistered_providers[msg.sender]

    self.providers[msg.sender] = Provider({is_registered: True, percentage: _provider_percentage})

@external
def unregister_provider(
):
    """
    @notice Unregister msg.sender as a provider. Reverts if msg.sender is not already registered as a provider. Provider still earns rewards from activity prior to un-registering
    """

    assert self.providers[msg.sender].is_registered

    percentage : uint256 = self.providers[msg.sender].percentage
    self.providers[msg.sender] = Provider({is_registered: False, percentage: percentage})
    self.unregistered_providers[msg.sender] = True

@external
@view
def is_registered_provider(
    _provider: address
) -> bool:
    """
    @notice Is _provider registered as a provider?
    @param _provider The address
    @return True/False. True means _provider has registered as a provider and has specified the percentage of its users' reward tokens that it will keep
    """

    return self.providers[_provider].is_registered

@external
@view
def provider_percentage(
    _provider: address
) -> uint256:
    """
    @notice Return the percentage of the cumulated reward tokens a provider keeps. A return value of 5 means the provider keeps 5% of its users' rewards
    @param _provider The address of the provider
    @return The percentage the provider keeps. x means x%
    """

    return self.providers[_provider].percentage

@external
def add_deposit_snapshot(
    _user: address,
    _amount: uint256,
    _provider: address,
    _deposit_reward_index: uint256
):
    """
    @notice Add a snapshot of the user's deposit for calculating the reward earned over the next period
    @dev This is meant to be called by a deployed desk
    @param _user The address of the user
    @param _amount The user's deposit balance at the end of the previous period
    @param _provider The front end provider
    @param _deposit_reward_index The growth of rewards per unit of deposit over the past period
    """

    desk : address = msg.sender
    assert self.is_registered_desk[desk] and self.providers[_provider].is_registered

    snapshots : DynArray[Snapshot, MAX_SNAPSHOTS] = self.deposit_snapshots[_user][desk]
    num_user_snapshots : uint256 = len(snapshots)
    if num_user_snapshots == 0:
        # this might be a desk _user is using for the first time
        self._add_desk_if_new(_user, desk)            
    elif num_user_snapshots == convert(MAX_SNAPSHOTS, uint256):
        self._update_reward(_user, _amount, _deposit_reward_index, snapshots)
        self.deposit_snapshots[_user][desk] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])

    self.deposit_snapshots[_user][desk].append(Snapshot({amount: _amount, reward_index: _deposit_reward_index, provider: _provider}))

@external
def add_borrow_snapshot(
    _user: address,
    _amount: uint256,
    _provider: address,
    _borrow_reward_index: uint256
):
    """
    @notice Add a snapshot of the user's loan for calculating the reward earned over the next period
    @dev This is meant to be called by a deployed desk
    @param _user The address of the user
    @param _amount The user's loan balance at the end of the previous period
    @param _provider The front end provider
    @param _borrow_reward_index The growth of rewards per unit borrowed over the past period
    """

    desk : address = msg.sender
    assert self.is_registered_desk[msg.sender] and self.providers[_provider].is_registered

    snapshots : DynArray[Snapshot, MAX_SNAPSHOTS] = self.borrow_snapshots[_user][desk]
    num_user_snapshots : uint256 = len(snapshots)
    if num_user_snapshots == 0:
        # this might be a desk _user is using for the first time
        self._add_desk_if_new(_user, desk)            
    elif num_user_snapshots == convert(MAX_SNAPSHOTS, uint256):
        self._update_reward(_user, _amount, _borrow_reward_index, snapshots)
        self.borrow_snapshots[_user][desk] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])

    self.borrow_snapshots[_user][desk].append(Snapshot({amount: _amount, reward_index: _borrow_reward_index, provider: _provider}))

@internal
def _add_desk_if_new(
    _user: address,
    _desk: address
):
    """
    @dev Add new desk to the array of desks _user has deposited in or borrowed from
    @param _user The user address
    @param _desk The address of the desk being added
    """

    user_desks : DynArray[address, MAX_NUM_DESKS] = self.user_desks[_user]
    found : bool = False
    for d in user_desks:
        if d == _desk:
            found = True
            break
    if not found:
        assert len(user_desks) < convert(MAX_NUM_DESKS, uint256)
        self.user_desks[_user].append(_desk)

@internal
def _update_reward(
    _user: address,
    _amount: uint256,
    _latest_reward_index: uint256,
    _snapshots: DynArray[Snapshot, MAX_SNAPSHOTS]
):
    """
    @dev Update the amount of XCRAY already earned by _user
    @param _user User address
    @param _amount The deposit or loan amount the user owns
    """

    reward : uint256 = 0
    provider_reward : uint256 = 0
    provider : address = empty(address)
    reward, provider_reward, provider = self._calculate_reward(_user, _amount, _latest_reward_index, _snapshots)

    self.earned_tokens[provider] += provider_reward
    self.earned_tokens[_user] += reward - provider_reward

@internal
@view
def _calculate_reward(
    _user: address,
    _amount: uint256,
    _latest_reward_index: uint256,
    _snapshots: DynArray[Snapshot, MAX_SNAPSHOTS]
) -> (uint256, uint256, address):
    """
    @dev Calculate the tokens earned by _user on one desk
    @param _user Address for which rewards are to be calculated
    @param _amount The amount of deposits or loans _user held at the end of latest period
    @param _latest_reward_index The level of the reward index at the end of the latest period
    @param _snapshots The snapshots of _user's positions over time
    @return Return triplet (total reward, provider reward, the provider to credit)
    """

    num_snapshots : uint256 = len(_snapshots)
    if num_snapshots == 0:
        return 0, 0, empty(address)
    
    provider : address = _snapshots[num_snapshots-1].provider
    reward : uint256 = _amount * (_latest_reward_index - _snapshots[num_snapshots-1].reward_index)
    ri_prev : uint256 = 0
    count : uint256 = 0
    for s in _snapshots:
        if count > 0:
            # reward balance at the end of period with reward growth over the past period
            reward += s.amount * (s.reward_index - ri_prev)
        ri_prev = s.reward_index
        if count == 0:
            count = 1
    provider_reward : uint256 = reward * self.providers[provider].percentage / 100
    return reward, provider_reward, provider
    
@external
@nonreentrant('lock')
def mint_all_reward_token(
    _user: address
):
    """
    @notice Credit _user with all the reward tokens accumulated by _user on all the desks
    @param _user The address whose rewards are being claimed
    """

    self._mint_reward_token(_user, self.user_desks[_user])

@external
@nonreentrant('lock')
def mint_reward_token(
    _user: address,
    _desks: DynArray[address, MAX_NUM_DESKS]
):
    """
    @notice Credit _user with the reward tokens accumulated by _user on _desks
    @param _user The address whose rewards are being claimed
    @param _desks Desks on which _user accumulated rewards and for which rewards are being claimed
    """

    self._mint_reward_token(_user, _desks)

@internal
def _mint_reward_token(
    _user: address,
    _desks: DynArray[address, MAX_NUM_DESKS]
):
    """
    @dev Credit _user with the reward tokens accumulated by _user on _desks
    @param _user The address whose rewards are being claimed
    @param _desks Desks on which _user accumulated rewards and for which rewards are being claimed
    """

    snapshots : DynArray[Snapshot, MAX_SNAPSHOTS] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])
    num_snapshots : uint256 = 0
    # loop through the desks
    for d in _desks:
        
        Desk(d).update_cumul_rewards()
        
        # do reward from loans
        snapshots = self.borrow_snapshots[_user][d]
        num_snapshots = len(snapshots)
        if num_snapshots != 0:
            borrow_index : uint256 = Desk(d).borrow_cumul_reward()
            user_loan : uint256 = Desk(d).user_loans(_user)
            self._update_reward(_user, user_loan, borrow_index, snapshots)
            self.borrow_snapshots[_user][d] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])
            if user_loan != 0:
                self.borrow_snapshots[_user][d].append(Snapshot({amount: user_loan, reward_index: borrow_index, provider: snapshots[num_snapshots - 1].provider}))

        # now do reward from deposit
        snapshots = self.deposit_snapshots[_user][d]
        num_snapshots = len(snapshots)
        if num_snapshots != 0:
            deposit_index : uint256 = Desk(d).deposit_cumul_reward()
            user_deposit : uint256 = Desk(d).balanceOf(_user)
            self._update_reward(_user, user_deposit, deposit_index, snapshots)
            self.deposit_snapshots[_user][d] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])
            if user_deposit != 0:
                self.deposit_snapshots[_user][d].append(Snapshot({amount: user_deposit, reward_index: deposit_index, provider: snapshots[num_snapshots - 1].provider}))

    reward_amount : uint256 = self.earned_tokens[_user]
    if reward_amount != 0:
        self.earned_tokens[_user] = 0 
        XCtoken(self.token_contract).mint(_user, reward_amount)

@external
@view
def reward_balanceOf(
    _user: address,
    _desks: DynArray[address, MAX_NUM_DESKS]
) -> uint256:
    """
    @notice Return the balance of rewards _user accumulated on _desks, as of the last update of the cumulative rewards on those desks
    @param _user The user whose reward balance is sought
    @param _desks The desks where rewards are to be checked
    @return The amount of reward tokens user can claim
    """

    snapshots : DynArray[Snapshot, MAX_SNAPSHOTS] = empty(DynArray[Snapshot, MAX_SNAPSHOTS])
    num_snapshots : uint256 = 0
    reward : uint256 = 0
    provider_reward : uint256 = 0
    provider : address = empty(address)
    total_reward : uint256 = self.earned_tokens[_user]
    for d in _desks:

        # do reward from loans
        snapshots = self.borrow_snapshots[_user][d]
        num_snapshots = len(snapshots)
        if num_snapshots != 0:
            borrow_index : uint256 = Desk(d).borrow_cumul_reward()
            user_loan : uint256 = Desk(d).user_loans(_user)
            reward, provider_reward, provider = self._calculate_reward(_user, user_loan, borrow_index, snapshots)
            total_reward += reward
       
        # reward from deposits
        snapshots = self.deposit_snapshots[_user][d]
        num_snapshots = len(snapshots)
        if num_snapshots != 0:
            deposit_index : uint256 = Desk(d).deposit_cumul_reward()
            user_deposit : uint256 = Desk(d).balanceOf(_user)
            reward, provider_reward, provider = self._calculate_reward(_user, user_deposit, deposit_index, snapshots)
            total_reward += reward

    return total_reward

@external
@view
def get_reward_parameters(
    _desk: address
) -> (uint256, uint256):
    """
    @notice Return the amount of reward tokens distributed to borrowers and depositors per block
    @param _desk The desk whose reward parameters are sought
    @return Tuple: first component is borrower rate, second is depositor rate
    """

    rates: DeskRates = self.desk_rates[_desk]
    return rates.borrow_rate, rates.deposit_rate

@external
def set_desk_rates(
    _desks: DynArray[address, MAX_NUM_DESKS],
    _borrow_rates: DynArray[uint256, MAX_NUM_DESKS],
    _deposit_rates: DynArray[uint256, MAX_NUM_DESKS]
):
    """
    @dev Set new XCRAY award rates for all registered desks. _borrow_rates[i] and _deposit_rates[i] apply to _desks[i]
    @param _desks The array containing all registered desks. Must contain all registered desks
    @param _borrow_rates Array containing the total amount of XCRAY to be awarded to borrowers
    @param _deposit_rates Array containing the total amount of XCRAY to be awarded to depositors 
    """
    
    assert msg.sender == self.admin

    _num_desks : uint256 = len(_desks)
    assert _num_desks == self.num_desks and _num_desks == len(_borrow_rates) and _num_desks == len(_deposit_rates)

    # some acrobatics to meet vyper's limitations. conversion is safe since _num_desks <= MAX_NUM_DESKS <= max_value(int128). argument to range() has to be a literal, hence the if statement in the loop
    count : int128 = convert(_num_desks, int128)
    for i in range(MAX_NUM_DESKS):
        if i == count:
            break
        assert self.is_registered_desk[_desks[i]] == True
        self.desk_rates[_desks[i]] = DeskRates({borrow_rate: _borrow_rates[i], deposit_rate: _deposit_rates[i]})

@external
def schedule_new_fee(
    _horizon: uint256,
    _new_fee: uint256,
    _desk: address
):
    """
    @dev Must have _new_fee > 0 and _horizon must be an existing horizon
    @param _new_fee The new fee for loans
    """

    assert msg.sender == self.admin and self.is_registered_desk[_desk]
    # make sure the new fee is being set for an existing horizon. can't change horizons
    assert Desk(_desk).horizons(_horizon) != 0

    from_block : uint256 = block.number + MIN_WAITING_PERIOD
    self.new_desk_fee[_desk][_horizon] = New_desk_setting({
        is_active: True,
        setting: _new_fee,
        from_block: from_block
    })

    log NewFee(_desk, _horizon, _new_fee, from_block)


@external
def schedule_new_flashloan_fee(
    _new_flashloan_fee: uint256,
    _desk: address
): 
    """
    @dev Must have _new_flashloan_fee > 0
    @param _new_flashloan_fee The new fee for flashloans
    """

    assert msg.sender == self.admin and self.is_registered_desk[_desk]

    from_block : uint256 = block.number + MIN_WAITING_PERIOD
    self.new_desk_flashloan_fee[_desk] = New_desk_setting({
        is_active: True,
        setting: _new_flashloan_fee,
        from_block: from_block
    })

    log NewFlashFee(_desk, _new_flashloan_fee, from_block)

@external
def schedule_new_liquidation_bonus(
    _new_liquidation_bonus: uint256,
    _desk: address
): 
    """
    @dev Must have _new_liquidation_bonus > 0 and 10000 + _new_liquidation_bonus < self.value_to_loan_ratio * 100
    @param _new_liquidation_bonus The new liquidation bonus
    """

    assert msg.sender == self.admin and self.is_registered_desk[_desk]

    from_block : uint256 = block.number + MIN_WAITING_PERIOD
    self.new_desk_liquidation_bonus[_desk] = New_desk_setting({
        is_active: True,
        setting: _new_liquidation_bonus, 
        from_block: from_block
    })

    log NewLiquidationBonus(_desk, _new_liquidation_bonus, from_block)

@external
def commit_new_fee(
    _desk: address,
    _horizon: uint256
):
    """
    @dev Execute scheduled new fee for desk
    @param _desk The desk address
    """

    assert msg.sender == self.admin

    new_fee_sched : New_desk_setting = self.new_desk_fee[_desk][_horizon]
    assert new_fee_sched.is_active and block.number >= new_fee_sched.from_block

    Desk(_desk).set_fee(_horizon, new_fee_sched.setting)

    self.new_desk_fee[_desk][_horizon] = empty(New_desk_setting)

@external
def commit_new_flashloan_fee(
    _desk: address
):
    """
    @dev Execute scheduled new flashloan fee for desk
    @param _desk The desk address
    """

    assert msg.sender == self.admin

    new_fee_sched : New_desk_setting = self.new_desk_flashloan_fee[_desk]
    assert new_fee_sched.is_active and block.number >= new_fee_sched.from_block

    Desk(_desk).set_flashloan_fee(new_fee_sched.setting)

    self.new_desk_flashloan_fee[_desk] = empty(New_desk_setting)

@external
def commit_new_liquidation_bonus(
    _desk: address
):
    """
    @dev Execute scheduled new liquidation bonus for desk
    @param _desk The desk address
    """

    assert msg.sender == self.admin

    new_value : New_desk_setting = self.new_desk_liquidation_bonus[_desk]
    assert new_value.is_active and block.number >= new_value.from_block

    Desk(_desk).set_liquidation_bonus(new_value.setting)

    self.new_desk_liquidation_bonus[_desk] = empty(New_desk_setting)

@external
def set_admin(
    _new_admin: address
):
    assert msg.sender == self.admin

    self.admin = _new_admin

    log NewAdmin(_new_admin)