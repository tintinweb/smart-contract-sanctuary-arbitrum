// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

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
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PaymentChannelManager {
  IERC20 token;
  uint256 challengePeriod; // in blocks

  enum ChannelStatus {
    ACTIVE,
    PENDING,
    CLOSED
  }

  struct PaymentChannel {
    address walletA;
    address proxyA;
    uint balanceA;
    address walletB;
    address proxyB;
    uint balanceB;
    uint index;
    uint challengePeriod;
    ChannelStatus status;
  }

  struct ChannelState {
    bytes32 channelId;
    uint index;
    uint balanceA;
    uint balanceB;
    bytes metadata;
  }

  struct HTLCState {
    bytes32 id;
    address sender;
    uint amount;
    bytes32 hashlock;
    uint timelock;
    bytes32 key;
  }

  mapping(bytes32 => PaymentChannel) channels;

  event ChannelUpdate(bytes32 indexed channelid, address indexed walletA, address indexed walletB, PaymentChannel pc);

  constructor(address _tokenAddress, uint256 _challengePeriod) payable {
    token = IERC20(_tokenAddress);
    challengePeriod = _challengePeriod;
  }

  function getChannelId(PaymentChannel memory _pc) public view returns (bytes32 channelId) {
    channelId = keccak256(abi.encodePacked(_pc.walletA, _pc.walletB, address(this), block.chainid));
  }

  function createChannel(
    address _walletA,
    address _proxyA,
    address _walletB,
    address _proxyB,
    uint _amount
  ) public returns (bytes32 channelId) {
    token.transferFrom(_walletA, address(this), _amount);
    token.transferFrom(_walletB, address(this), _amount);
    PaymentChannel memory pc = PaymentChannel(
      _walletA,
      _proxyA,
      _amount,
      _walletB,
      _proxyB,
      _amount,
      0,
      0,
      ChannelStatus.ACTIVE
    );

    channelId = getChannelId(pc);
    channels[channelId] = pc;
    emit ChannelUpdate(channelId, _walletA, _walletB, pc);
  }

  function getChannelStateHash(ChannelState memory _cs) public pure returns (bytes32 stateHash) {
    stateHash = keccak256(abi.encode(_cs.channelId, _cs.index, _cs.balanceA, _cs.balanceB, _cs.metadata));
  }

  function closeChannel(
    ChannelState memory _cs,
    bytes calldata _sigA,
    bytes calldata _sigB
  ) public returns (ChannelStatus status) {
    PaymentChannel storage pc = channels[_cs.channelId];

    require(pc.status == ChannelStatus.ACTIVE, "Inactive channel");
    isValidState(_cs, _sigA, _sigB);
    require(keccak256(_cs.metadata) == keccak256(bytes("CLOSE")), "Invalid close msg");

    pc.balanceA = _cs.balanceA;
    pc.balanceB = _cs.balanceB;
    pc.status = ChannelStatus.CLOSED;

    token.transfer(pc.walletA, _cs.balanceA);
    token.transfer(pc.walletB, _cs.balanceB);

    emit ChannelUpdate(_cs.channelId, pc.walletA, pc.walletB, pc);
    return pc.status;
  }

  function requestCloseChannel(
    ChannelState memory _cs,
    bytes calldata _sigA,
    bytes calldata _sigB
  ) public returns (ChannelStatus status) {
    PaymentChannel storage pc = channels[_cs.channelId];

    require(pc.status == ChannelStatus.ACTIVE, "Inactive channel");
    isValidState(_cs, _sigA, _sigB);

    HTLCState[] memory htlcs = abi.decode(_cs.metadata, (HTLCState[]));
    for (uint i = 0; i < htlcs.length; i++) {
      HTLCState memory htlc = htlcs[i];
      if (htlc.timelock > block.number && htlc.key != bytes32(0) && htlc.hashlock == keccak256(abi.encode(htlc.key))) {
        if (htlc.sender == pc.walletA) {
          _cs.balanceA -= htlc.amount;
          _cs.balanceB += htlc.amount;
        } else {
          _cs.balanceB -= htlc.amount;
          _cs.balanceA += htlc.amount;
        }
      }
    }
    pc.balanceA = _cs.balanceA;
    pc.balanceB = _cs.balanceB;
    pc.index = _cs.index;
    pc.challengePeriod = block.number + challengePeriod;
    pc.status = ChannelStatus.PENDING;

    emit ChannelUpdate(_cs.channelId, pc.walletA, pc.walletB, pc);
    return ChannelStatus.PENDING;
  }

  function challengeCloseChannel(
    ChannelState memory _cs,
    bytes calldata _sigA,
    bytes calldata _sigB
  ) public returns (ChannelStatus status) {
    PaymentChannel storage pc = channels[_cs.channelId];

    require(pc.status == ChannelStatus.PENDING, "Non-pending channel");
    require(_cs.index > pc.index, "Older state provided");
    require(pc.challengePeriod >= block.number, "Challenge period over");

    isValidState(_cs, _sigA, _sigB);

    HTLCState[] memory htlcs = abi.decode(_cs.metadata, (HTLCState[]));
    for (uint i = 0; i < htlcs.length; i++) {
      HTLCState memory htlc = htlcs[i];
      if (htlc.timelock > block.number && htlc.key != bytes32(0) && htlc.hashlock == keccak256(abi.encode(htlc.key))) {
        if (htlc.sender == pc.walletA) {
          _cs.balanceA -= htlc.amount;
          _cs.balanceB += htlc.amount;
        } else {
          _cs.balanceB -= htlc.amount;
          _cs.balanceA += htlc.amount;
        }
      }
    }
    pc.balanceA = _cs.balanceA;
    pc.balanceB = _cs.balanceB;
    pc.index = _cs.index;
    pc.status = ChannelStatus.CLOSED;

    token.transfer(pc.walletA, _cs.balanceA);
    token.transfer(pc.walletB, _cs.balanceB);

    emit ChannelUpdate(_cs.channelId, pc.walletA, pc.walletB, pc);
    return ChannelStatus.CLOSED;
  }

  function isValidState(ChannelState memory _channelState, bytes calldata _sigA, bytes calldata _sigB) public view {
    PaymentChannel memory pc = channels[_channelState.channelId];

    require(pc.balanceA + pc.balanceB == _channelState.balanceA + _channelState.balanceB, "Balance mismatch");

    bytes32 stateHash = getChannelStateHash(_channelState);
    require(isValidSignature(pc.proxyA, stateHash, _sigA), "Invalid A's signature");
    require(isValidSignature(pc.proxyB, stateHash, _sigB), "Invalid B's signature");
  }

  function isValidSignature(address signer, bytes32 hash, bytes memory signature) internal pure returns (bool) {
    (address recovered, ECDSA.RecoverError error, ) = ECDSA.tryRecover(hash, signature);
    return error == ECDSA.RecoverError.NoError && recovered == signer;
  }
}