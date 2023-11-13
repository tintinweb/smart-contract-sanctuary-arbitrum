// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import {IValidSigner} from "./interfaces/IValidSigner.sol";
import {IGnosis} from "./interfaces/IGnosis.sol";

contract SignatureStorage is Ownable {
	bytes4 public constant ERC1257_MAGICVALUE = 0x1626ba7e;
	bytes4 public constant GNOSIS_MAGICVALUE = 0x20c13b0b;

	bytes32 public HASH;
	string public disclaimer;

	mapping(address => bool) public hasSigned;

	event Signed(address indexed user);

	constructor(bytes32 _hash) Ownable(msg.sender) {
		HASH = _hash;
	}

	function submitSignature(bytes32 _hash, bytes memory _signature) external returns (bool) {
		require(_hash == HASH, "Improper message");
		require(checkSignature(_hash, _signature, msg.sender), "invalid sig");
		hasSigned[msg.sender] = true;
		emit Signed(msg.sender);
	}

	function checkSignature(bytes32 _hash, bytes memory _signature, address _for) public view returns (bool) {
		if (isContract(_for)) {
			return checkGnosis(_hash, _signature, _for) || checkERC1271(_hash, _signature, _for);
		}
		return checkForEOA(_hash, _signature, _for);
	}

	/*
	 * HELPERS
	 */
	function extractSignature(bytes memory _signature) public pure returns (bytes32 r, bytes32 s, uint8 v) {
		require(_signature.length == 65, "Invalid signature length");

		assembly {
			// Retrieve r by loading the first 32 bytes (offset 0) of the signature
			r := mload(add(_signature, 32))

			// Retrieve s by loading the second 32 bytes (offset 32) of the signature
			s := mload(add(_signature, 64))

			// Retrieve v by loading the byte (offset 64) following the signature
			v := byte(0, mload(add(_signature, 96)))
		}
	}

	function convertBytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
		bytes memory result = new bytes(32);

		assembly {
			mstore(add(result, 32), data)
		}

		return result;
	}

	function checkForEOA(bytes32 hash, bytes memory signature, address _for) public view returns (bool) {
		(bytes32 r, bytes32 s, uint8 v) = extractSignature(signature);
		address signer = ecrecover(hash, v, r, s);
		return signer == _for;
	}

	function checkGnosis(bytes32 hash, bytes memory signature, address _for) public view returns (bool) {
		bytes memory hashInBytes = convertBytes32ToBytes(hash);
		try IGnosis(_for).isValidSignature(hashInBytes, signature) returns (bytes4 val) {
			return val == GNOSIS_MAGICVALUE;
		} catch {
			return false;
		}
	}

	function checkERC1271(bytes32 hash, bytes memory signature, address _for) public view returns (bool) {
		try IValidSigner(_for).isValidSignature(hash, signature) returns (bytes4 val) {
			return val == ERC1257_MAGICVALUE;
		} catch {
			return false;
		}
	}

	function isContract(address _address) public view returns (bool) {
		uint256 codeSize;
		assembly {
			codeSize := extcodesize(_address)
		}
		return codeSize > 0;
	}

	// Hmmm....
	function canSignFor(address _user) public view returns (bool) {
		if (_user == msg.sender) return true;

		return false;
	}

	function setHash(bytes32 _hash) external onlyOwner {
		HASH = _hash;
	}

	function setDisclaimer(string calldata _newDisclaimer) external onlyOwner {
		disclaimer = _newDisclaimer;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.20;

interface IGnosis {
	function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.20;

interface IValidSigner {
	function isValidSignature(bytes32 _data, bytes calldata _signature) external view returns (bytes4);
}