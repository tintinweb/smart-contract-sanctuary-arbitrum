// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
// First version of contract that opens and closes betting and emits corresponding events. Later will accept bets.
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
   * @title TradingGame
   * @dev ContractDescription
   * @custom:dev-run-script compiler_config.json
   */
contract TradingGame is ConfirmedOwner {
    event BettingClosed(uint256 current_price, uint256 serial_number);
    event ProofOfRandomness(uint256 current_price, uint256 serial_number, string parameters_proof, string signature_proof);   

    uint256 current_price = 1000; 
    uint256 serial_number;
    bool open;

    constructor() ConfirmedOwner(msg.sender) {

    }
    

    function closeBetting() external onlyOwner returns (bool) {
        open = false;
        emit BettingClosed(current_price, serial_number);
        return open;
    }

    function openBetting(uint256 new_price, uint256 _serial_number, string memory parameters_proof, string memory signature_proof) 
        external onlyOwner returns (bool) {
            
            current_price = new_price;
            serial_number = _serial_number;
            open = true;
            emit ProofOfRandomness(current_price, _serial_number, parameters_proof, signature_proof);
            return open;
        }

    function getCurrentPrice() public view returns (uint256) {
        return current_price;
    }

    function getSerialNumber() public view returns (uint256) {
        return serial_number;
    }

    function isBettingOpen() public view returns (bool) {
        return open;
    }


    
}