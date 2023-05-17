/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

contract VerifySignature {
    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _to,
        uint256 _lvl,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _lvl, _nonce));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _to,
        uint256 _lvl,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _lvl, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

contract PelandAirdrop is Context, Ownable, VerifySignature {
    uint256 public constant denominator = 10_000;

    constructor() {
        address _token = 0x5FfA031b9b6e165ca53282CbE6bdAd0f15EEcC2C;

        launchpads[_token].claims.push(
            Claim({
                percent: 10_000,
                date: block.timestamp + 5 * 24 * 60 * 60,
                index: 1
            })
        );

        launchpads[_token].whitelistRates.push(
            WhitelistRate({min: 1, max: 15, rate: 144_000_000 ether})
        );

        launchpads[_token].whitelistRates.push(
            WhitelistRate({min: 16, max: 50, rate: 117_000_000 ether})
        );

        launchpads[_token].whitelistRates.push(
            WhitelistRate({min: 51, max: 99999, rate: 90_000_000 ether})
        );

        launchpads[_token].token = _token; //token address
        launchpads[_token].owner = msg.sender; //owner, signer address
        launchpads[_token]
            .tokenHolderAddress = 0xe5F1288f690E32459cFa4703186FFa3db59aa918; //token holder address
        launchpads[_token]
            .ethReceiverAddress = 0x6aA421113eCa2EBBc9B260f391C65a32ae4B4195; //ether receiver
        launchpads[_token].rate = 180_000_000 ether;
        launchpads[_token].startDate = block.timestamp + 0 * 24 * 60 * 60; //0 day from now
        launchpads[_token].whitelistDate = block.timestamp + 0 * 24 * 60 * 60; //0 day from now
        launchpads[_token].endDate = block.timestamp + 3 * 24 * 60 * 60; //10s day from now
        launchpads[_token].maxEtherAmount = 150 ether; //after 150 ether, buyer cannot buy any token.
        launchpads[_token].refRate = 1000; // 1%
        require(_isValidClaims(launchpads[_token].claims));
    }

    struct Launchpad {
        address owner;
        address token;
        address tokenHolderAddress;
        uint256 rate;
        uint256 startDate;
        uint256 whitelistDate;
        WhitelistRate[] whitelistRates;
        uint256 endDate;
        Claim[] claims;
        uint256 maxEtherAmount;
        uint256 totalTokenAmount;
        uint256 totalOrder;
        uint256 totalEtherAmount;
        address ethReceiverAddress;
        uint256 refRate;
        uint256 minEthBought;
        uint256 maxEthBought;
    }

    struct Claim {
        uint256 percent;
        uint256 date;
        uint256 index;
    }

    struct Ref {
        uint256 reward;
        uint256 count;
    }

    struct WhitelistRate {
        uint256 min;
        uint256 max;
        uint256 rate;
    }

    struct Order {
        uint256 totalEtherAmount;
        uint256 totalTokenAmount;
        uint256 tokenAmount;
        uint256 claimedTokenAmount;
        uint256[] claimedIndexes;
    }

    mapping(address => Launchpad) launchpads;

    mapping(bytes32 => Order) orders;

    mapping(bytes32 => Ref) refs;

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
        uint256 amount = ((10**_decimals * _rate * _etherAmount) / 10**18) /
            10**18;
        return amount;
    }

    function _getRate(WhitelistRate[] memory _rates, uint256 _lvl)
        private
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < _rates.length; ) {
            if (_lvl >= _rates[i].min && _lvl <= _rates[i].max) {
                return _rates[i].rate;
            }
            unchecked {
                i++;
            }
        }
        return 0;
    }

    function buy(
        address _token,
        uint256 _etherAmount,
        uint256 _lvl,
        uint256 _nonce,
        bytes memory _signature,
        address ref
    ) external payable {
        require(block.timestamp <= launchpads[_token].endDate, "Closed");
        require(
            msg.value >= _etherAmount && _etherAmount > 0,
            "Not enough ether"
        );
        uint256 _rate = launchpads[_token].rate;
        if (
            verify(
                launchpads[_token].owner,
                msg.sender,
                _lvl,
                _nonce,
                _signature
            ) && _getRate(launchpads[_token].whitelistRates, _lvl) > 0
        ) {
            _rate = _getRate(launchpads[_token].whitelistRates, _lvl);
        }

        _etherAmount = _refundExceed(_token, _etherAmount);
        require(_etherAmount > 0, "Out of stock");
        if (ref != address(0)) {
            TransferHelper.safeTransferETH(
                launchpads[_token].ethReceiverAddress,
                _etherAmount -
                    (launchpads[_token].refRate * _etherAmount) /
                    denominator
            );
            TransferHelper.safeTransferETH(
                ref,
                (launchpads[_token].refRate * _etherAmount) / denominator
            );
            refs[_getOrderId(ref, _token)].count++;
            refs[_getOrderId(ref, _token)].reward +=
                (launchpads[_token].refRate * _etherAmount) /
                denominator;
        } else {
            TransferHelper.safeTransferETH(
                launchpads[_token].ethReceiverAddress,
                _etherAmount
            );
        }

        bytes32 _order = _getOrderId(msg.sender, _token);

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
        launchpads[_token].totalTokenAmount += _tokenAmount;
        launchpads[_token].totalEtherAmount += _etherAmount;
        if (
            launchpads[_token].minEthBought > _etherAmount ||
            launchpads[_token].minEthBought == 0
        ) {
            launchpads[_token].minEthBought = _etherAmount;
        }
        if (launchpads[_token].maxEthBought < _etherAmount) {
            launchpads[_token].maxEthBought = _etherAmount;
        }
    }

    function claim(address _token) external {
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

    function getRef(address _ref, address _token)
        external
        view
        returns (Ref memory)
    {
        return refs[_getOrderId(_ref, _token)];
    }

    function updateMaxEtherAmount(address _token, uint256 _maxEtherAmount)
        external
        onlyOwner
    {
        launchpads[_token].maxEtherAmount = _maxEtherAmount;
    }

    function updateDate(
        address _token,
        uint256 _startDate,
        uint256 _whitelistDate,
        uint256 _endDate
    ) external onlyOwner {
        launchpads[_token].startDate = _startDate;
        launchpads[_token].whitelistDate = _whitelistDate;
        launchpads[_token].endDate = _endDate;
    }

    function updateEthReceiverAddress(
        address _token,
        address _ethReceiverAddress
    ) external onlyOwner {
        require(_ethReceiverAddress != address(0));
        launchpads[_token].ethReceiverAddress = _ethReceiverAddress;
    }

    function updateClaims(address _token, Claim[] calldata _claims)
        external
        onlyOwner
    {
        require(_isValidClaims(_claims), "Claims not valid");
        require(_claimListCount(_token, address(0)) <= 0, "Claiming");
        delete launchpads[_token].claims;
        for (uint256 i = 0; i < _claims.length; ) {
            launchpads[_token].claims.push(_claims[i]);
            unchecked {
                i++;
            }
        }
    }

    function updateRate(address _token, uint256 _rate) external onlyOwner {
        launchpads[_token].rate = _rate;
    }

    function updateRefRate(address _token, uint256 _refRate)
        external
        onlyOwner
    {
        launchpads[_token].refRate = _refRate;
    }

    function updateWhitelistRates(
        address _token,
        WhitelistRate[] calldata _whitelistRates
    ) external onlyOwner {
        delete launchpads[_token].whitelistRates;
        for (uint256 i = 0; i < _whitelistRates.length; ) {
            launchpads[_token].whitelistRates.push(_whitelistRates[i]);
            unchecked {
                i++;
            }
        }
    }

    function _isValidClaims(Claim[] memory _claims)
        internal
        pure
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