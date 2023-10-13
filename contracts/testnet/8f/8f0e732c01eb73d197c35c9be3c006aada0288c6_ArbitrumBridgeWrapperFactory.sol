// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ArbitrumBridgeWrapper.sol";

contract ArbitrumBridgeWrapperFactory {
    event ContractCreated(address arbitrumBridgeWrapperAddress);

    error DeploymentFailed();

    function deployArbitrumBridgeWrapper(address owner)
        external
        payable
        returns (address wrapperAddress)
    {

        bytes32 salt = bytes32(uint256(uint160(msg.sender)) << 96);
        bytes memory initCode = type(ArbitrumBridgeWrapper).creationCode;
        initCode = bytes.concat(initCode, abi.encode(owner));

        assembly {
            wrapperAddress :=
                create2(
                    0, // value - left at zero here
                    add(0x20, initCode), // initialization bytecode
                    mload(initCode), // length of initialization bytecode
                    salt // user-defined nonce to ensure unique address
                )
        }
        if (wrapperAddress == address(0)) {
            revert DeploymentFailed();
        }

        emit ContractCreated(wrapperAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../shared/access/ConfirmedOwner.sol";

contract ArbitrumBridgeWrapper is ConfirmedOwner {
    event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);

    IArbitrumBridge public s_arbitrumBridgeOnramp;

    constructor(address owner) ConfirmedOwner(owner) {}

    function setArbitrumBridgeOnrampAddress(address onramp) external onlyOwner() {
        s_arbitrumBridgeOnramp = IArbitrumBridge(onramp);
    }

    function bridge() external payable {
        s_arbitrumBridgeOnramp.depositEth{value: msg.value}();
    }

    receive() external payable {
        emit FundsAdded(msg.value, address(this).balance, msg.sender);
    }

    function withdrawFunds(address to) external onlyOwner() {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Could not withdraw");
    }
}

interface IArbitrumBridge {
    function depositEth() external payable;
}

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

import "../interfaces/IOwnable.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
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

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}