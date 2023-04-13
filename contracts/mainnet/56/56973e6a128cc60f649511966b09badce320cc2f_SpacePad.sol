/**
 *Submitted for verification at Arbiscan on 2023-04-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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
     * @dev Calldata version of {processMultiProof}
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract SpacePad is Context, Ownable {
    uint256 public denominator = 10_000;

    constructor() {
        users[msg.sender] = true;
    }

    event BuyToken(
        address _token,
        address _user,
        uint256 _etherAmount,
        uint256 _tokenAmount
    );

    event ClaimToken(address _token, address _user, uint256 tokenAmount);

    struct Launchpad {
        address owner;
        address token;
        address tokenHolderAddress;
        uint256 rate;
        uint256 startDate;
        uint256 whitelistDate;
        uint256 whitelistRate;
        uint256 endDate;
        Claim[] claims;
        bytes32 merkleRoot;
        uint256 tokenAmount;
        uint256 totalOrder;
        uint256 totalEtherAmount;
        uint256 maxEtherAmount;
        address ethReceiverAddress;
    }

    struct Claim {
        uint256 percent;
        uint256 date;
        uint256 index;
    }

    struct Order {
        uint256 totalEtherAmount;
        uint256 totalTokenAmount;
        uint256 tokenAmount;
        uint256 claimedTokenAmount;
        uint256[] claimedIndexes;
    }

    mapping(address => Launchpad) launchpads;

    mapping(address => bool) users;

    mapping(bytes32 => Order) orders;

    bool public isPrivate = false;

    function activateUser(address user, bool active) external onlyOwner {
        users[user] = active;
    }

    modifier onlyUser() {
        require(
            users[_msgSender()] == true || !isPrivate,
            "User: caller is not the user"
        );
        _;
    }

    modifier launchpadSetup(address _token) {
        require(
            launchpads[_token].token != address(0),
            "Launchpad: not setup yet"
        );
        _;
    }

    modifier launchpadNoBuyer(address _token) {
        require(
            launchpads[_token].tokenAmount == 0,
            "Launchpad: not setup yet"
        );
        _;
    }

    modifier launchpadOwner(address _token) {
        require(
            launchpads[_token].owner == _msgSender(),
            "User: caller is not the lp owner"
        );
        _;
    }

    function verifyWhitelist(
        address _token,
        address _user,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        return _verify(_merkleProof, launchpads[_token].merkleRoot, _user);
    }

    function _getOrderId(address _user, address _token)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_user, _token));
    }

    function getOrder(address _user, address _token)
        external
        view
        returns (Order memory)
    {
        return orders[_getOrderId(_user, _token)];
    }

    function _verify(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot,
        address _user
    ) private pure returns (bool) {
        return
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function _refundExceed(address _token, uint256 _etherAmount)
        private
        returns (uint256)
    {
        if (
            launchpads[_token].totalEtherAmount + _etherAmount >
            launchpads[_token].maxEtherAmount
        ) {
            TransferHelper.safeTransferETH(
                msg.sender,
                _etherAmount -
                    (launchpads[_token].maxEtherAmount -
                        launchpads[_token].totalEtherAmount)
            );
            _etherAmount =
                launchpads[_token].maxEtherAmount -
                launchpads[_token].totalEtherAmount;
        }
        return _etherAmount;
    }

    function _calcTokenAmount(
        uint256 _decimals,
        uint256 _rate,
        uint256 _etherAmount
    ) private pure returns (uint256) {
        uint256 amount = ((10**_decimals * _rate * _etherAmount) / 10**18)/ 10**18;
        return amount;
    }

    function buy(
        address _token,
        uint256 _etherAmount,
        bytes32[] calldata _merkleProof
    ) external payable launchpadSetup(_token) {
        require(block.timestamp <= launchpads[_token].endDate, "Closed");
        require(
            msg.value >= _etherAmount && _etherAmount > 0,
            "Not enough ether"
        );
        bool _verified = _verify(
            _merkleProof,
            launchpads[_token].merkleRoot,
            msg.sender
        );
        require(
            block.timestamp >=
                (
                    _verified
                        ? launchpads[_token].whitelistDate
                        : launchpads[_token].startDate
                ),
            "Not open yet"
        );
        _etherAmount = _refundExceed(_token, _etherAmount);
        require(_etherAmount > 0, "Out of stock");

        TransferHelper.safeTransferETH(
            launchpads[_token].ethReceiverAddress,
            _etherAmount
        );

        bytes32 _order = _getOrderId(msg.sender, _token);
        uint256 _rate = _verified && launchpads[_token].whitelistRate > 0
            ? launchpads[_token].whitelistRate
            : launchpads[_token].rate;

        uint256 _tokenAmount = _calcTokenAmount(
            IBEP20(_token).decimals(),
            _rate,
            _etherAmount
        );

        if (orders[_order].totalTokenAmount <= 0) {
            launchpads[_token].totalOrder += 1;
        }

        if (orders[_order].claimedTokenAmount > 0) {
            TransferHelper.safeTransferFrom(
                _token,
                launchpads[_token].tokenHolderAddress,
                msg.sender,
                _tokenAmount
            );
        } else {
            // transfer token to smart contract
            TransferHelper.safeTransferFrom(
                _token,
                launchpads[_token].tokenHolderAddress,
                address(this),
                _tokenAmount
            );
            orders[_order].tokenAmount += _tokenAmount;
        }

        orders[_order].totalEtherAmount += _etherAmount;
        orders[_order].totalTokenAmount += _tokenAmount;
        launchpads[_token].tokenAmount += _tokenAmount;
        launchpads[_token].totalEtherAmount += _etherAmount;

        emit BuyToken(_token, msg.sender, _etherAmount, _tokenAmount);
    }

    function claim(address _token) external launchpadSetup(_token) {
        bytes32 _order = _getOrderId(msg.sender, _token);
        require(
            orders[_order].claimedTokenAmount < orders[_order].tokenAmount,
            "No more to claim"
        );
        uint256 _amount = 0;
        if (
            launchpads[_token].claims.length == 0 &&
            launchpads[_token].endDate <= block.timestamp
        ) {
            _amount =
                orders[_order].tokenAmount -
                orders[_order].claimedTokenAmount;
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
            orders[_order].claimedTokenAmount = orders[_order].tokenAmount;
        } else {
            uint256[] memory _claims;
            uint256 _percent;
            (_claims, _percent) = _claimList(_token, msg.sender);
            require(_claims.length > 0, "Not time yet to claim");
            for (uint256 i = 0; i < _claims.length; ) {
                orders[_order].claimedIndexes.push(_claims[i]);
                unchecked {
                    i++;
                }
            }
            _amount = (_percent * orders[_order].tokenAmount) / denominator;
            if (
                _amount >
                orders[_order].tokenAmount - orders[_order].claimedTokenAmount
            ) {
                _amount =
                    orders[_order].tokenAmount -
                    orders[_order].claimedTokenAmount;
            }
            orders[_order].claimedTokenAmount += _amount;
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
        }
        emit ClaimToken(_token, msg.sender, _amount);
    }

    function _claimList(address _token, address _user)
        internal
        view
        returns (uint256[] memory _claimIndexes, uint256 _percent)
    {
        _claimIndexes = new uint256[](_claimListCount(_token, _user));
        bytes32 _order = _getOrderId(_user, _token);
        uint256 j = 0;
        for (uint256 i = 0; i < launchpads[_token].claims.length; ) {
            if (
                !_exist(
                    launchpads[_token].claims[i].index,
                    orders[_order].claimedIndexes
                ) &&
                launchpads[_token].claims[i].date <= block.timestamp &&
                launchpads[_token].claims[i].index > 0 &&
                launchpads[_token].claims[i].percent > 0
            ) {
                _claimIndexes[j] = launchpads[_token].claims[i].index;
                _percent += launchpads[_token].claims[i].percent;
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return (_claimIndexes, _percent);
    }

    function _claimListCount(address _token, address _user)
        internal
        view
        returns (uint256)
    {
        bytes32 _order = _getOrderId(_user, _token);
        uint256 j = 0;
        for (uint256 i = 0; i < launchpads[_token].claims.length; ) {
            if (
                !_exist(
                    launchpads[_token].claims[i].index,
                    orders[_order].claimedIndexes
                ) &&
                launchpads[_token].claims[i].date <= block.timestamp &&
                launchpads[_token].claims[i].index > 0 &&
                launchpads[_token].claims[i].percent > 0
            ) {
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return j;
    }

    function _exist(uint256 _id, uint256[] memory _list)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; ) {
            if (_list[i] == _id) {
                return true;
            }
            unchecked {
                i++;
            }
        }
        return false;
    }

    function getLaunchpad(address _token)
        external
        view
        returns (Launchpad memory)
    {
        return launchpads[_token];
    }

    function isUser(address _user) external view returns (bool) {
        return users[_user];
    }

    function setIsPrivate(bool _isPrivate) external {
        isPrivate = _isPrivate;
    }

    function updateMerkleRoot(address _token, bytes32 _merkleRoot)
        external
        launchpadOwner(_token)
        launchpadSetup(_token)
    {
        launchpads[_token].merkleRoot = _merkleRoot;
    }

    function updateMaxEtherAmount(address _token, uint256 _maxEtherAmount)
        external
        launchpadOwner(_token)
        launchpadSetup(_token)
    {
        if (launchpads[_token].maxEtherAmount < _maxEtherAmount) {
            require(
                IBEP20(_token).allowance(msg.sender, address(this)) >=
                    _calcTokenAmount(
                        IBEP20(_token).decimals(),
                        launchpads[_token].whitelistRate >
                            launchpads[_token].rate
                            ? launchpads[_token].whitelistRate
                            : launchpads[_token].rate,
                        _maxEtherAmount - launchpads[_token].totalEtherAmount
                    )
            );
        }
        launchpads[_token].maxEtherAmount = _maxEtherAmount;
    }

    function updateDate(
        address _token,
        uint256 _startDate,
        uint256 _whitelistDate,
        uint256 _endDate
    ) external launchpadOwner(_token) launchpadSetup(_token) {
        launchpads[_token].startDate = _startDate;
        launchpads[_token].whitelistDate = _whitelistDate;
        launchpads[_token].endDate = _endDate;
    }

    function updateEthReceiverAddress(
        address _token,
        address _ethReceiverAddress
    ) external launchpadOwner(_token) launchpadSetup(_token) {
        require(_ethReceiverAddress != address(0));
        launchpads[_token].ethReceiverAddress = _ethReceiverAddress;
    }

    function updateClaims(address _token, Claim[] calldata _claims)
        external
        launchpadOwner(_token)
        launchpadSetup(_token)
        launchpadNoBuyer(_token)
    {
        require(_isValidClaims(_claims), "Claims not valid");
        delete launchpads[_token].claims;
        for (uint256 i = 0; i < _claims.length; ) {
            launchpads[_token].claims.push(_claims[i]);
            unchecked {
                i++;
            }
        }
    }

    function updateRate(
        address _token,
        uint256 _rate,
        uint256 _whitelistRate
    ) external launchpadOwner(_token) launchpadSetup(_token) {
        launchpads[_token].whitelistRate = _whitelistRate;
        launchpads[_token].rate = _rate;
    }

    function deletePad(address _token) external onlyOwner {
        delete launchpads[_token];
    }

    function setup(
        address _token,
        address _tokenHolderAddress,
        uint256 _rate,
        uint256 _startDate,
        uint256 _whitelistRate,
        uint256 _whitelistDate,
        uint256 _endDate,
        Claim[] calldata _claims,
        bytes32 _merkleRoot,
        uint256 _maxEtherAmount,
        address _ethReceiverAddress
    ) external onlyUser {
        require(
            launchpads[_token].token == address(0),
            "Launchpad has been added"
        );
        require(_isValidClaims(_claims), "Claims not valid");
        require(
            IBEP20(_token).allowance(_tokenHolderAddress, address(this)) >=
                _calcTokenAmount(
                    IBEP20(_token).decimals(),
                    _whitelistRate > _rate ? _whitelistRate : _rate,
                    _maxEtherAmount
                ),
            "Not enough token"
        );
        launchpads[_token].token = _token;
        launchpads[_token].owner = msg.sender;
        launchpads[_token].tokenHolderAddress = _tokenHolderAddress;
        launchpads[_token].rate = _rate;
        launchpads[_token].startDate = _startDate;
        launchpads[_token].whitelistDate = _whitelistDate;
        launchpads[_token].whitelistRate = _whitelistRate;
        launchpads[_token].endDate = _endDate;
        for (uint256 i = 0; i < _claims.length; ) {
            launchpads[_token].claims.push(_claims[i]);
            unchecked {
                i++;
            }
        }
        launchpads[_token].merkleRoot = _merkleRoot;
        launchpads[_token].maxEtherAmount = _maxEtherAmount;
        launchpads[_token].ethReceiverAddress = _ethReceiverAddress ==
            address(0)
            ? msg.sender
            : _ethReceiverAddress;
    }

    function _isValidClaims(Claim[] calldata _claims)
        internal
        view
        returns (bool)
    {
        if (_claims.length <= 0) {
            return true;
        }
        if (_claims.length > 3) {
            return false;
        }
        uint256 _temp;
        uint256 _percent;
        for (uint256 i = 0; i < _claims.length; i++) {
            _temp = _claims[i].index;
            if (_temp <= 0) {
                return false;
            }
            for (uint256 j = 0; j < _claims.length; j++) {
                if ((j != i) && (_temp == _claims[j].index)) {
                    return false;
                }
            }
            _percent += _claims[i].percent;
        }
        if (_percent != denominator) {
            return false;
        }

        return true;
    }
}