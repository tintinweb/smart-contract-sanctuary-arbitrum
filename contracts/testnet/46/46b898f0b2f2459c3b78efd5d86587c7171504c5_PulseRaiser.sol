// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ClaimTracker.sol";
import "./Normalizer.sol";
import "./interfaces/IPulseRaiser.sol";

contract PulseRaiser is IPulseRaiser, Normalizer, ClaimTracker {
    // guard against ERC20 tokens that do now follow the ERC20, such as USDT
    using SafeERC20 for IERC20;
    // use sendValue to transfer native currency
    using Address for address payable;

    address public wallet;

    // 1111111111, see pppval
    uint256 private constant LOWEST_10_BITS_MASK = 1023;

    // DO NOT MODIFY the PERIODS constant
    uint8 public constant PERIODS = 30;
    uint256 public constant PERIOD_SECONDS = 1 days;

    //
    // - STORAGE
    //

    // The amount of points allocated to each day's normalized price
    uint32 public immutable points;
    // The sale starts at this time
    uint32 public launchAt;

    // Instead of storing 30 uint256 price values for 30 days, which takes 30 SSTOREs
    // use two slots to encode reduced prices for each day. A day's price is contained
    // in a 10-bit span, 25x10 == 250 bits (which fits into a uint256) + 5x10 which fits
    // into a second one.
    uint256[2] public encodedpp;

    // store point balances of all the participating accounts
    mapping(address => uint256) public pointsGained;

    // points allocated here
    uint256 public pointsLocal;
    uint256 public raiseLocal;

    // generation token
    IERC20 public token;
    uint256 public tokenPerPoint;

    bool public claimsEnabled;
    bytes32 public merkleRoot;

    address public immutable wrappedNative;

    constructor(
        address token_,
        address wrappedNative_,
        address wallet_,
        uint32 points_,
        address[] memory stables_,
        address[] memory assets_,
        address[] memory feeds_
    ) Normalizer() {
        // NOTE: ignore token_ being address(0); this would indicate
        // a collatable deployment that doesn't need a token
        require(wrappedNative_ != address(0), "Zero Wrapped Native Token");
        require(wallet_ != address(0), "Zero Wallet Addr");
        require(points_ > 0, "Zero Points");

        points = points_;

        wallet = wallet_;

        wrappedNative = wrappedNative_;

        if (token_ != address(0)) {
            token = IERC20(token_);
        }

        if (assets_.length > 0) {
            _controlAssetsWhitelisting(assets_, feeds_);
        }

        if (stables_.length > 0) {
            bool[] memory states_ = new bool[](stables_.length);
            for (uint8 t = 0; t < stables_.length; t++) {
                states_[t] = true;
            }
            _controlStables(stables_, states_);
        }

        encodedpp[
            0
        ] = 820545819910267688809181204034835617660015146854381185410943199127741239396;
        encodedpp[1] = 823165490612735;
    }

    function estimate(
        address token_,
        uint256 amount
    ) external view returns (uint256) {
        _requireSaleInProgress();
        _requireTokenWhitelisted(token_);

        uint256 numerator_ = points * _normalize(token_, amount);

        uint256 currentPrice_ = _currentPrice();

        return numerator_ / currentPrice_;
    }

    function normalize(
        address token_,
        uint256 amount_
    ) external view returns (uint256) {
        return _normalize(token_, amount_);
    }

    function currentPrice() external view returns (uint256) {
        _requireSaleInProgress();
        return _currentPrice();
    }

    function nextPrice() external view returns (uint256) {
        return _nextPrice();
    }

    //
    // - MUTATORS
    //
    function contribute(
        address token_,
        uint256 tokenAmount,
        string calldata referral
    ) external payable {
        _requireNotPaused();
        _requireSaleInProgress();
        _requireEOA();

        address account = msg.sender;
        uint256 normalizedAmount;

        bool tokenContributionOn = token_ != address(0) && tokenAmount > 0;

        if (tokenContributionOn) {
            _requireTokenWhitelisted(token_);
            normalizedAmount += _normalize(token_, tokenAmount);
        }

        if (msg.value > 0) {
            normalizedAmount += _normalize(wrappedNative, msg.value);
        }

        uint256 pointAmount = (points * normalizedAmount) / _currentPrice();

        require(pointAmount > 0, "Insufficient Contribution");

        pointsGained[account] += pointAmount;

        pointsLocal += pointAmount;

        raiseLocal += normalizedAmount;

        emit PointsGained(account, pointAmount);

        if (bytes(referral).length != 0) {
            emit Referral(referral, normalizedAmount);
        }

        if (tokenContributionOn) {
            IERC20(token_).safeTransferFrom(account, wallet, tokenAmount);
        }

        if (msg.value > 0) {
            payable(wallet).sendValue(msg.value);
        }
    }

    function claim(
        uint256 index_,
        uint256 points_,
        bytes32[] calldata proof_
    ) external {
        _requireNotPaused();
        _requireClaimsEnabled();
        address account = msg.sender;
        uint256 pointsTotal;

        // if there's a points record, delete and add token based on points held
        if (pointsGained[account] > 0) {
            pointsTotal += pointsGained[account];
            delete pointsGained[account];
        }

        // if a valid proof is supplied, mark used and add token based on points held
        if (proof_.length > 0) {
            require(_attempSetClaimed(index_), "Proof Already Used");
            bytes32 node = keccak256(
                abi.encodePacked(index_, account, points_)
            );

            require(
                MerkleProof.verifyCalldata(proof_, merkleRoot, node),
                "Invalid Merkle Proof"
            );

            pointsTotal += points_;
        }

        if (pointsTotal > 0) {
            uint256 amountToDistribute = pointsTotal * tokenPerPoint;
            token.safeTransfer(account, amountToDistribute);
            emit Distributed(account, amountToDistribute);
        }
    }

    //
    // - MUTATORS (ADMIN)
    //
    function launch(uint32 at) external {
        _checkOwner();
        require(launchAt == 0, "No Restarts");
        if (at == 0) {
            launchAt = uint32(block.timestamp);
        } else {
            require(at > block.timestamp, "Future Timestamp Expected");
            launchAt = at;
        }
        emit LaunchTimeSet(launchAt);
    }

    function setRaiseWallet(address wallet_) external {
        _checkOwner();
        require(wallet_ != address(0), "Zero Wallet Addr");

        emit RaiseWalletUpdated(wallet, wallet_);
        wallet = wallet_;
    }

    function modifyPriceBase(uint8 dayIndex_, uint16 priceBase_) external {
        _checkOwner();
        _requireDayInRange(dayIndex_);
        _requireValidPriceBase(priceBase_);

        uint8 encodedppIndex = (dayIndex_ < 25) ? 0 : 1;

        uint16[] memory priceBases = _splitPriceBases(encodedppIndex);

        uint8 from = (dayIndex_ < 25) ? 0 : 25;
        uint8 count = (dayIndex_ < 25) ? 25 : 5;
        priceBases[dayIndex_ - from] = priceBase_;

        encodedpp[encodedppIndex] = _encodePriceBasesMemory(priceBases, count);

        emit PriceBaseModified(dayIndex_, priceBase_);
    }

    function modifyPriceBases(uint16[] calldata priceBases) external {
        _checkOwner();
        require(priceBases.length == PERIODS, "Invalid Bases Count");
        for (uint8 i = 0; i < PERIODS; i++) {
            _requireValidPriceBase(priceBases[i]);
        }

        encodedpp[0] = _encodePriceBases(priceBases, 0, 25);
        encodedpp[1] = _encodePriceBases(priceBases, 25, 5);

        emit PriceBasesBatchModified();
    }

    function distribute(
        bytes32 merkleRoot_,
        uint256 pointsOtherNetworks
    ) external {
        _checkOwner();
        require(address(token) != address(0), "Not the Primary Contract");
        require(
            (launchAt > 0) &&
                (block.timestamp >= launchAt + PERIODS * PERIOD_SECONDS),
            "Wait for Sale to Complete"
        );
        require(!claimsEnabled, "Distribution Locked");
        claimsEnabled = true;

        uint256 pointsTotal = pointsLocal + pointsOtherNetworks;

        uint256 distributionSupply = token.balanceOf(address(this));

        tokenPerPoint = distributionSupply / pointsTotal;

        merkleRoot = merkleRoot_;
        emit TotalPointsAllocated(pointsTotal, tokenPerPoint);
    }

    //
    // - INTERNALS
    //
    function _currentPrice() internal view returns (uint256) {
        // if not yet launched will revert, otherwise will result
        // in days 0..N, where the largest legal N is 29, pppval
        // will revert starting with dayIndex == 30
        uint8 dayIndex = uint8((block.timestamp - launchAt) / PERIOD_SECONDS);

        return _pppval(dayIndex);
    }

    function _nextPrice() internal view returns (uint256) {
        uint256 tmrwIndex = ((block.timestamp - launchAt) / PERIOD_SECONDS) + 1;

        if (tmrwIndex > PERIODS - 1) return 0;

        return _pppval(uint8(tmrwIndex));
    }

    function _pppval(uint8 dayIndex) internal view returns (uint256 price_) {
        _requireDayInRange(dayIndex);
        if (dayIndex < 25)
            price_ =
                ((encodedpp[0] >> (dayIndex * 10)) & LOWEST_10_BITS_MASK) *
                1e16;
        else {
            uint8 adjDayIndex = dayIndex - 25;
            price_ =
                ((encodedpp[1] >> (adjDayIndex * 10)) & LOWEST_10_BITS_MASK) *
                1e16;
        }
    }

    function _requireValidPriceBase(uint16 pb) internal pure {
        require(pb <= 1023, "Price Base Exceeds 10 Bits");
        require(pb > 0, "Zero Price Base");
    }

    function _requireClaimsEnabled() internal view {
        require(claimsEnabled, "Wait for Claims");
    }

    function _encodePriceBases(
        uint16[] calldata bases_,
        uint8 from,
        uint8 count
    ) private pure returns (uint256 encode) {
        for (uint8 d = from; d < from + count; d++) {
            encode = encode | (uint256(bases_[d]) << ((d - from) * 10));
        }
    }

    function _encodePriceBasesMemory(
        uint16[] memory bases_,
        uint8 count
    ) private pure returns (uint256 encode) {
        for (uint8 d = 0; d < count; d++) {
            encode = encode | (uint256(bases_[d]) << (d * 10));
        }
    }

    function _splitPriceBases(
        uint8 encodedppIndex
    ) private view returns (uint16[] memory) {
        uint16[] memory split = new uint16[](25);
        for (uint8 dayIndex = 0; dayIndex < 25; dayIndex++) {
            split[dayIndex] = uint16(
                (encodedpp[encodedppIndex] >> (dayIndex * 10)) &
                    LOWEST_10_BITS_MASK
            );
        }
        return split;
    }

    function _requireSaleInProgress() internal view {
        require(launchAt > 0, "Sale Time Not Set");
        require(block.timestamp >= launchAt, "Sale Not In Progress");
        require(
            block.timestamp <= launchAt + PERIODS * PERIOD_SECONDS,
            "Sale Ended"
        );
    }

    function _requireEOA() internal view {
        require(msg.sender == tx.origin, "Caller Not an EOA");
    }

    function _requireDayInRange(uint8 dayIndex) internal pure {
        require(dayIndex < PERIODS, "Expected a 0-29 Day Index");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract ClaimTracker {
    mapping(uint256 => uint256) public claimed;

    function _attempSetClaimed(uint256 index_) internal returns (bool) {
        uint256 claimedWordIndex = index_ / 256;
        uint256 claimedBitIndex = index_ % 256;

        uint256 claimedWord = claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        bool isClaimed = claimedWord & mask == mask;
        if (isClaimed) return false;

        claimed[claimedWordIndex] =
            claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// https://docs.chain.link/data-feeds/l2-sequencer-feeds
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OwnablePausable.sol";

import "./interfaces/INormalizer.sol";

interface IERC20Metadata_ {
    function decimals() external view returns (uint8);
}

abstract contract Normalizer is OwnablePausable, INormalizer {
    address public constant ARB_MAINNET_SEQ_FEED =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant ARB_GOERLI_SEQ_FEED =
        0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69;

    uint256 private constant ARBITRUM_ONE = 42161;
    uint256 private constant ARBITRUM_NOVA = 42170;
    uint256 private constant ARBITRUM_GOERLI = 421613;
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    AggregatorV2V3Interface public sequencerUptimeFeed;

    // map an asset to a feed that returns its conversion rate to normalized token
    mapping(address => address) public feeds;
    // enabled stablecoins like USDT, USDC, and BUSD that need no normalization
    mapping(address => bool) public stables;

    constructor() {
        if (block.chainid == ARBITRUM_ONE || block.chainid == ARBITRUM_NOVA) {
            sequencerUptimeFeed = AggregatorV2V3Interface(ARB_MAINNET_SEQ_FEED);
        } else if (block.chainid == ARBITRUM_GOERLI) {
            sequencerUptimeFeed = AggregatorV2V3Interface(ARB_GOERLI_SEQ_FEED);
        }
    }

    //
    // - MUTATORS (ADMIN)
    //
    function controlAssetsWhitelisting(
        address[] memory tokens_,
        address[] memory feeds_
    ) external {
        _checkOwner();

        _controlAssetsWhitelisting(tokens_, feeds_);
    }

    function controlStables(
        address[] memory stables_,
        bool[] memory states_
    ) external {
        _checkOwner();

        _controlStables(stables_, states_);
    }

    //
    // - INTERNALS
    //
    function _controlAssetsWhitelisting(
        address[] memory assets_,
        address[] memory feeds_
    ) internal {
        uint256 numAssets = assets_.length;
        for (uint256 f = 0; f < numAssets; f++) {
            require(assets_[f] != address(0), "Zero Asset Address");
            feeds[assets_[f]] = feeds_[f];
            if (feeds_[f] == address(0)) {
                emit AssetDisabled(assets_[f]);
            } else {
                emit AssetEnabled(assets_[f], feeds_[f]);
            }
        }
    }

    function _controlStables(
        address[] memory assets_,
        bool[] memory states_
    ) internal {
        require(assets_.length == states_.length, "Mismatched Arrays");

        for (uint8 f = 0; f < assets_.length; f++) {
            require(assets_[f] != address(0), "Zero Asset Address");
            stables[assets_[f]] = states_[f];
            if (states_[f]) {
                emit AssetEnabled(assets_[f], assets_[f]);
            } else {
                emit AssetDisabled(assets_[f]);
            }
        }
    }

    function _requireTokenWhitelisted(address asset_) internal view {
        require(
            feeds[asset_] != address(0) || stables[asset_],
            "Invalid Payment Asset"
        );
    }

    function _normalize(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        if (token == address(0)) return 0;
        if (stables[token]) {
            return amount * (10 ** (18 - IERC20Metadata_(token).decimals()));
        }

        return _priceFeedNormalize(token, amount);
    }

    function _priceFeedNormalize(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        _ensureSequencerUp();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeds[token]);

        (, int price, , , ) = priceFeed.latestRoundData();

        uint8 tokenDecimals = IERC20Metadata_(token).decimals();

        return
            ((uint256(price) * amount) / (10 ** priceFeed.decimals())) *
            (10 ** (18 - tokenDecimals));
    }

    function _ensureSequencerUp() internal view {
        // short-circuit if we're not on Arbitrum
        if (address(sequencerUptimeFeed) == address(0)) return;

        // prettier-ignore
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        require(isSequencerUp, "ARB: Sequencer Is Down");

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        require(timeSinceUp > GRACE_PERIOD_TIME, "ARB: Grace Period Not Over");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IPulseRaiserEvents.sol";

interface IPulseRaiser is IPulseRaiserEvents {
    // - VIEWS
    //
    // @dev Calculate the number of points that an amount of a token will pay for during this stint.
    //      Use the wrapped ERC20 equivalent to estimate a contribution in native currency. If you need
    //      to estimate both at the same time, call `estimate` twice.
    //
    // @param A whitelisted ERC20 token.
    // @amount The amount to assess.
    //
    // Requirements:
    // - Token is whitelisted;
    // - The sale is in progress.
    function estimate(
        address token,
        uint256 amount
    ) external view returns (uint256);

    // @dev Get normalized amount for a token. 
    // 
    // @param A whitelisted ERC20 token.
    // @amount The amount to assess.
    function normalize(
        address token,
        uint256 amount
    ) external view returns (uint256);

    // current normalized price of 10k points
    function currentPrice() external view returns (uint256);

    // tomorrow's normalized price of 10k points; 0 if sale ends before that
    function nextPrice() external view returns (uint256);

    //
    // - MUTATORS
    //
    // @dev Contribute an amount of token in exchange for points. Native currency sent along
    //      will be considered as well and normalized using the wrapped ERC20 equivalent.
    //
    // Requirements:
    // - Token is whitelisted;
    // - The sale is in progress.
    // - The contract is not paused.
    function contribute(address token, uint256 tokenAmount, string calldata referral) external payable;

    // @dev Claim token based on accumulated points. If a Merkle proof is supplied,
    //      will also claim based on tokens accumulated on other chains. If not, only
    //      the accounting in this contract will apply. Either claim (contract-based accounting
    //      or Merkle-based) can only be executed once.
    function claim(
        uint256 index_,
        uint256 points_,
        bytes32[] calldata proof_
    ) external;

    //
    // - MUTATORS (ADMIN)
    //
    // @dev Owner-only. Modify price base for a single day.
    //
    // @param dayIndex_ The day to modify pricing for. Must range from 0
    //        (which represents the first day of the sale) to 19 (inclusive,
    //         which represents the 20th day).
    // @param priceBase_ The price base per 10k points. Must range from 1 to
    //        1023 and will be divided by 100 to infer the normalized (dollar) value.
    //        E.g., 950 translates to $9.50.
    function modifyPriceBase(uint8 dayIndex_, uint16 priceBase_) external;

    // @dev Owner-only. Simultaneously modify pricing for all days.
    // @param priceBases See `modifyPriceBase` for per-element requirements. Element 0
    //        of the array corresponds to day 1, element 19 corresponds to day 20. The
    //        array must include exactly 20 non-zero elements.
    //
    function modifyPriceBases(uint16[] calldata priceBases) external;

    // @dev Owner-only. Must be called after the sale is completed. Can only be called once.
    //                  Set the Merkle tree to support claiming of tokens based on points
    //                  accumulated on other chains. Enable claiming.
    //
    // @param merkleRoot_ Merkle tree root.
    // @param pointsOtherNetworks The total of points accumulated by contributors on other chains.
    //
    function distribute(bytes32 merkleRoot_, uint256 pointsOtherNetworks) external;

    // @dev Owner-only. Set launch time. 
    //
    // @param at If 0, sets the launch time to block.timestamp and starts the sale immediately.
    //           Must be above block.timestamp otherwise (in the future).
    function launch(uint32 at) external;
     

    // @dev Owner-only. Change the raise wallet address.
    // 
    // @param wallet_ The address of the new wallet. Cannot be address(0).
    function setRaiseWallet(address wallet_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IOwnablePausableEvents.sol";

contract OwnablePausable is Ownable, Pausable, IOwnablePausableEvents {
    function toggle() external {
        _checkOwner();
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        emit PauseStateSet(paused());
    }

    function _requireNotPaused() internal view virtual override {
        require(!paused(), "Contract Paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./INormalizerEvents.sol";

interface INormalizer is INormalizerEvents {
    // @dev Owner-only. Enable/disable whitelisted ERC20 assets (non-stables) that can be evaluated in USD via
    //      Chainlink price feeds.
    function controlAssetsWhitelisting(
        address[] memory tokens_,
        address[] memory feeds_
    ) external;

    // @dev Owner-only. Enable/disable whitelisted ERC20 stablecoins. 
    function controlStables(
        address[] memory stables_,
        bool[] memory states_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IPulseRaiserEvents {
    event PriceBaseModified(uint8 indexed day, uint16 indexed base);
    event PriceBasesBatchModified();
    event PointsGained(address indexed account, uint256 indexed pointAmount);
    event TotalPointsAllocated(
        uint256 indexed pointsTotal,
        uint256 indexed tokenPerPoint
    );
    event Referral(string indexed referral, uint256 indexed normalizedAmount);
    event RaiseWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event ClaimsEnabled();
    event LaunchTimeSet(uint32 indexed launchTimestamp);
    event Distributed(address indexed account, uint256 indexed amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOwnablePausableEvents {
    event PauseStateSet(bool indexed state);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface INormalizerEvents {
    event AssetDisabled(address indexed asset);
    event AssetEnabled(address indexed asset, address indexed feed);
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