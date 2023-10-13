// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "Ownable.sol";

interface IValidSigner {
    function isValidSignature(bytes32 _data, bytes calldata _signature)
        external
        view
        returns (bytes4);
}

interface IGnosis {
    function isValidSignature(bytes calldata _data, bytes calldata _signature)
        external
        view
        returns (bytes4);
}

contract SignatureStorage is Ownable {
    bytes4 public constant ERC1257_MAGICVALUE = 0x1626ba7e;
    bytes4 public constant GNOSIS_MAGICVALUE = 0x20c13b0b;

    bytes32 public HASH;
    mapping(address => bool) public hasSigned;
    string public disclaimer;

    event Signed(address indexed user);

    constructor(bytes32 _hash) {
        HASH = _hash;
    }

    function setHash(bytes32 _hash) external onlyOwner {
        HASH = _hash;
    }

    function canSignFor(address _user) public view returns (bool) {
        if (_user == msg.sender) return true;

        return false;
    }

    function submitSignature(bytes32 hash, bytes memory signature) external returns (bool) {
        require(hash == HASH, "Improper message");
        require(checkSignature(hash, signature, msg.sender), "invalid sig");
        hasSigned[msg.sender] = true;
        emit Signed(msg.sender);
    }

    function extractSignature(bytes memory signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            // Retrieve r by loading the first 32 bytes (offset 0) of the signature
            r := mload(add(signature, 32))

            // Retrieve s by loading the second 32 bytes (offset 32) of the signature
            s := mload(add(signature, 64))

            // Retrieve v by loading the byte (offset 64) following the signature
            v := byte(0, mload(add(signature, 96)))
        }
    }

    function convertBytes32ToBytes(bytes32 data) public pure returns (bytes memory) {
        bytes memory result = new bytes(32);

        assembly {
            mstore(add(result, 32), data)
        }

        return result;
    }

    function checkForEOA(
        bytes32 hash,
        bytes memory signature,
        address _for
    ) public view returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = extractSignature(signature);
        address signer = ecrecover(hash, v, r, s);
        return signer == _for;
    }

    function checkGnosis(
        bytes32 hash,
        bytes memory signature,
        address _for
    ) public view returns (bool) {
        bytes memory hashInBytes = convertBytes32ToBytes(hash);
        // try IGnosis(_for).isValidSignature(hashInBytes, signature) returns (bytes4 val) {
        //     return val == GNOSIS_MAGICVALUE;
        // } catch {
        //     return false;
        // }
    }

    function checkERC1271(
        bytes32 hash,
        bytes memory signature,
        address _for
    ) public view returns (bool) {
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

    function checkSignature(
        bytes32 hash,
        bytes memory signature,
        address _for
    ) public view returns (bool) {
        bool isValid;
        if (isContract(_for)) {
            return checkGnosis(hash, signature, _for) || checkERC1271(hash, signature, _for);
        }
        return checkForEOA(hash, signature, _for);
    }

    function setDisclaimer(string calldata _newDisclaimer) external onlyOwner {
        disclaimer = _newDisclaimer;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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