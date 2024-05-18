// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import "chainlink/src/v0.8/shared/access/ConfirmedOwner.sol"; // Ownership
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Random.win Accounts Smart Contract
 * @author Lancelot Chardonnet
 *
 * @notice This contract is the Accounts contract for Random.win RNG ( https://www.random.win )
 * 
 */
contract Accounts is ConfirmedOwner {

    error UnknownCaller(address caller);
    error NotEnoughFunds(address user);
    event PaymentSuccessful(address user);

    uint256 public price;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    mapping(address => bool) public allowedCallers;
    AggregatorV3Interface internal priceFeed;


    modifier onlyMain {
        if (!allowedCallers[msg.sender]) {
            revert UnknownCaller(msg.sender);
        }
        _;
    }

    modifier skipIfOwner(address user) {
        if (user != owner()) {
            _;
        }
    }

    constructor (
        uint256 _price,
        address priceFeedAddress
    )
        ConfirmedOwner(msg.sender)
    {
        price = _price;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function pay(address user) external onlyMain skipIfOwner(user) {

        uint256 weiPrice = getWeiPrice();

        if (balances[user] < weiPrice) {
            revert NotEnoughFunds(user);
        }

        balances[user] -= weiPrice;
        totalBalance -= weiPrice;
        emit PaymentSuccessful(user);
    }

    function getWeiPrice() public view returns (uint256) {
        
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        uint256 weiPrice = (price * 1000000000000000000000000) / uint256(answer);
        return weiPrice;
    }

    function setCaller(address caller, bool allowed) external onlyOwner {
        allowedCallers[caller] = allowed;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function deposit(address user) external payable {
        require(msg.value > 0, "Empty top up");
        balances[user] += msg.value;
        totalBalance += msg.value;
    }

    function withdraw(uint256 amount, address recipient) external {
        uint256 ethBalance = balances[msg.sender];
        _withdraw(amount, recipient, ethBalance);
        balances[msg.sender] -= amount;
        totalBalance -= amount;
    }

    function withdrawAdmin(uint256 amount, address recipient) external onlyOwner {
        uint256 ethBalance = getRevenue();
        _withdraw(amount, recipient, ethBalance);
    }

    function _withdraw(uint256 amount, address recipient, uint256 ethBalance) private {
        require(ethBalance > 0, "Nothing to withdraw");
        require(ethBalance >= amount, "Amount too high");
        payable(recipient).transfer(amount);
    }

    function getRevenue() public view returns (uint256) {
        return address(this).balance - totalBalance;
    }

    receive() external payable { }

    fallback() external payable { }
   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}