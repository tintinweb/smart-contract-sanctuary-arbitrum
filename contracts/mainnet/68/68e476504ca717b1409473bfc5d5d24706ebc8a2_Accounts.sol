// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import "chainlink/src/v0.8/shared/access/ConfirmedOwner.sol"; // Ownership
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Random.win Accounts Smart Contract
 * @author Borr Technologies SAS, a registered French company
 *
 * @notice This contract is the Accounts contract for Random.win RNG ( https://www.random.win )
 * 
 */
contract Accounts is ConfirmedOwner {

    error UnknownCaller(address caller);
    error NotEnoughFunds(address user);

    event EndOfTrial(address user);
    event PaymentSuccessful(address user);

    uint256 public price;
    mapping(address => uint256) private customPrices;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private testBalances;
    uint256 private totalBalance;
    mapping(address => bool) private allowedCallers;
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

        uint256 weiPrice = getWeiPrice(user);

        if (testBalances[user] > 0) {

            if (testBalances[user] <= weiPrice) {

                weiPrice -= testBalances[user];
                totalBalance -= testBalances[user];
                testBalances[user] = 0;

                emit EndOfTrial(user);

            } else {
                testBalances[user] -= weiPrice;
                totalBalance -= weiPrice;
                weiPrice = 0;
            }
            
        }

        if (weiPrice > 0) {

            if (balances[user] < weiPrice) {
                revert NotEnoughFunds(user);
            }

            balances[user] -= weiPrice;
            totalBalance -= weiPrice;

        }

        emit PaymentSuccessful(user);
    }

    function getWeiPrice(address user) private view returns (uint256) {
        
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return (getUsdPrice(user) * 1000000000000000000000000) / uint256(answer);
    }

    function getUsdPrice(address user) private view returns (uint256) {
        
        if (customPrices[user] > 0) {
            return customPrices[user];
        }

        return price;
    }

    function balance(address user) external view returns (uint256) {
        return balances[user] + testBalances[user];
    }

    function totalBalanceUsers() external onlyOwner returns (uint256) {
        return totalBalance;
    }

    function setCaller(address caller, bool allowed) external onlyOwner {
        allowedCallers[caller] = allowed;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setCustomPrice(uint256 _price, address user) external onlyOwner {
        customPrices[user] = _price;
    }

    function deposit() external payable {
        depositUser(msg.sender);
    }

    function depositUser(address user) private {
        require(msg.value > 0, "Empty top up");
        balances[user] += msg.value;
        totalBalance += msg.value;
    }

    function withdraw(uint256 amount) external {
        withdrawUser(amount, msg.sender, msg.sender);
    }

    function withdrawTo(uint256 amount, address recipient) external {
        withdrawUser(amount, msg.sender, recipient);
    }

    function withdrawUser(uint256 amount, address user, address recipient) private {
        uint256 ethBalance = balances[user];
        balances[user] -= amount;
        totalBalance -= amount;
        _withdraw(amount, recipient, ethBalance);
    }

    function withdrawMaximum(address user) external view returns (uint256) {
        return balances[user];
    }

    function withdrawOwner() external onlyOwner {
        uint256 ethBalance = withdrawOwnerMaximum();
        _withdraw(ethBalance, owner(), ethBalance);
    }

    function withdrawOwnerAdvanced(uint256 amount, address recipient) external onlyOwner {
        uint256 ethBalance = withdrawOwnerMaximum();
        _withdraw(amount, recipient, ethBalance);
    }

    function withdrawOwnerMaximum() public view returns (uint256) {
        return address(this).balance - totalBalance;
    }

    function _withdraw(uint256 amount, address recipient, uint256 ethBalance) private {
        require(ethBalance > 0, "Nothing to withdraw");
        require(ethBalance >= amount, "Amount too high");
        payable(recipient).transfer(amount);
    }

    function addTestBalance(address user) external payable onlyOwner {
        require(msg.value > 0, "Empty top up");
        testBalances[user] += msg.value;
        totalBalance += msg.value;
    }

    function removeTestBalance(address user) external onlyOwner {
        uint256 ethBalance = testBalances[user];
        testBalances[user] = 0;
        totalBalance -= ethBalance;
        _withdraw(ethBalance, owner(), ethBalance);
    }

    function removeTestBalanceAdvanced(address user, uint256 amount, address recipient) external onlyOwner {
        uint256 ethBalance = testBalances[user];
        testBalances[user] -= amount;
        totalBalance -= amount;
        _withdraw(amount, recipient, ethBalance);
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