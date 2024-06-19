#pragma version 0.3.10
#pragma evm-version cancun

"""
@title Governance Contract
@license Copyright 2023, 2024 Biggest Lab Co Ltd, Benjamin Scherrey, Sajal Kayan, and Eike Caldeweyher
@author BiggestLab
@notice Governance for AdapterVault
"""
event StrategyWithdrawal:
    Nonce: uint256
    vault: address

event StrategyVote:
    Nonce: uint256
    vault: address
    GuardAddress: indexed(address)
    Endorse: bool

event NewGuard:
    GuardAddress: indexed(address)

event GuardRemoved:
    GuardAddress: indexed(address)

event GuardSwap:
    OldGuardAddress: indexed(address)
    NewGuardAddress: indexed(address)

event GovernanceContractChanged:
    Voter: address
    NewGovernance: indexed(address)
    VoteCount: uint256
    TotalGuards: uint256

event VoteForNewGovernance:
    NewGovernance: indexed(address)
    Voter: indexed(address)

event NewVault:
    vault: indexed(address)

event VaultRemoved:
    vault: indexed(address)

event VaultSwap:
    OldVaultAddress: indexed(address)
    NewVaultAddress: indexed(address)

event OwnerChanged:
    new_owner: indexed(address)
    old_owner: indexed(address)      

#LPRatios

struct AdapterStrategy:
    adapter: address
    ratio: uint256

struct ProposedStrategy:
    LPRatios: AdapterStrategy[MAX_ADAPTERS]
    min_proposer_payout: uint256

event StrategyProposal:
    strategy : Strategy
    ProposerAddress: address
    LPRatios: AdapterStrategy[MAX_ADAPTERS]
    min_proposer_payout: uint256
    vault: address

event StrategyActivation:
    strategy: Strategy
    ProposerAddress: address
    LPRatios: AdapterStrategy[MAX_ADAPTERS]
    min_proposer_payout: uint256
    vault: address

struct Strategy:
    Nonce: uint256
    ProposerAddress: address
    LPRatios: AdapterStrategy[MAX_ADAPTERS]
    min_proposer_payout: uint256
    TSubmitted: uint256
    TActivated: uint256
    Withdrawn: bool
    no_guards: uint256
    VotesEndorse: DynArray[address, MAX_GUARDS]
    VotesReject: DynArray[address, MAX_GUARDS]
    VaultAddress: address
    
# Contract assigned storage 
contractOwner: public(address)
MAX_GUARDS: constant(uint256) = 5
MAX_ADAPTERS: constant(uint256) = 5
MAX_VAULTS: constant(uint256) = 25
DEFAULT_MIN_PROPOSER_PAYOUT: constant(uint256) = 0  # TODO: Need a reasonable value here based on expected gas costs of paying proposal fees.
LGov: public(DynArray[address, MAX_GUARDS])
TDelay: public(uint256)
no_guards: public(uint256)

CurrentStrategyByVault: public(HashMap[address, Strategy])
PendingStrategyByVault: public(HashMap[address, Strategy])

VotesGCByVault: public(HashMap[address, HashMap[address, address]])
MIN_GUARDS: constant(uint256) = 1
NextNonceByVault: public(HashMap[address, uint256])
VaultList: public(DynArray[address, MAX_VAULTS])


interface AdapterVault:
    def set_strategy(Proposer: address, Strategies: AdapterStrategy[MAX_ADAPTERS], min_proposer_payout: uint256) -> bool: nonpayable
    def replaceGovernanceContract(NewGovernance: address) -> bool: nonpayable


@external
def __init__(contractOwner: address, _tdelay: uint256):
    """
    @notice The function provides a way to initialize the contract
    @param contractOwner Governance Contract Owner
    @param _tdelay Time delay until a proposed strategy can be replaced
    """
    self.contractOwner = contractOwner
    self.TDelay = _tdelay
    if _tdelay == empty(uint256):
        self.TDelay = 2592000 # 30 days vs 21600 (6 hours)


@internal
def _submitStrategy(strategy: ProposedStrategy, vault: address) -> uint256:
    assert msg.sender in self.LGov, "Only Guards may submit strategies."

    if self.NextNonceByVault[vault] == 0:
        self.NextNonceByVault[vault] += 1

    # No using a Strategy function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    assert vault in self.VaultList, "Vault not in vault list!"        

    pending_strat: Strategy = self.PendingStrategyByVault[vault]

    # Confirm there's no currently pending strategy for this vault so we can replace the old one.

    # First is it the same as the current one?
    # Otherwise has it been withdrawn? 
    # Otherwise, has it been short circuited down voted? 
    # Has the period of protection from being replaced expired already?
    reject_votes : uint256 = 0
    for guard_addr in self.LGov:
        if guard_addr in pending_strat.VotesReject:
            reject_votes += 1

    nonces_match : bool =  (self.CurrentStrategyByVault[vault].Nonce == pending_strat.Nonce)                
    at_least_one_reject : bool = reject_votes > 0
    strategy_rejected : bool = (reject_votes >= pending_strat.no_guards/2+1)
    strategy_timedout : bool = (convert(block.timestamp, decimal) > (convert(pending_strat.TSubmitted, decimal)+(convert(self.TDelay, decimal))))
    assert  nonces_match or (pending_strat.Withdrawn == True) or at_least_one_reject and \
            strategy_rejected or strategy_timedout, "Invalid proposed strategy!"

    # Confirm msg.sender Eligibility
    # Confirm msg.sender is not blacklisted

    strat : Strategy = empty(Strategy)

    strat.Nonce = self.NextNonceByVault[vault]
    self.NextNonceByVault[vault] += 1

    strat.ProposerAddress = msg.sender
    strat.LPRatios = strategy.LPRatios
    strat.min_proposer_payout = strategy.min_proposer_payout
    strat.TSubmitted = block.timestamp
    strat.TActivated = 0    
    strat.Withdrawn = False
    strat.no_guards = len(self.LGov)
    strat.VotesEndorse = empty(DynArray[address, MAX_GUARDS])
    strat.VotesReject = empty(DynArray[address, MAX_GUARDS])
    strat.VaultAddress = vault

    self.PendingStrategyByVault[vault] = strat

    log StrategyProposal(strat, msg.sender, strat.LPRatios, strategy.min_proposer_payout, vault)

    return strat.Nonce


@external
def submitStrategy(strategy: ProposedStrategy, vault: address) -> uint256:
    """
    @notice This function provides a way to Propose a Strategy for a specific Vault
    @param strategy The Proposed Strategy (for a Vault) to evaluate 
    @param vault The vault address (for the Proposed Strategy) to evaluate
    @return The nonce for a strategy submitted for a specific vault
    """
    return self._submitStrategy(strategy, vault)


@external
def withdrawStrategy(Nonce: uint256, vault: address):
    """
    @notice This function provides a way to withdraw a proposed strategy for a specific vault
    @param Nonce Integer (for the Proposed Strategy, by Vault) to evaluate
    @param vault The vault address (for the Proposed Strategy) to evaluate
    """
    pending_strat : Strategy = self.PendingStrategyByVault[vault]

    # No using a Strategy function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    #Check to see if vault is in vault list
    assert vault in self.VaultList, "vault not in vault list!"  

    #Check to see that the pending strategy is not the current strategy
    assert (self.CurrentStrategyByVault[vault].Nonce != pending_strat.Nonce), "Cannot withdraw Current Strategy"

    #Check to see that the pending strategy's nonce matches the nonce we want to withdraw
    assert pending_strat.Nonce == Nonce, "Cannot Withdraw Strategy if its not Pending Strategy"

    #Check to see that sender is eligible to withdraw
    assert pending_strat.ProposerAddress == msg.sender

    #Withdraw Pending Strategy
    self.PendingStrategyByVault[vault].Withdrawn = True

    log StrategyWithdrawal(Nonce, vault)


@external
def endorseStrategy(Nonce: uint256, vault: address):
    """
    @notice This function provides a way to vote for a proposed strategy for a specific vault
    @param Nonce Integer (for the Proposed Strategy, by Vault) to evaluate
    @param vault The vault address (for the Proposed Strategy) to evaluate
    """
    pending_strat : Strategy = self.PendingStrategyByVault[vault]

    # No using a Strategy function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    #Check to see if vault is in vault list
    assert vault in self.VaultList, "vault not in vault list!"  

    #Check to see that the pending strategy is not the current strategy
    assert self.CurrentStrategyByVault[vault].Nonce != pending_strat.Nonce, "Cannot Endorse Strategy thats already  Strategy"

    #Check to see that the pending strategy's nonce matches the nonce we want to endorse
    assert pending_strat.Nonce == Nonce, "Cannot Endorse Strategy if its not Pending Strategy"

    #Check to see that sender is eligible to vote
    assert msg.sender in self.LGov, "Sender is not eligible to vote"

    #Check to see that sender has not already voted
    assert msg.sender not in pending_strat.VotesReject
    assert msg.sender not in pending_strat.VotesEndorse

    #Vote to endorse strategy
    self.PendingStrategyByVault[vault].VotesEndorse.append(msg.sender)

    log StrategyVote(Nonce, vault, msg.sender, True)


@external
def rejectStrategy(Nonce: uint256, vault: address, replacementStrategy : ProposedStrategy = empty(ProposedStrategy)):
    """
    @notice This function provides a way to vote against a proposed strategy for a specific vault
    @param Nonce Integer (for the Proposed Strategy, by Vault) to evaluate
    @param vault The vault address (for the Proposed Strategy) to evaluate
    """
    pending_strat : Strategy = self.PendingStrategyByVault[vault]

    # No using a Strategy function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    #Check to see if vault is in vault list
    assert vault in self.VaultList, "vault not in vault list!"  

    #Check to see that the pending strategy is not the current strategy
    assert self.CurrentStrategyByVault[vault].Nonce != pending_strat.Nonce, "Cannot Reject Strategy thats already Current Strategy"

    #Check to see that the pending strategy's nonce matches the nonce we want to reject
    assert pending_strat.Nonce == Nonce, "Cannot Reject Strategy if its not Pending Strategy"

    #Check to see that sender is eligible to vote
    assert msg.sender in self.LGov

    #Check to see that sender has not already voted
    assert msg.sender not in pending_strat.VotesReject
    assert msg.sender not in pending_strat.VotesEndorse

    strategy_already_rejected : bool = (len(pending_strat.VotesReject) >= pending_strat.no_guards/2+1)

    #Vote to reject strategy
    self.PendingStrategyByVault[vault].VotesReject.append(msg.sender)

    strategy_ultimately_rejected : bool = (len(pending_strat.VotesReject) >= pending_strat.no_guards/2+1)

    # If there is a replacement strategy suggested and this is the vote that ultimately decides the thing...
    if replacementStrategy.LPRatios[0].adapter != empty(address): # Can't test against empty(ProposedStrategy) due to Vyper issue #2638.
        if (not strategy_already_rejected) and strategy_ultimately_rejected:    
            # Replace the current pending but rejected strategy with this new one.
            self._submitStrategy(replacementStrategy, vault)

    log StrategyVote(Nonce, vault, msg.sender, False)


@external
def activateStrategy(Nonce: uint256, vault: address):
    """
    @notice This function provides a way to activate a proposed strategy (for a specific vault) which becomes the current strategy
    @param Nonce Integer (for the Proposed Strategy, by Vault) to evaluate
    @param vault The vault address (for the Proposed Strategy) to evaluate
    """
    pending_strat : Strategy = self.PendingStrategyByVault[vault]

    # No using a Strategy function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    #Check to see if vault is in vault list
    assert vault in self.VaultList, "vault not in vault list!"  

    #Confirm there is a currently pending strategy
    assert (self.CurrentStrategyByVault[vault].Nonce != pending_strat.Nonce), "Invalid Nonce."
    assert (pending_strat.Withdrawn == False), "Strategy is withdrawn."

    #Confirm strategy is approved by guards
    endorse_votes : uint256 = 0
    reject_votes : uint256 = 0
    for guard_addr in self.LGov:
        if guard_addr in pending_strat.VotesEndorse:
            endorse_votes += 1
        if guard_addr in pending_strat.VotesReject:
            reject_votes += 1

    assert (endorse_votes >= (len(self.LGov)/2)+1) or \
           ((pending_strat.TSubmitted + self.TDelay) < block.timestamp), "Premature activation with insufficience endorsements."
    assert reject_votes <= endorse_votes, "Strategy was rejected."

    #Confirm Pending Strategy is the Strategy we want to activate
    assert pending_strat.Nonce == Nonce, "Incorrect strategy nonce."

    #Make Current Strategy and Activate Strategy
    self.CurrentStrategyByVault[vault] = self.PendingStrategyByVault[vault]

    AdapterVault(vault).set_strategy(self.CurrentStrategyByVault[vault].ProposerAddress, self.CurrentStrategyByVault[vault].LPRatios, pending_strat.min_proposer_payout)

    self.CurrentStrategyByVault[vault].TActivated = block.timestamp

    log StrategyActivation(self.CurrentStrategyByVault[vault], self.CurrentStrategyByVault[vault].ProposerAddress, self.CurrentStrategyByVault[vault].LPRatios, pending_strat.min_proposer_payout, vault)
 

@external
def addGuard(GuardAddress: address):
    """
    @notice This function provides a way to add a guard to the contract's government
    @param GuardAddress The guard's address (to add to the contract's government) to evaluate
    """
    #Check to see that sender is the contract owner
    assert msg.sender == self.contractOwner, "Cannot add guard unless you are contract owner"

    #Check to see if there is the max amount of Guards
    assert len(self.LGov) <= MAX_GUARDS, "Cannot add anymore guards"

    #Check to see that the Guard being added is a valid address
    assert GuardAddress != empty(address), "Cannot add ZERO_ADDRESS"

    #Check to see that GuardAddress is not already in self.LGov
    assert GuardAddress not in self.LGov, "Guard already exists"

    #Add new guard address as the last in the list of guards
    self.LGov.append(GuardAddress)

    log NewGuard(GuardAddress)


@external
def removeGuard(GuardAddress: address):
    """
    @notice This function provides a way to remove a guard to the contract's government
    @param GuardAddress The guard's address (to remove from the contract's government) to evaluate
    """
    #Check to see that sender is the contract owner
    assert msg.sender == self.contractOwner, "Cannot remove guard unless you are contract owner"

    last_index: uint256 = len(self.LGov) 
    #Check to see if there are any guards on the list of guards
    assert last_index != 0, "No guards to remove."

    # Correct size to zero offset position.
    last_index -= 1
    
    #Run through list of guards to find the index of the one we want to remove
    current_index: uint256 = 0
    for guard_addr in self.LGov:
        if guard_addr == GuardAddress: break
        current_index += 1

    #Make sure that GuardAddress is a guard on the list of guards
    assert GuardAddress == self.LGov[current_index], "GuardAddress not a current Guard."    

    # Replace Current Guard with last
    self.LGov[current_index] = self.LGov[last_index]

    # Eliminate the redundant one at the end.
    self.LGov.pop()

    log GuardRemoved(GuardAddress)


@external
def swapGuard(OldGuardAddress: address, NewGuardAddress: address):
    """
    @notice This function provides a way to swap a guard from the contract's government with a new guard
    @param OldGuardAddress The guard's address (to swap out from the contract's government) to evaluate
    @param NewGuardAddress The guard's address (to swap into the contract's government) to evaluate
    """
    #Check that the sender is authorized to swap a guard
    assert msg.sender == self.contractOwner, "Cannot swap guard unless you are contract owner"

    #Check that the guard we are swapping in is a valid address
    assert NewGuardAddress != empty(address), "Cannot add ZERO_ADDRESS"

    #Check that the guard we are swapping in is not on the list of guards already
    assert NewGuardAddress not in self.LGov, "New Guard is already a Guard."

    #Run through list of guards to find the index of the one we want to swap out
    current_index: uint256 = 0 
    for guard_addr in self.LGov:
        if guard_addr == OldGuardAddress: break
        current_index += 1

    #Make sure that OldGuardAddress is a guard on the list of guards
    assert OldGuardAddress == self.LGov[current_index], "OldGuardAddress not a current Guard."

    #Replace OldGuardAddress with NewGuardAddress
    self.LGov[current_index] = NewGuardAddress

    log GuardSwap(OldGuardAddress, NewGuardAddress)


# Have to do this to give public access to DynArray.
# https://github.com/vyperlang/vyper/issues/2897
@external
@view
def guards() -> DynArray[address, MAX_GUARDS]:
    return self.LGov


@external
@view
def checkGuard(GuardAddress: address) -> bool:
    return GuardAddress in self.LGov


@external
@view
def checkVault(VaultAddress: address) -> bool:
    return VaultAddress in self.VaultList


@external
def replaceGovernance(NewGovernance: address, vault: address):
    """
    @notice This function provides a way to replace this governance contract out with a new governance contract (per vault)
    @param NewGovernance The new governance contract's address to evaluate
    @param vault A vault address (for this governance contract) to evaluate
    """
    VoteCount: uint256 = 0
    Voter: address = msg.sender
    TotalGuards: uint256 = len(self.LGov)
    # No using function without a vault
    assert len(self.VaultList) > 0, "Cannot call Strategy function with no vault"

    #Check to see if vault is in vault list
    assert vault in self.VaultList, "vault not in vault list!"  

    #Check if there are enough guards to change governance
    assert len(self.LGov) >= MIN_GUARDS

    #Check if sender is a guard
    assert msg.sender in self.LGov

    #Check if new contract address is not the current
    assert NewGovernance != self

    #Check if new contract address is valid address
    assert NewGovernance != empty(address)

    #Check if sender has voted, if not log new vote
    if self.VotesGCByVault[vault][msg.sender] != NewGovernance: 
        log VoteForNewGovernance(NewGovernance, msg.sender)

    #Record Vote
    self.VotesGCByVault[vault][msg.sender] = NewGovernance

    #Add Vote to VoteCount
    for guard_addr in self.LGov:
        if self.VotesGCByVault[vault][guard_addr] == NewGovernance:
            VoteCount += 1

    if len(self.LGov) == VoteCount:
        AdapterVault(vault).replaceGovernanceContract(NewGovernance)
        
        # Clear out the old votes.
        for guard_addr in self.LGov:
            self.VotesGCByVault[vault][guard_addr] = empty(address)


        log GovernanceContractChanged(Voter, NewGovernance, VoteCount, TotalGuards)


@external
def addVault(vault: address): 
    """
    @notice This function provides a way to add a vault to the list of vaults governed by this contract
    @param vault A vault address (to add to this governance contract) to evaluate
    """
    # Must be Contract Owner to add vault
    assert msg.sender == self.contractOwner

    # Must have space to add vault
    assert len(self.VaultList) <= MAX_VAULTS

    # Must be a real vault address
    assert vault != empty(address)

    # Must not already be in vault list
    assert vault not in self.VaultList

    # Add vault to vault list
    self.VaultList.append(vault)

    # Log new vault
    log NewVault(vault)


@external
def removeVault(vault: address):
    """
    @notice This function provides a way to remove a vault from the list of vaults governed by this contract
    @param vault A vault address (to remove from this governance contract) to evaluate
    """
    # Must be Contract owner to remove vault
    assert msg.sender == self.contractOwner

    last_vault: uint256 = len(self.VaultList) 
    # Vault List must not be empty
    assert last_vault != 0

    # Correct size to zero offset position.
    last_vault -= 1
    
    #Run through list of vaults to find the one we want to remove
    current_vault: uint256 = 0
    for vault_addr in self.VaultList:
        if vault_addr == vault: break
        current_vault += 1

    # Make sure that vault is the vault we want to remove from vault list
    assert vault == self.VaultList[current_vault], "vault not a current vault."    

    # Replace current vault with the last
    self.VaultList[current_vault] = self.VaultList[last_vault]

    # Remove the last
    self.VaultList.pop()

    #Log Vault Removal
    log VaultRemoved(vault)


@external
def swapVault(OldVaultAddress: address, NewVaultAddress: address):
    """
    @notice This function provides a way to swap a vault (on the list of vaults governed by this contract) out with a new vault
    @param OldVaultAddress the vault to replace.
    @param NewVaultAddress the vault replacing the old one..
    """
    #Check that the sender is authorized to swap vault
    assert msg.sender == self.contractOwner

    #Check that the vault we are swapping in is a valid address
    assert NewVaultAddress != empty(address)

    #Check that the vault we are swapping in is not on the list of vaults already
    assert NewVaultAddress not in self.VaultList

    #Run through list of vaults to find the one we want to swap out
    current_vault: uint256 = 0 
    for vault_addr in self.VaultList:
        if vault_addr == OldVaultAddress: break
        current_vault += 1

    #Make sure that OldVaultAddress is a vault on the list of vaults
    assert OldVaultAddress == self.VaultList[current_vault]

    #Replace OldVaultAddress with NewVaultAddress
    self.VaultList[current_vault] = NewVaultAddress

    # Log Vault Swap
    log VaultSwap(OldVaultAddress, NewVaultAddress)
    
    
@external
def replaceOwner(_new_owner: address) -> bool:
    """
    @notice replace the current Governance contract owner with a new one.
    @param _new_owner address of the new contract owner
    @return True, if contract owner was replaced, False otherwise
    """
    assert msg.sender == self.contractOwner, "Only existing owner can replace the owner."
    assert _new_owner != empty(address), "Owner cannot be null address."

    log OwnerChanged(_new_owner, self.contractOwner)

    self.contractOwner = _new_owner
    
    return True