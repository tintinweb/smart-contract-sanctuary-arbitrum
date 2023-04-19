/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// SPDX-License-Identifier: MIT

/*
               __                 _   
  _   _ _ __  / _|_ __ ___  _ __ | |_ 
 | | | | '_ \| |_| '__/ _ \| '_ \| __|
 | |_| | |_) |  _| | | (_) | | | | |_ 
  \__,_| .__/|_| |_|  \___/|_| |_|\__|
       |_|                            

  Multi-Signature Wallet

  Authors: <dotfx>
  Date: 2023/04/19
  Version: 1.0.0
*/

pragma solidity >=0.8.18 <0.9.0;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() virtual {
    require(_msgSender() == _owner, "Caller must be the owner.");

    _;
  }

  function renounceOwnership() external virtual isOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");

    locked = true;
    _;
    locked = false;
  }
}

contract upfrontMultiSignatureWallet is ReentrancyGuard {
  uint256 private PROPOSAL_DEADLINE;
  uint256 private PROPOSAL_QUORUM;
  uint256 private PROPOSAL_THRESHOLD;
  address private EXECUTOR_ADDRESS;
  bool private initialized;

  struct managerDataStruct {
    bool exists;
    bool active;
  }

  struct delegateDataStruct {
    bool exists;
    mapping(address => delegateRelationDataStruct) relation;
    address[] relationList;
  }

  struct delegateRelationDataStruct {
    bool exists;
    bool active;
    uint256 timestamp;
  }

  struct proposalDataStruct {
    bool exists;
    bool approved;
    uint256 created;
    uint256 start;
    uint256 end;
    uint256 closed;
    uint256 executed;
    address creator;
    string subject;
    string description;
    string canceled;
    address[] target;
    bytes[] data;
    bytes[] response;
    uint256 agreed;
    mapping(address => votedProposalDataStruct) voted;
    address[] votedList;
  }

  struct votedProposalDataStruct {
    bool exists;
    uint256 timestamp;
    address signer;
    bool agreed;
  }

  struct proposalReturnStruct {
    bool approved;
    uint256 created;
    uint256 start;
    uint256 end;
    uint256 closed;
    uint256 executed;
    address creator;
    string subject;
    string description;
    string canceled;
    address[] target;
    bytes[] data;
    bytes[] response;
    uint256 agreed;
    votedProposalReturnStruct[] voted;
  }

  struct votedProposalReturnStruct {
    uint256 timestamp;
    address manager;
    address signer;
    bool agreed;
  }

  address[] private managerList;
  mapping(address => managerDataStruct) private managerData;

  address[] private delegateList;
  mapping(address => delegateDataStruct) private delegateData;

  uint256[] private proposalList;
  mapping(uint256 => proposalDataStruct) private proposalData;

  event addedManager(address indexed manager);
  event revokedManager(address indexed manager);
  event addedDelegate(address indexed manager, address delegate);
  event revokedDelegate(address indexed manager, address delegate);
  event SubmittedProposal(uint256 indexed id, address indexed creator);
  event CanceledProposal(uint256 indexed id, string reason);
  event ApprovedProposal(uint256 indexed id, uint256 agreed, uint256 total);
  event DeniedProposal(uint256 indexed id, uint256 agreed, uint256 total);
  event VotedProposal(uint256 indexed id, address indexed manager, address signer, bool agreed);
  event ExecutedProposal(uint256 indexed id, address executor);

  modifier isSelf() {
    if (initialized) { require(msg.sender == address(this), "Caller must be internal."); }

    _;
  }

  modifier isManager() {
    require(managerData[_msgSender()].exists && managerData[_msgSender()].active, "Caller must be manager.");

    _;
  }

  modifier isExecutor() {
    require(_msgSender() == EXECUTOR_ADDRESS, "Caller must be executor.");

    _;
  }

  modifier isProposal(uint256 id, bool openOnly, bool startedOnly) {
    require(proposalData[id].exists, "Unknown proposal.");

    if (openOnly) {
      require(proposalData[id].closed == 0, "Proposal closed.");

      if (startedOnly) { require(proposalData[id].start <= getCurrentTime(), "Proposal not yet started."); }
    }

    _;
  }

  modifier isApproved(uint256 id, bool approved) {
    if (approved) {
      require(proposalData[id].closed > 0 && proposalData[id].approved, "Proposal not yet approved.");
    } else {
      require(proposalData[id].closed == 0, "Proposal closed.");
    }

    _;
  }

  modifier isExecuted(uint256 id, bool executed) {
    if (executed) {
      require(proposalData[id].executed > 0, "Proposal not yet executed.");
    } else {
      require(proposalData[id].executed == 0, "Proposal already executed.");
    }

    _;
  }

  constructor(address[] memory _managers, address _executor, uint256 _deadline, uint256 _quorum, uint256 _threshold) {
    uint256 cnt = _managers.length;

    require(cnt >= 3, "Minimum managers not reached.");

    unchecked {
      for (uint256 m; m < cnt; m++) {
        address manager = _managers[m];

        require(manager != address(0), "Invalid manager.");
        require(!Address.isContract(manager), "Invalid manager.");
        require(!managerData[manager].exists, "Manager already exists.");

        addManager(manager, false);
      }

      setProposalDeadline(_deadline);
      setProposalQuorum(_quorum == 0 ? cnt / 2 : _quorum);
      setProposalThreshold(_threshold == 0 ? (cnt / 2) + 1 : _threshold);
      setExecutorAddress(_executor);
    }

    proposalList.push(0);
    proposalData[0].exists = false;

    initialized = true;
  }

  function getContractInfo() external view returns (uint256, uint256, uint256) {
    return (PROPOSAL_DEADLINE, PROPOSAL_QUORUM, PROPOSAL_THRESHOLD);
  }

  function setProposalDeadline(uint256 _time) public isSelf {
    require(_time >= 1 days, "Deadline cannot be less than 1 day.");

    PROPOSAL_DEADLINE = _time;
  }

  function setProposalQuorum(uint256 _value) public isSelf {
    uint256 managers = _countActiveManagers();

    unchecked {
      require(_value > 0 && _value <= managers / 2, "Maximum quorum must be less or equal than half the number of managers.");
    }

    PROPOSAL_QUORUM = _value;
  }

  function setProposalThreshold(uint256 _value) public isSelf {
    uint256 managers = _countActiveManagers();

    require(_value > 0 && _value < managers, "Maximum threshold must be less than the number of managers.");

    PROPOSAL_THRESHOLD = _value;
  }

  function setExecutorAddress(address _address) public isSelf {
    require(_address != address(0));
    require(_address != address(this));

    bool proceed;
    uint256 cnt = managerList.length;

    unchecked {
      for (uint256 m; m < cnt; m++) {
        if (managerList[m] == _address) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Executor cannot be a manager.");

    EXECUTOR_ADDRESS = _address;
  }

  function addManager(address _manager, bool _adjust) public isSelf {
    require(_manager != address(0));
    require(_manager != address(this));
    require(EXECUTOR_ADDRESS != _manager, "Executor cannot be a manager.");

    if (!managerData[_manager].exists) {
      managerList.push(_manager);
      managerData[_manager].exists = true;
    }

    managerData[_manager].active = true;

    unchecked {
      if (_adjust) {
        uint256 managers = _countActiveManagers();

        setProposalQuorum(managers / 2);
        setProposalThreshold((managers / 2) + 1);
      }
    }

    emit addedManager(_manager);
  }

  function revokeManager(address _manager, bool _adjust) public isSelf {
    require(managerData[_manager].exists, "Unknown manager.");

    uint256 managers = _countActiveManagers();

    require(managers - 1 >= 3, "Minimum managers not reached.");

    unchecked {
      if (_adjust) {
        setProposalQuorum((managers - 1) / 2);
        setProposalThreshold(((managers - 1) / 2) + 1);
      }
    }

    managerData[_manager].active = false;

    uint256 cnt = proposalList.length;

    unchecked {
      for (uint256 p = 1; p < cnt; p++) {
        if (proposalData[p].creator != _manager) { continue; }
        if (bytes(proposalData[p].canceled).length > 0 || (proposalData[p].approved && (proposalData[p].executed > 0 || proposalData[p].target.length == 0))) { continue; }

        proposalData[p].closed = getCurrentTime();
        proposalData[p].canceled = "Manager has been revoked.";
      }
    }

    emit revokedManager(_manager);
  }

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function getProposal(uint256 _id) public view isProposal(_id, false, false) returns (proposalReturnStruct memory) {
    proposalReturnStruct memory proposal;
    uint256 cnt = proposalData[_id].votedList.length;

    proposal.approved = proposalData[_id].approved;
    proposal.created = proposalData[_id].created;
    proposal.start = proposalData[_id].start;
    proposal.end = proposalData[_id].end;
    proposal.closed = proposalData[_id].closed;
    proposal.executed = proposalData[_id].executed;
    proposal.creator = proposalData[_id].creator;
    proposal.subject = proposalData[_id].subject;
    proposal.description = proposalData[_id].description;
    proposal.canceled = proposalData[_id].canceled;
    proposal.target = proposalData[_id].target;
    proposal.data = proposalData[_id].data;
    proposal.response = proposalData[_id].response;
    proposal.agreed = proposalData[_id].agreed;
    proposal.voted = new votedProposalReturnStruct[](cnt);

    unchecked {
      for (uint256 i; i < cnt; i++) {
        votedProposalDataStruct memory voted = proposalData[_id].voted[proposalData[_id].votedList[i]];

        proposal.voted[i] = votedProposalReturnStruct(voted.timestamp, proposalData[_id].votedList[i], voted.signer, voted.agreed);
      }
    }

    return proposal;
  }

  function cancelProposal(uint256 _id, string memory _reason) public isManager isProposal(_id, true, false) isApproved(_id, false) {
    require(proposalData[_id].exists, "Unknown proposal.");
    require(proposalData[_id].creator == msg.sender, "Not the creator.");
    require(bytes(_reason).length > 0, "Specify a reason.");

    proposalData[_id].closed = getCurrentTime();
    proposalData[_id].canceled = _reason;

    emit CanceledProposal(_id, _reason);
  }

  function voteProposal(uint256 _id, address _manager, bool agree) public isProposal(_id, true, true) isApproved(_id, false) {
    require(managerData[_manager].exists && managerData[_manager].active, "Unknown manager.");
    require(proposalData[_id].end > getCurrentTime(), "Voting deadline expired.");

    if (proposalData[_id].voted[_manager].exists) { revert("You or your delegate have already voted."); }

    if (_manager == msg.sender) {
      require(managerData[msg.sender].exists && managerData[msg.sender].active, "Unknown manager.");
    } else {
      require(getManagerDelegate(_manager) == msg.sender, "Not authorized to vote.");
    }

    proposalData[_id].voted[_manager] = votedProposalDataStruct(true, getCurrentTime(), msg.sender, agree);
    proposalData[_id].votedList.push(_manager);

    unchecked {
      if (agree) { proposalData[_id].agreed++; }
    }

    emit VotedProposal(_id, _manager, msg.sender, agree);

    unchecked {
      uint256 voted = proposalData[_id].votedList.length;
      uint256 denied = voted - proposalData[_id].agreed;
      uint256 managers = _countActiveManagers();

      if ((voted == managers) || (proposalData[_id].agreed > denied && proposalData[_id].agreed - denied >= PROPOSAL_THRESHOLD) || (proposalData[_id].agreed < denied && denied - proposalData[_id].agreed >= PROPOSAL_THRESHOLD)) {
        proposalData[_id].closed = getCurrentTime();

        if (proposalData[_id].agreed > denied) {
          proposalData[_id].approved = true;

          emit ApprovedProposal(_id,proposalData[_id].agreed, voted);
        } else {
          emit DeniedProposal(_id, proposalData[_id].agreed, voted);
        }
      }
    }
  }

  function _hasReachedQuorum(uint256 _id) internal view returns (bool reached, bool agreed) {
    uint256 voted = proposalData[_id].votedList.length;

    if (voted == 0) { return (true, false); }

    unchecked {
      uint256 denied = voted - proposalData[_id].agreed;

      if (proposalData[_id].agreed == denied) { return (true, false); }

      reached = (proposalData[_id].agreed > denied ? proposalData[_id].agreed >= PROPOSAL_QUORUM : denied >= PROPOSAL_QUORUM);

      return (reached, reached ? proposalData[_id].agreed > denied : false);
    }
  }

  function submitProposal(string memory _subject, string memory _description, uint256 _time, address[] memory _contract, bytes[] memory _data) public isManager returns (uint256) {
    require(bytes(_subject).length > 0, "Specify a subject.");
    require(bytes(_description).length > 0, "Specify a description.");
    require(_contract.length == _data.length, "Invalid number of params.");

    uint256 id = proposalList.length;

    proposalList.push(id);
    proposalData[id].exists = true;
    proposalData[id].created = getCurrentTime();
    proposalData[id].start = _time < getCurrentTime() ? getCurrentTime() : _time;
    proposalData[id].end = proposalData[id].start + PROPOSAL_DEADLINE;
    proposalData[id].creator = msg.sender;
    proposalData[id].subject = _subject;
    proposalData[id].description = _description;
    proposalData[id].target = _contract;
    proposalData[id].data = _data;

    emit SubmittedProposal(id, msg.sender);

    return id;
  }

  function manualExecuteProposal(uint256 _id) external isManager isProposal(_id, false, false) isExecuted(_id, false) nonReEntrant returns (bytes[] memory) {
    return _executeProposal(_id);
  }

  function autoExecuteProposal(uint256 _id) external isExecutor isProposal(_id, false, false) isExecuted(_id, false) nonReEntrant returns (bytes[] memory) {
    return _executeProposal(_id);
  }

  function _executeProposal(uint256 _id) internal returns (bytes[] memory) {
    if (proposalData[_id].approved) {
      uint256 cnt = proposalData[_id].target.length;

      require(cnt > 0, "Nothing to execute.");

      bytes[] memory results = new bytes[](cnt);

      unchecked {
        for (uint256 i; i < cnt; i++) {
          (bool success, bytes memory result) = proposalData[_id].target[i].call{ value: 0 }(proposalData[_id].data[i]);

          if (success) {
            results[i] = result;

            continue;
          }

          if (result.length == 0) { revert("Function call reverted."); }

          assembly {
            let size := mload(result)

            revert(add(32, result), size)
          }
        }
      }

      proposalData[_id].executed = getCurrentTime();
      proposalData[_id].response = results;

      emit ExecutedProposal(_id, _msgSender());

      return results;
    }

    require(proposalData[_id].end <= getCurrentTime(), "Voting deadline not yet expired.");

    proposalData[_id].closed = getCurrentTime();
    uint256 voted = proposalData[_id].votedList.length;

    (bool quorum, bool agreed) = _hasReachedQuorum(_id);

    if (quorum) {
      if (agreed) {
        proposalData[_id].approved = true;

        emit ApprovedProposal(_id, proposalData[_id].agreed, voted);

        if (proposalData[_id].target.length == 0) { return new bytes[](0); }

        return _executeProposal(_id);
      }

      emit DeniedProposal(_id, proposalData[_id].agreed, voted);

      return new bytes[](0);
    }

    emit DeniedProposal(_id, proposalData[_id].agreed, voted);

    return new bytes[](0);
  }

  function setManagerDelegate(address _delegate, bool _active) external isManager {
    require(_delegate != address(0));
    require(_delegate != msg.sender, "Cannot delegate to yourself.");

    if (_active) {
      address delegate = getManagerDelegate(msg.sender);

      require(delegate != _delegate, "Delegate already active.");
      require(delegate == address(0), "You can only have one active delegate.");
    } else {
      require(delegateData[_delegate].exists, "Unknown delegate address.");
    }

    if (delegateData[_delegate].exists) {
      if (delegateData[_delegate].relation[msg.sender].exists) {
        if (!_active && !delegateData[_delegate].relation[msg.sender].active) { revert("Delegate already inactive."); }
      } else {
        delegateData[_delegate].relation[msg.sender].exists = true;
        delegateData[_delegate].relationList.push(msg.sender);
      }

      delegateData[_delegate].relation[msg.sender].active = _active;
      delegateData[_delegate].relation[msg.sender].timestamp = getCurrentTime();
    } else {
      delegateList.push(_delegate);
      delegateData[_delegate].exists = true;
      delegateData[_delegate].relation[msg.sender] = delegateRelationDataStruct(true, _active, getCurrentTime());
      delegateData[_delegate].relationList.push(msg.sender);
    }

    if (_active) {
      emit addedDelegate(msg.sender, _delegate);
    } else {
      emit revokedDelegate(msg.sender, _delegate);
    }
  }

  function getManagerDelegate(address _manager) public view returns (address) {
    require(managerData[_manager].exists, "Unknown manager.");

    address delegate;
    uint256 dcnt = delegateList.length;

    if (dcnt == 0) { return delegate; }

    unchecked {
      for (uint256 d; d < dcnt; d++) {
        uint256 rcnt = delegateData[delegateList[d]].relationList.length;

        for (uint256 r; r < rcnt; r++) {
          if (delegateData[delegateList[d]].relationList[r] != _manager) { continue; }
          if (!delegateData[delegateList[d]].relation[_manager].exists) { continue; }
          if (!delegateData[delegateList[d]].relation[_manager].active) { continue; }

          delegate = delegateList[d];
          break;
        }
      }
    }

    return delegate;
  }

  function listManagers(bool _active) external view returns (address[] memory) {
    uint256 cnt = managerList.length;
    uint256 len = _active ? _countActiveManagers() : cnt;
    uint256 i;

    address[] memory data = new address[](len);

    unchecked {
      for (uint256 m; m < cnt; m++) {
        if (_active && !managerData[managerList[m]].active) { continue; }

        data[i++] = managerList[m];
      }
    }

    return data;
  }

  function listProposals() external view returns (proposalReturnStruct[] memory) {
    uint256 cnt = proposalList.length;
    proposalReturnStruct[] memory data = new proposalReturnStruct[](cnt);

    unchecked {
      for (uint256 p = 1; p < cnt; p++) { data[p] = getProposal(p); }
    }

    return data;
  }

  function _countActiveManagers() internal view returns (uint256) {
    uint256 cnt = managerList.length;
    uint256 active;

    unchecked {
      for (uint256 m; m < cnt; m++) {
        if (!managerData[managerList[m]].active) { continue; }

        active++;
      }
    }

    return active;
  }
}