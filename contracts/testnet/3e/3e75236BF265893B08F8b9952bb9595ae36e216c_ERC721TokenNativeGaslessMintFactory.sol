// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IERC721Token.sol";

/// @title ERC721TokenNativeGaslessMintFactory
/// @notice Factory contract that can deploy ERC721, ERC721 Soulbound tokens for use on Coinvise Campaigns
/// @author Coinvise
contract ERC721TokenNativeGaslessMintFactory is Ownable {
  /// @notice Emitted when trying to set `erc721TokenImpl`, `erc721SoulboundTokenImpl`, `erc721TokenNativeGaslessMintImpl`, `erc721SoulboundTokenNativeGaslessMintImpl` to zero address
  error InvalidAddress();

  /// @notice Emitted when `fee * _maxSupply` is not passed in as msg.value during `deployERC721Token()`
  error InvalidFee();

  /// @notice Emitted when ether transfer reverted
  error TransferFailed();

  /// @notice Emitted when an ERC721Token clone is deployed
  /// @param _tokenType type of token deployed
  /// @param _erc721TokenClone address of the deployed clone
  /// @param _creator address of the creator of the deployed clone
  /// @param _erc721TokenImpl address of the implementation used for the deployed clone
  event ERC721TokenDeployed(
    TokenType indexed _tokenType,
    address _erc721TokenClone,
    address indexed _creator,
    address indexed _erc721TokenImpl
  );

  /// @notice Emitted when funds are withdrawn
  /// @param _feeTreasury treasury address to which fees are withdrawn
  /// @param _amount amount of funds withdrawn to `_feeTreasury`
  event Withdrawal(address _feeTreasury, uint256 _amount);

  /// @notice Emitted when erc721TokenImpl is changed
  /// @param _oldERC721TokenImpl old erc721TokenImpl
  /// @param _newERC721TokenImpl new erc721TokenImpl
  event ERC721TokenImplSet(
    address _oldERC721TokenImpl,
    address _newERC721TokenImpl
  );

  /// @notice Emitted when erc721SoulboundTokenImpl is changed
  /// @param _oldERC721SoulboundTokenImpl old erc721SoulboundTokenImpl
  /// @param _newERC721SoulboundTokenImpl new erc721SoulboundTokenImpl
  event ERC721SoulboundTokenImplSet(
    address _oldERC721SoulboundTokenImpl,
    address _newERC721SoulboundTokenImpl
  );

  /// @notice Emitted when erc721TokenNativeGaslessMintImpl is changed
  /// @param _oldERC721TokenNativeGaslessMintImpl old erc721TokenNativeGaslessMintImpl
  /// @param _newERC721TokenNativeGaslessMintImpl new erc721TokenNativeGaslessMintImpl
  event ERC721TokenNativeGaslessMintImplSet(
    address _oldERC721TokenNativeGaslessMintImpl,
    address _newERC721TokenNativeGaslessMintImpl
  );

  /// @notice Emitted when erc721SoulboundTokenNativeGaslessMintImpl is changed
  /// @param _oldERC721SoulboundTokenNativeGaslessMintImpl old erc721SoulboundTokenNativeGaslessMintImpl
  /// @param _newERC721SoulboundTokenNativeGaslessMintImpl new erc721SoulboundTokenNativeGaslessMintImpl
  event ERC721SoulboundTokenNativeGaslessMintImplSet(
    address _oldERC721SoulboundTokenNativeGaslessMintImpl,
    address _newERC721SoulboundTokenNativeGaslessMintImpl
  );

  /// @notice Emitted when fee is changed
  /// @param _oldFee old fee
  /// @param _newFee new fee
  event FeeSet(uint256 _oldFee, uint256 _newFee);

  /// @notice Enum to differentiate type of token to deploy
  enum TokenType {
    ERC721Token,
    ERC721SoulboundToken,
    ERC721TokenNativeGaslessMint,
    ERC721SoulboundTokenNativeGaslessMint
  }

  /// @notice Implementation contract address used to deploy ERC721Token clones
  address public erc721TokenImpl;

  /// @notice Implementation contract address used to deploy ERC721SoulboundToken clones
  address public erc721SoulboundTokenImpl;

  /// @notice Implementation contract address used to deploy ERC721TokenNativeGaslessMint clones
  address public erc721TokenNativeGaslessMintImpl;

  /// @notice Implementation contract address used to deploy ERC721SoulboundTokenNativeGaslessMint clones
  address public erc721SoulboundTokenNativeGaslessMintImpl;

  /// @notice Fee per _maxSupply to be paid
  /// @dev `fee * _maxSupply` should be passed in as msg.value during `deployERC721Token()`
  uint256 public fee;

  /// @notice Sets `_erc721TokenImpl`, `_erc721SoulboundTokenImpl`, `_fee`
  /// @dev Reverts if `_erc721TokenImpl` or `_erc721SoulboundTokenImpl` param is address(0)
  /// @param _erc721TokenImpl ERC721Token implementation contract address
  /// @param _erc721SoulboundTokenImpl ERC721SoulboundToken implementation contract address
  /// @param _erc721TokenNativeGaslessMintImpl ERC721TokenNativeGaslessMint implementation contract address
  /// @param _erc721SoulboundTokenNativeGaslessMintImpl ERC721SoulboundTokenNativeGaslessMint implementation contract address
  /// @param _fee fee per _maxSupply to be paid
  constructor(
    address _erc721TokenImpl,
    address _erc721SoulboundTokenImpl,
    address _erc721TokenNativeGaslessMintImpl,
    address _erc721SoulboundTokenNativeGaslessMintImpl,
    uint256 _fee
  ) {
    /* if (
      _erc721TokenImpl == address(0) ||
      _erc721SoulboundTokenImpl == address(0) ||
      _erc721TokenNativeGaslessMintImpl == address(0) ||
      _erc721SoulboundTokenNativeGaslessMintImpl == address(0)
    ) revert InvalidAddress(); */

    assembly {
      if or(
        or(iszero(_erc721TokenImpl), iszero(_erc721SoulboundTokenImpl)),
        or(
          iszero(_erc721TokenNativeGaslessMintImpl),
          iszero(_erc721SoulboundTokenNativeGaslessMintImpl)
        )
      ) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    erc721TokenImpl = _erc721TokenImpl;
    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;
    erc721TokenNativeGaslessMintImpl = _erc721TokenNativeGaslessMintImpl;
    erc721SoulboundTokenNativeGaslessMintImpl = _erc721SoulboundTokenNativeGaslessMintImpl;
    fee = _fee;
  }

  /// @notice Deploys and initializes a new token clone with the params
  /// @dev Uses all token params + `_saltNonce` to calculate salt for clone.
  ///      Reverts if `fee * _maxSupply` is not passed in as msg.value.
  ///      Emits `ERC721TokenDeployed` or `ERC721SoulboundTokenDeployed`
  /// @param _tokenType Enum to differentiate type of token to deploy: ERC721Token | ERC721SoulboundToken | ERC721TokenNativeGaslessMint | ERC721SoulboundTokenNativeGaslessMint
  /// @param _name Token name
  /// @param _symbol Token symbol
  /// @param contractURI_ Token contract metadata URI
  /// @param tokenURI_ Token metadata URI
  /// @param _trustedAddress Address used for signatures
  /// @param _maxSupply Max allowed token amount
  /// @param _saltNonce Salt nonce to be used for the clone
  /// @return Address of the newly deployed clone
  function deployERC721Token(
    TokenType _tokenType,
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _trustedAddress,
    uint256 _maxSupply,
    uint256 _saltNonce
  ) external payable returns (address) {
    if (msg.value != fee * _maxSupply) revert InvalidFee();

    address impl;
    if (_tokenType == TokenType.ERC721Token) impl = erc721TokenImpl;
    else if (_tokenType == TokenType.ERC721SoulboundToken)
      impl = erc721SoulboundTokenImpl;
    else if (_tokenType == TokenType.ERC721TokenNativeGaslessMint)
      impl = erc721TokenNativeGaslessMintImpl;
    else if (_tokenType == TokenType.ERC721SoulboundTokenNativeGaslessMint)
      impl = erc721SoulboundTokenNativeGaslessMintImpl;

    address erc721TokenClone = Clones.cloneDeterministic(
      impl,
      keccak256(
        abi.encodePacked(
          _name,
          _symbol,
          contractURI_,
          tokenURI_,
          msg.sender,
          _trustedAddress,
          _maxSupply,
          _saltNonce
        )
      )
    );
    IERC721Token(erc721TokenClone).initialize(
      _name,
      _symbol,
      contractURI_,
      tokenURI_,
      msg.sender,
      _trustedAddress,
      _maxSupply
    );

    /* emit ERC721TokenDeployed(_tokenType, erc721TokenClone, msg.sender, impl); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, erc721TokenClone)
      log4(
        memPtr,
        32, // _erc721TokenClone
        0x23899f3b1fe55da77188b135df7513bf63e425a3958ee2866b3a19547c56effe, // ERC721TokenDeployed(uint8,address,address,address)
        _tokenType, // _tokenType
        caller(), // _creator
        impl // _erc721TokenImpl
      )
    }

    return erc721TokenClone;
  }

  /// @notice Set ERC721Token implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721TokenImpl` is address(0).
  ///      Emits `ERC721TokenImplSet`
  /// @param _erc721TokenImpl ERC721Token implementation contract address
  function setERC721TokenImplAddress(
    address _erc721TokenImpl
  ) external onlyOwner {
    /* if (_erc721TokenImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721TokenImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721TokenImpl = erc721TokenImpl;

    erc721TokenImpl = _erc721TokenImpl;

    /* emit ERC721TokenImplSet(_oldERC721TokenImpl, _erc721TokenImpl); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721TokenImpl) // _oldERC721TokenImpl
      mstore(add(memPtr, 32), _erc721TokenImpl) // _newERC721TokenImpl
      log1(
        memPtr,
        64,
        0xcbc745d8ffafdbb1db5af2ff6acd261357d2d6fa74ac0ea4389b92c8891a6bd8 // ERC721TokenImplSet(address,address)
      )
    }
  }

  /// @notice Set ERC721SoulboundToken implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721SoulboundTokenImpl` is address(0).
  ///      Emits `ERC721SoulboundTokenImplSet`
  /// @param _erc721SoulboundTokenImpl ERC721SoulboundToken implementation contract address
  function setERC721SoulboundTokenImplAddress(
    address _erc721SoulboundTokenImpl
  ) external onlyOwner {
    /* if (_erc721SoulboundTokenImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721SoulboundTokenImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721SoulboundTokenImpl = erc721SoulboundTokenImpl;

    erc721SoulboundTokenImpl = _erc721SoulboundTokenImpl;

    /* emit ERC721SoulboundTokenImplSet(
      _oldERC721SoulboundTokenImpl,
      _erc721SoulboundTokenImpl
    ); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721SoulboundTokenImpl) // _oldERC721SoulboundTokenImpl
      mstore(add(memPtr, 32), _erc721SoulboundTokenImpl) // _newERC721SoulboundTokenImpl
      log1(
        memPtr,
        64,
        0x9367781c37dc381ab012632d88359dc932afe7feabe3bc1a25a1f244c7324d03 // ERC721SoulboundTokenImplSet(address,address)
      )
    }
  }

  /// @notice Set ERC721TokenNativeGaslessMint implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721TokenNativeGaslessMintImpl` is address(0).
  ///      Emits `ERC721TokenNativeGaslessMintImplSet`
  /// @param _erc721TokenNativeGaslessMintImpl ERC721TokenNativeGaslessMint implementation contract address
  function setERC721TokenNativeGaslessMintImplAddress(
    address _erc721TokenNativeGaslessMintImpl
  ) external onlyOwner {
    /* if (_erc721TokenNativeGaslessMintImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721TokenNativeGaslessMintImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721TokenNativeGaslessMintImpl = erc721TokenNativeGaslessMintImpl;

    erc721TokenNativeGaslessMintImpl = _erc721TokenNativeGaslessMintImpl;

    /* emit ERC721TokenNativeGaslessMintImplSet(
      _oldERC721TokenNativeGaslessMintImpl,
      _erc721TokenNativeGaslessMintImpl
    ); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721TokenNativeGaslessMintImpl) // _oldERC721TokenNativeGaslessMintImpl
      mstore(add(memPtr, 32), _erc721TokenNativeGaslessMintImpl) // _newERC721TokenNativeGaslessMintImpl
      log1(
        memPtr,
        64,
        0x082b95c02b3eb688d1f091aae892ca75f69239366bbf8ecef64dbe962733f2b4 // ERC721TokenNativeGaslessMintImplSet(address,address)
      )
    }
  }

  /// @notice Set ERC721SoulboundTokenNativeGaslessMint implementation contract address
  /// @dev Callable only by `owner`.
  ///      Reverts if `_erc721SoulboundTokenNativeGaslessMintImpl` is address(0).
  ///      Emits `ERC721SoulboundTokenNativeGaslessMintImplSet`
  /// @param _erc721SoulboundTokenNativeGaslessMintImpl ERC721SoulboundTokenNativeGaslessMint implementation contract address
  function setERC721SoulboundTokenNativeGaslessMintImplAddress(
    address _erc721SoulboundTokenNativeGaslessMintImpl
  ) external onlyOwner {
    /* if (_erc721SoulboundTokenNativeGaslessMintImpl == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_erc721SoulboundTokenNativeGaslessMintImpl) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    address _oldERC721SoulboundTokenNativeGaslessMintImpl = erc721SoulboundTokenNativeGaslessMintImpl;

    erc721SoulboundTokenNativeGaslessMintImpl = _erc721SoulboundTokenNativeGaslessMintImpl;

    /* emit ERC721SoulboundTokenNativeGaslessMintImplSet(
      _oldERC721SoulboundTokenNativeGaslessMintImpl,
      _erc721SoulboundTokenNativeGaslessMintImpl
    ); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldERC721SoulboundTokenNativeGaslessMintImpl) // _oldERC721SoulboundTokenNativeGaslessMintImpl
      mstore(add(memPtr, 32), _erc721SoulboundTokenNativeGaslessMintImpl) // _newERC721SoulboundTokenNativeGaslessMintImpl
      log1(
        memPtr,
        64,
        0x2d8808514ecfc7e19bbed72dc7ad5d4e76fc343879db03af8dc1195c437ff9f9 // ERC721SoulboundTokenNativeGaslessMintImplSet(address,address)
      )
    }
  }

  /// @notice Set fee
  /// @dev Callable only by `owner`.
  ///      Emits `FeeSet`
  /// @param _fee fee per _maxSupply
  function setFee(uint256 _fee) external onlyOwner {
    uint256 _oldFee = fee;
    fee = _fee;

    /* emit FeeSet(_oldFee, _fee); */
    assembly {
      let memPtr := mload(64)
      mstore(memPtr, _oldFee) // _oldFee
      mstore(add(memPtr, 32), _fee) // _newFee
      log1(
        memPtr,
        64,
        0x74dbbbe280ef27b79a8a0c449d5ae2ba7a31849103241d0f98df70bbc9d03e37 // FeeSet(uint256,uint256)
      )
    }
  }

  /// @notice Withdraw funds to `_feeTreasury`
  /// @dev Transfers contract balance only to `_feeTreasury`, iff balance > 0.
  ///      Emits `Withdrawal`
  function withdraw(address _feeTreasury) external onlyOwner {
    uint256 _balance = address(this).balance;

    if (_balance > 0) {
      (bool success, ) = _feeTreasury.call{value: _balance}("");
      /* if (!success) revert TransferFailed(); */
      assembly {
        if iszero(success) {
          mstore(0x00, 0x90b8ec18) // TransferFailed()
          revert(0x1c, 0x04)
        }
      }

      /* emit Withdrawal(_feeTreasury, _balance); */
      assembly {
        let memPtr := mload(64)
        mstore(memPtr, _feeTreasury) // _feeTreasury
        mstore(add(memPtr, 32), _balance) // _amount
        log1(
          memPtr,
          64,
          0x7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65 // Withdrawal(address,uint256)
        )
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Token {
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _owner,
    address _trustedAddress,
    uint256 _maxSupply
  ) external;
}