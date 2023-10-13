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

        bytes memory initCode = hex"608060405234801561001057600080fd5b5060405161071b38038061071b83398101604081905261002f91610168565b33806000816100855760405162461bcd60e51b815260206004820152601860248201527f43616e6e6f7420736574206f776e657220746f207a65726f000000000000000060448201526064015b60405180910390fd5b600080546001600160a01b0319166001600160a01b03848116919091179091558116156100b5576100b5816100be565b50505050610198565b6001600160a01b0381163314156101175760405162461bcd60e51b815260206004820152601760248201527f43616e6e6f74207472616e7366657220746f2073656c66000000000000000000604482015260640161007c565b600180546001600160a01b0319166001600160a01b0383811691821790925560008054604051929316917fed8889f560326eb138920d842192f0eb3dd22b4f139c87a2c57538e05bae12789190a350565b60006020828403121561017a57600080fd5b81516001600160a01b038116811461019157600080fd5b9392505050565b610574806101a76000396000f3fe60806040526004361061005e5760003560e01c80638da5cb5b116100435780638da5cb5b146100df578063e78cea9214610118578063f2fde38b1461012057600080fd5b806368742da6146100a857806379ba5097146100ca57600080fd5b366100a35760408051348152476020820152338183015290517fc6f3fb0fec49e4877342d4625d77a632541f55b7aae0f9d0b34c69b3478706dc9181900360600190a1005b600080fd5b3480156100b457600080fd5b506100c86100c336600461052a565b610140565b005b3480156100d657600080fd5b506100c861021b565b3480156100eb57600080fd5b506000546040805173ffffffffffffffffffffffffffffffffffffffff9092168252519081900360200190f35b6100c8610318565b34801561012c57600080fd5b506100c861013b36600461052a565b61039d565b6101486103b1565b60008173ffffffffffffffffffffffffffffffffffffffff164760405160006040518083038185875af1925050503d80600081146101a2576040519150601f19603f3d011682016040523d82523d6000602084013e6101a7565b606091505b5050905080610217576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601260248201527f436f756c64206e6f74207769746864726177000000000000000000000000000060448201526064015b60405180910390fd5b5050565b60015473ffffffffffffffffffffffffffffffffffffffff16331461029c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601660248201527f4d7573742062652070726f706f736564206f776e657200000000000000000000604482015260640161020e565b60008054337fffffffffffffffffffffffff00000000000000000000000000000000000000008083168217845560018054909116905560405173ffffffffffffffffffffffffffffffffffffffff90921692909183917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e091a350565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663439370b1346040518263ffffffff1660e01b81526004016000604051808303818588803b15801561038257600080fd5b505af1158015610396573d6000803e3d6000fd5b5050505050565b6103a56103b1565b6103ae81610434565b50565b60005473ffffffffffffffffffffffffffffffffffffffff163314610432576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601660248201527f4f6e6c792063616c6c61626c65206279206f776e657200000000000000000000604482015260640161020e565b565b73ffffffffffffffffffffffffffffffffffffffff81163314156104b4576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601760248201527f43616e6e6f74207472616e7366657220746f2073656c66000000000000000000604482015260640161020e565b600180547fffffffffffffffffffffffff00000000000000000000000000000000000000001673ffffffffffffffffffffffffffffffffffffffff83811691821790925560008054604051929316917fed8889f560326eb138920d842192f0eb3dd22b4f139c87a2c57538e05bae12789190a350565b60006020828403121561053c57600080fd5b813573ffffffffffffffffffffffffffffffffffffffff8116811461056057600080fd5b939250505056fea164736f6c6343000806000a";
        initCode = bytes.concat(initCode, abi.encode(owner));
        assembly {
            wrapperAddress :=
                create2(
                    0, // value - left at zero here
                    add(0x20, initCode), // initialization bytecode
                    mload(initCode), // length of initialization bytecode
                    "123" // user-defined nonce to ensure unique address
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

    IArbitrumBridge internal s_arbitrumBridgeOnramp;

    constructor(address owner) ConfirmedOwner(msg.sender) {}

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