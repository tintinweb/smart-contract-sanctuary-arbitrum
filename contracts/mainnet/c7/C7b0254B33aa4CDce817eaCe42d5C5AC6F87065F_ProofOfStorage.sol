// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/
pragma solidity ^0.8.0;

interface ISimpleINFT {
    // Create or Transfer Node
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Return amount of Nodes by owner
    function balanceOf(address owner) external view returns (uint256);

    // Return Token ID by Node address
    function getNodeIDByAddress(address _node) external view returns (uint256);

    // Return owner address by Token ID
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMetaData {
    // Create or Update Node
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ipAddress,
        uint16 port
    );

    // Structure for Node
    struct DeNetNode{
        uint8[4] ipAddress; // for example [127,0,0,1]
        uint16 port;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 updatesCount;
        uint256 rank;
    }

    // Return Node info by token ID;
    // function nodeInfo(uint256 tokenId) external view returns (IMetaData.DeNetNode memory);
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);
}

interface IDeNetNodeNFT {
     function totalSupply() external view returns (uint256);

     // PoS Only can ecevute
     function addSuccessProof(address _nodeOwner) external;

     function getLastUpdateByAddress(address _user) external view returns(uint256);
     function getNodesRow(uint _startId, uint _endId) external view returns(IMetaData.DeNetNode[] memory);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IOldPayments {
    
    event LocalTransferFrom(
        address indexed _token,
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event RegisterToken(
        address indexed _token,
        uint256 indexed _id
    );

    function getBalance(address _token, address _address)
        external
        view
        returns (uint256 result);

    function localTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function depositToLocal(
        address _user_address,
        address _token,
        uint256 _amount
    ) external;

    function closeDeposit(address _user_address, address _token) external;
}

pragma solidity ^0.8.0;

interface IPayments {
    event ChangePoSContract(address indexed PoS_Contract_Address);
    event RegisterToken(address indexed _token, uint256 indexed _id);

    function getBalance(address _address) external view returns (uint256 result);
    function localTransferFrom(address _from, address _to, uint256 _amount) external;
    function depositToLocal(address _user_address, uint256 _amount) external;
    function closeDeposit(address _user_address) external;
    function getSystemReward() external  view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.9;

interface IProofOfStorage {

    event TargetProofTimeUpdate(
        uint256 _newTargetProofTime
    );

    event MinStorageSizeUpdate(
        uint256 _newMinStorageSize
    );

    /*
        @dev Returns info about user reward for ProofOfStorage

        INPUT
            @_user - User Address
            @_user_storage_size - User Storage Size

        OUTPUT
            @_amount - Total Token Amount for PoS
            @_last_rroof_time - Last Proof Time
    */


    function getUserRewardInfo(address _user, uint _user_storage_size)
        external
        view
        returns (
            uint,
            uint
        );
    
    /*
        @dev Returns last user root hash and nonce.

        INPUT
            @_user - User Address
        
        OUTPUT
            @_hash - Last user root hash
            @_nonce - Noce of root hash
    */
    function getUserRootHash(address _user)
        external
        view
        returns (bytes32, uint);
    
    /**
    * @dev this function update Target Proof time, to move difficulty on same size.
    */
    function setTargetProofTime(uint _newTargetProofTime) external;

    /**
    * @dev this function update Min Storage Size, it means, if min storage size = 500, but 
    * user store less size of data, user storage size will rounding up to 500 MB.
    * it's need's to make mining profitable for prooving small users, but 
    * reward will more, than tx proof cost for miner..
    */
    function setMinStorage(uint _size) external;

    function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) external;

    // This Function calls from Traffic Manager
    function initTrafficPayment(address _user_address, uint _amount) external;
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );


    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _nonce,
        address _updater
    ) external;

    /*
        updateLastProofTime

        Function set current timestamp yo lastProofTime in users[userAddress]. it means, that
        userDifficulty = zero (current time - lastProofTime), and will grow  with time.
    */
    function updateLastProofTime(address userAddress) external;
    
    /* 
        getPeriodFromLastProof
        function return userDifficulty.
        userDifficulty =  timestamp (curren time - lastProofTime)
    */
    function getPeriodFromLastProof(address userAddress) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

/**
* @dev Proof Of Storage - Consensus for Decentralized Storage.
* This contract solve problem with Nodes veriify and payment system
*/

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IUserStorage.sol";
import "./interfaces/IPayments.sol";
import "./interfaces/IOldPayments.sol";
import "./interfaces/INodeNFT.sol";
import "./interfaces/IContractStorage.sol";
import "./interfaces/IProofOfStorage.sol";
import "./utils/CryptoProofUtils.sol";
import "./utils/StringNumbersConstant.sol";


contract Depositable is StringNumbersConstant {
    using SafeMath for uint;

    address public paymentsAddress;

    /**
    *   Value target Proof Time used for modearating speed of sending proofs,
    *   targetProofTime => Smaller, then users count grow, but nodes not
    *   targetProofTime => Grow, then nodes count grow, but users not
    *   This value will exact to baseDifficulty, when node sending proofs faster than
    *     targetProofTime, baseDifficulty will grow, if nodes will send proofs slower
    *     than targetProofTime, baseDifficulty will down
    **/
    uint256 public targetProofTime = 60*10; // 10 min

    constructor () {}

    /**
        @notice make deposit function.

        @param _amount - Amount of  Pair Token

        @dev Require approve from Pair Token to paymentsAddress
    */
    function makeDeposit(uint256 _amount) external {
        /* Updating Deposit amount */
        IPayments _payment = IPayments(paymentsAddress);
        _payment.depositToLocal(msg.sender, _amount);
    }

    /**
        @notice close deposit functuin. Will burn part of gastoken and return pair token to msg.sender
    */
    function closeDeposit() external {
        IPayments _payment = IPayments(paymentsAddress);
        _payment.closeDeposit(msg.sender);
    }

    /**
        @notice updateTargetProofTime, this function set new target proof time for all nodes
    */
    function updateTargetProofTime(uint _newTargetProofTime) internal {
        targetProofTime = _newTargetProofTime;
    }
}

contract ProofOfStorage is Ownable, CryptoProofs, Depositable, IProofOfStorage {
    using SafeMath for uint;


    /**
        @notice Contract Storage Address to get info about updates
    */
    address public contractStorageAddress;

    /**
       @notice Address of smart contract, where User Storage placed
    */
    address public userStorageAddress;
   
    /**
        @notice Address of smart contract, where NFT of nodes placed
    */
    address public node_nft_address = address(0);
    
    /**
        @notice  Max blocks after proof needs to use newest proof as it possible
        
        see more, in StringNumbersConstant
    */
    uint256 private _max_blocks_after_proof = MAX_BLOCKS_AFTER_PROOF;
    
    /**
        @dev Minimal sotrage size for proof. 

        in Polygon netowrk best min storage size ~10GB (~0.03 USD or more per month).
        if user store less than 10GB, user storage size will increased to min_storage_require

        @notice min_storage_require in megabytes.

    */
    uint public min_storage_require = 102400; // replace to after testnet ends STORAGE_10GB_IN_MB;

    /**
        @dev DAO Contract or Wallet Address
    */
    address public daoContractAddress;
    address public trafficManagerContractAddress;


    constructor(
        address _ContractStorageAddress
    ) Depositable() {
        contractStorageAddress = _ContractStorageAddress;
        sync();
    }

    /*
        Owner Zone Start
    */

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        userStorageAddress = contractStorage.getContractAddressViaName("userstorage", NETWORK_ID);
        paymentsAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        node_nft_address = contractStorage.getContractAddressViaName("nodenft", NETWORK_ID);
        trafficManagerContractAddress = contractStorage.getContractAddressViaName("trafficmanager", NETWORK_ID);
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    // this functuon able to make transfers from traffic manager
    modifier onlyTrafficManager() {
        require(msg.sender == trafficManagerContractAddress, "PoSAdmin:msg.sender != trafficManager");
        _;
    }

    function setTargetProofTime(uint256 _newTargetProofTime) external override onlyDAO {
        updateTargetProofTime(_newTargetProofTime);
        emit TargetProofTimeUpdate(_newTargetProofTime);
    }


    /**
        @notice this function updating Node Rank.

        TODO: Move it to DifficultyManufacturing

        @return current_difficulty - new difficulty for all nodes.
    */
    function _updateNodeRank(address _proofer, uint current_difficulty) internal returns(uint256) { 
        if (node_nft_address != address(0)) {
            IDeNetNodeNFT NFT = IDeNetNodeNFT(node_nft_address);
            uint timeFromLastProof = block.timestamp - NFT.getLastUpdateByAddress(_proofer);
            
            NFT.addSuccessProof(_proofer);
           
            if (timeFromLastProof <= targetProofTime) {
                /* 
                    Difficulty += 0-2% per proof if it faster than timeFromLastProof
                */
                return current_difficulty.mul(targetProofTime*100 + (targetProofTime - timeFromLastProof) * 2).div(targetProofTime*100);
            } else {
                /* 
                    difficulty -= 0-2% (pseudo randomly) per proof if it slower than timeFromLastProof
                */
                if (timeFromLastProof > targetProofTime * 2) {
                    timeFromLastProof = targetProofTime * 2;
                }
                return current_difficulty.mul(targetProofTime*100 - (timeFromLastProof - targetProofTime) * 2).div(targetProofTime*100);
            }
        }
        return current_difficulty;
    }

    /*
        ToDO:
            - Move it into documentation
        
        Increase, if network fees growing
        Decreese, if network fees down

        For example:
            MATIC:
                Matic price: 2$
                Avg gas price: 30 GWEI
                Avg proof gasused: 300,000
                Avg tx cost: 30 x 300,000  = 0,009 MATIC 
                Avg tx price: 0.009 MATIC x 2$ = 0.018$
                1TB/year Price ~30$
                Max period for proof: 30 days. (~2.5$ / TB / Month)
                Min storage size = 0.018 / 2.5$ = 0.0072 TB
            Ethereum:
                ETH price: 4000$
                Avg gas price: 100 GWEI
                Avg proof gasused: 300,000
                Avg tx cost: 100 x 300,000  = 0,03 ETH 
                Avg tx price: 0.03 ETH x 4000$ = 120$
                1TB/year Price ~30$
                Max period for proof: 30 days. (~2.5$ / TB / Month)
                Min storage size = 120 / 2.5$ = 48 TB
            Binance Smart Chain:
                BNB price: 500$
                Avg gas price: 5 GWEI
                Avg proof gasused: 300,000
                Avg tx cost: 5 x 300,000  = 0.0014 BNB 
                Avg tx price: 0.0014 BNB x 500$ = 0.7$
                1TB/year Price ~30$
                Max period for proof: 30 days. (~2.5$ / TB / Month)
                Min storage size = 0.7 / 2.5$ = 0.27 TB
    */
    function setMinStorage(uint _size) external override onlyDAO {
        min_storage_require = _size;
        emit MinStorageSizeUpdate(_size);
    }

    /**
        @notice More _new_difficulty = more random for nodes. Less _new_difficulty more proofs and less randomize.
    */
    function updateBaseDifficulty(uint256 _new_difficulty) public onlyDAO {
        _setDifficulty(_new_difficulty);
    }

    /*
        Owner Zone End
    */

    /*
        Send proof use sendProofFrom with msg.sender address as node
    */
    function sendProof(
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) public {
        sendProofFrom(
            msg.sender,
            _user_address,
            _block_number,
            _user_root_hash,
            _user_storage_size,
            _user_root_hash_nonce,
            _user_signature,
            _file,
            merkleProof
        );
    }

    /*
        Send Proof From - proof of storage mechanism, that look like TransferFrom
        but in case transferFrom, user creating approve transactions. in PoS you don't need to do it.

        _node_address - Who will recieve reward in success case
        _user_address - Who is payer
        _block_number - Block number, to approve tx with newest data (see _max_blocks_after_proof)
        _user_root_hash - root hash, signed by payer
        _user_storage_size - Storage size in MB. or files count (because all files size 1 MB)
        _user_root_hash_nonce - parametr to proof, that is newest data proof
        _user_signature - approve, that root hash, storage size and nonce is correct.
        _file - part of file
        _merkleProof - proof start from part of file, and edns with user_root_hash
    */
  
    function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) public override{
        
        address signer = ECDSA.recover(
            sha256(abi.encodePacked(
                _user_root_hash,
                uint256(_user_storage_size),
                uint256(_user_root_hash_nonce)
            )),
            _user_signature
        );
        require(_user_address == signer, "User address not signer");

        /*
            _amount_returns = amount of TB/Year token

            if something wrong, transaction will rejected
        */
        uint256 _amount_returns = _sendProofFrom (
            _node_address,
            _user_address,
            _block_number,
            _user_root_hash,
            _user_storage_size,
            _user_root_hash_nonce,
            _file,
            merkleProof
        );

        _takePay(_user_address, _node_address, _amount_returns);

        _updateLastProofTime(_user_address);

        /*
            +1 To Node Success proofs, also return new difficulty for all nodes (+- 2%)
        */
        _setDifficulty(_updateNodeRank(_node_address, getUpgradingDifficulty()));
    }

    /**
        @dev Update Root Hash for user.

        @param _user - target user
        @param _updater - address of node or user, who update root_hash
        @param _new_hash - new root hash
        @param _new_storage_size - storage size in megabytes
        @param _new_nonce - updated nonce
    */
    function _updateRootHash(
        address _user,
        address _updater,
        bytes32 _new_hash,
        uint64 _new_storage_size,
        uint64 _new_nonce
    ) private {
        bytes32 _cur_user_root_hash;
        uint256 _cur_user_root_hash_nonce;
        (_cur_user_root_hash, _cur_user_root_hash_nonce) = getUserRootHash(_user);

        require(_new_nonce >= _cur_user_root_hash_nonce, "POS.updateRootHash:_new_nonce < old_nonce");

        /**
            @dev no need update root hash, if it no changed
        */
        if (_new_hash != _cur_user_root_hash) {
            _updateLastRootHash(_user, _new_hash, _new_storage_size, _new_nonce, _updater);
        }
    }

    /**
        @dev Proof Verification

        @param _sender - node
        @param _file - 8kb of data
        @param _block_number - number of block in selected blockchain
        @param _time_passed - time from last proof to now
    */
    function verifyFileProof(
        address _sender,
        bytes calldata _file,
        uint32 _block_number,
        uint256 _time_passed
    ) public view returns (bool) {
        /*  
            Some blockchains have limits for getting blockhash. Most of them last 256 blocks
        */
        require (blockhash(_block_number) != 0x0, "POS.verifyFileProof:blockhash=0");

        /*
            make _file_proof with hash from _file + _node_address + blockhash
        */
        bytes32 _file_proof = sha256(
            abi.encodePacked(_file, _sender, blockhash(_block_number))
        );

        /*
            Verify with difficulty, (more in isMatchDifficulty)
        */
        return isMatchDifficulty(getDifficulty(), uint256(_file_proof), _time_passed);
    }

    function initTrafficPayment(address _user_address, uint _amount) public override onlyTrafficManager {
        _takePay(_user_address, trafficManagerContractAddress, _amount);
    }

    /**
        @return uint256 - amount of gastoken for this proof
    */
    function _sendProofFrom(
        address _proofer,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _user_root_hash_nonce,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) private returns(uint256) {

        bytes32 _file_hash = sha256(_file);

        require(
            _block_number >= block.number - _max_blocks_after_proof,
            "POS._sendProofFrom:_block_number < block.number - _max_blocks_after_proof"
        );

        // not need, with using signature checking
        require(
            _proofer != address(0) && _user_address != address(0),
            "POS._sendProofFrom:_proofer or _user_address = 0"
        );

        /* Check Correct Proof Start */
        
        require(
            _file_hash == merkleProof[0] || _file_hash == merkleProof[1],
            "POS._sendProofFrom:sha256(file) not in merkleProof[0:1]"
        );

        require(
            isValidMerkleTreeProof(_user_root_hash, merkleProof),
            "POS._sendProofFrom:merkleProof is invalid"
        );

        /* Check Correct Proof End */

        // digital signature of user must be checked before this function called
        _updateRootHash(
            _user_address,
            _proofer,
            _user_root_hash,
            _user_storage_size,
            _user_root_hash_nonce
        );
        
        (
            uint256 _amount_returns,
            uint256 _blocks_complited
        ) = getUserRewardInfo(_user_address, _user_storage_size);

        require(
            verifyFileProof(
                _proofer,
                _file,
                _block_number,
                _blocks_complited
            ),
            "POS._sendProofFrom:_proof % baseDifficulty > _targetDifficulty"
        );

        return (_amount_returns);
    }

    /**
        @notice Returns info about user reward for ProofOfStorage

        @param _user - User Address
        @param _user_storage_size - User Storage Size
        
        @return _amount - Total Token Amount for PoS
        @return _last_proof_time - Last Proof Time
    */
    function getUserRewardInfo(address _user, uint _user_storage_size)
        public
        view
        returns (
            uint,
            uint
        )
    {
        require(_user_storage_size != 0, "POS.getUserRewardInfo:_user_storage_size=0");
        

        IUserStorage _storage = IUserStorage(userStorageAddress);
        
        uint _timePassed = _storage.getPeriodFromLastProof(_user);
        
        /*
            Increase user storage size to min_storage_require (10 GB) if it less
        */
        if (_user_storage_size < min_storage_require) {
            _user_storage_size = min_storage_require;
        }

        /*
            Set timePassed to 30 days, if it more.
        */
        if (_timePassed > TIME_30D) {
            _timePassed = TIME_30D;
        }
        
        /*
            TODO: Move it into documentation 

            1e18 - decimals for TB/Year
            31536000 - one year in seconds
            storage size - in megabytes
            1048576 = 1024 x 1024 
            
            Simple:
                amount = timePassed x storage size / one year
            
            True:
                                timePassed x storage size 
                amount = 0e18 x __________________________
                                    31536000 x 1048576
        */
        uint _amountReturns = uint(DECIMALS_18).div(TIME_1Y).mul(_timePassed).mul(_user_storage_size).div(STORAGE_1TB_IN_MB);

        return (_amountReturns, _timePassed);
    }

    /**
        @dev Function move part of deposit  _from to _to
        Transfer deposit from user to node

        @param _from - User Address
        @param _to - node address (who proof)
        @param _amount - amount of prooved storage data
    */
    function _takePay(
        address _from,
        address _to,
        uint _amount
    ) private {
        IPayments _payment = IPayments(paymentsAddress);
        _payment.localTransferFrom(_from, _to, _amount);
    }

    /**
       @dev Returns User Root Hash

       @param _user - user address
       @return sha256 - hash of last user root hash
    */
    function getUserRootHash(address _user)
        public
        view
        returns (bytes32, uint)
    {
        IUserStorage _storage = IUserStorage(userStorageAddress);
        return _storage.getUserRootHash(_user);
    }

    /**
       @notice Set last proof time to current timestamp.
       @param _user_address - address of user,
    */
    function _updateLastProofTime(address _user_address)
        private
    {
        IUserStorage _storage = IUserStorage(userStorageAddress);
        _storage.updateLastProofTime(_user_address);
    }

    /**
        @dev Set root hash, user_storage size and nonce
        
        @param _user_address - address of user
        @param _user_root_hash - merkle tree root hash of FS
        @param _user_storage_size - storage size in megabytes
        @param _nonce - uin256 number
        @param _updater - address of updater (node/user/whatchtower/etc)
    */
    function _updateLastRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _nonce,
        address _updater
    ) private {
        IUserStorage _storage = IUserStorage(userStorageAddress);
        _storage.updateRootHash(
            _user_address,
            _user_root_hash,
            _user_storage_size,
            _nonce,
            _updater
        );
    }
}

// SPDX-License-Identifier: MIT

import "./interfaces/ICryptoProofs.sol";

pragma solidity ^0.8.0;

interface IDifficultyManufacturing {
    event UpdateDifficulty(
        uint newDifficulty
    );
}

contract DifficultyManufacturing is IDifficultyManufacturing{
    /**
        @dev Proof period < 1D, _baseDifficulty++
        Proof period > 1D, _baseDifficulty--

        Using for 'randomly" proof verification.

        1,000,000 is start value for difficulty 
    */
    uint256 private _baseDifficulty = 1000000;
    uint256 private _upgradingDifficulty = _baseDifficulty;

    function _setDifficulty(uint newDifficulty) internal {
        // min difficulty = 10000
        if (newDifficulty < 10000) {
            newDifficulty = 10000;
        }

        _upgradingDifficulty = newDifficulty;
        uint difficultyChangeSize = _baseDifficulty * 10000 / _upgradingDifficulty;
        
        // if difficulty changed more than 4%, update it
        if (difficultyChangeSize > 10400 || difficultyChangeSize <  9600 ) {
            _baseDifficulty = _upgradingDifficulty;
            emit UpdateDifficulty(_baseDifficulty);
        }
    }

    function getDifficulty() public view returns(uint){
        return _baseDifficulty;
    }

    function getUpgradingDifficulty() public view returns(uint) {
        return _upgradingDifficulty;
    }
}

contract CryptoProofs is DifficultyManufacturing, ICryptoProofs {
    event WrongError(bytes32 wrongHash);

    // TODO: transform merkle proof verification to efficient as OZ
    function isValidMerkleTreeProof(
        bytes32 rootHash,
        bytes32[] calldata proof
    ) public override pure returns (bool) {
        bytes32 nextProof = 0;
        for (uint32 i = 0; i < proof.length / 2; i++) {
            nextProof = sha256(
                abi.encodePacked(proof[i * 2], proof[i * 2 + 1])
            );
            if (proof.length - 1 > i * 2 + 3) {
                if (
                    proof[i * 2 + 2] == nextProof &&
                    proof[i * 2 + 3] == nextProof
                ) {
                    return false;
                }
            } else if (proof.length - 1 > i * 2 + 2) {
                if (proof[i * 2 + 2] != nextProof) {
                    return false;
                }
            }
        }
        return rootHash == nextProof;
    }

    /*
        Matching diffuclty, where _targetDifficulty = some growing number, 
        for example _targetDiffuculty = seconds from last proof for selected user
        
        _proof = sha256 of something
        _targetDiffuculty = seconds from last proof 
        _baseDifficulty
        
    */
    function isMatchDifficulty(uint baseDiff, uint256 _proof, uint256 _targetDifficulty)
        public
        pure
        returns (bool)
    {
        if (_proof % baseDiff < _targetDifficulty) {
            return true;
        }
        return false;
    }

    function getBlockNumber() public view returns (uint32) {
        return uint32(block.number);
    }

     // Show Proof for Test
    function getProof(bytes calldata _file, address _sender, uint256 _blockNumber) public view returns(bytes memory, bytes32) {
        bytes memory _packed = abi.encodePacked(_file, _sender, blockhash(_blockNumber));
        bytes32 _proof = sha256(_packed);
        return (_packed, _proof);
    }

    function getBlockHash(uint32 _n) external view returns (bytes32) {
        return blockhash(_n);
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.9;

interface ICryptoProofs {
     /*
        @dev Returns true/false of rooth hash contains in _proof via sha256

        INPUT
            @_root_hash - root hash of merkleTree
            @_proof - Merkletree array
        OUTPUT
            @result (bool) - is valid merkletree proof
    */
    function isValidMerkleTreeProof(
        bytes32 rootHash,
        bytes32[] calldata _proof
    ) external view returns (bool);

    /*
        Matching diffuclty, where _targetDifficulty = some growing number, 
        for example _targetDiffuculty = seconds from last proof for selected user
        
        _proof = sha256 of something
        _targetDiffuculty = seconds from last proof 
        base_difficult
        
    */
    // function isMatchDifficulty(uint256 _proof, uint256 _targetDifficulty) external pure returns (bool);
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
   uint public constant STORAGE_100GB_IN_MB = 102400; // 100 GB;
  
   // nax blocks after proof depends of network, most of them 256 is ok
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   // Polygon Network Settigns
   address public constant PAIR_TOKEN_START_ADDRESS = 0x081Ec4c0e30159C8259BAD8F4887f83010a681DC; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x15968404140CFB148365577D669477E1615557C0; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 2241;

   // StorageToken Default Vars
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
}