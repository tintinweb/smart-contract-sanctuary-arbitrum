// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// contract that updates price and accepts bets.

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


/**
   * @title TradingGame
   * @dev ContractDescription
   */
contract TradingGame1_flat is ConfirmedOwner {
    event UpBetPlaced(uint256 betId, address owner, 
                    uint256 wagerAmount, string wagerCurrency, uint256 entryPrice, uint256 stopPrice);

    event DownBetPlaced(uint256 betId, address owner, 
                    uint256 wagerAmount, string wagerCurrency, uint256 entryPrice, uint256 stopPrice);

    // add event for price update

    uint256 currentPrice = 10000; 
    uint256 serialNumber;
    
    // Long and Short to reduce size of array to loop over when checking stop prices
    // Update: you cant iterate over a mapping, only array, so positions can be one mapping but create 2 arrays for short and long
    struct LongPositions {
        address owner;
        uint256 wagerAmount; 
        string wagerCurrency; 
        uint256 entryPrice;
        uint256 stopPrice;
    }
    mapping(uint256 => LongPositions)
        public long_positions; /* betId --> longPosition */

    struct ShortPositions {
        address owner;
        uint256 wagerAmount; 
        string wagerCurrency; 
        uint256 entryPrice;
        uint256 stopPrice;
    }
    mapping(uint256 => ShortPositions)
        public short_positions; /* betId --> shortPosition */

    constructor() ConfirmedOwner(msg.sender) {

    }

    function updatePrice(uint256 newPrice, uint256 _serialNumber) 
        external onlyOwner returns (uint256) {           
            currentPrice = newPrice;
            serialNumber = _serialNumber;
            return newPrice;
        }

    // apply reentrancy guard on this
    function placeBet(uint16 _direction, string memory _wagerCurrency, uint32 multiplier) 
        external payable returns (uint256 betId) {    
            betId = block.timestamp; // temporary, create hash of msg.sender, amount, currentPrice, serialNumber, block.timestamp, nonce: betId = uint256(keccak256(abi.encodePacked(newItemId,msg.sender,block.difficulty,block.timestamp)));
            uint256 _stopPrice = multiplier; // temporary, need to calculate from currentPrice, direction and multiplier 
            if (_direction == 1) { // direction 1 == long
                long_positions[betId] = LongPositions({
                    owner: msg.sender,
                    wagerAmount: msg.value,
                    wagerCurrency: _wagerCurrency,
                    entryPrice: currentPrice, 
                    stopPrice: _stopPrice
                });
                emit UpBetPlaced(betId, msg.sender, msg.value, _wagerCurrency, currentPrice, _stopPrice); // picked up in UI to show activity
            } else if (_direction == 2) {
                short_positions[betId] = ShortPositions({
                    owner: msg.sender,
                    wagerAmount: msg.value,
                    wagerCurrency: _wagerCurrency,
                    entryPrice: currentPrice, 
                    stopPrice: _stopPrice
                });
                emit DownBetPlaced(betId, msg.sender, msg.value, _wagerCurrency, currentPrice, _stopPrice);
            }  
            // needs to send msg.value to the house bankroll smart contract           
            return betId;
        }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function getSerialNumber() public view returns (uint256) {
        return serialNumber;
    }
  
}