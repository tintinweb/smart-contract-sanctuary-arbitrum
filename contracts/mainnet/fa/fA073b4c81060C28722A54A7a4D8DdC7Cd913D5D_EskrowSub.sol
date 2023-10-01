/**
 *Submitted for verification at Arbiscan.io on 2023-10-01
*/

// SPDX-License-Identifier: GD
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

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin\contracts\utils\Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts\Helpers\RandomizerUnsafe.sol

pragma solidity ^0.8.19;

// Reasonable randomizer routines. It can (still) be predicted/attacked by miners
//  although the likelyhood is low (implemented difficulty + nounce). Do not use
//  for lottery-type of function. Generally, reasonable.
abstract contract RandomizerUnsafe {
    using Counters for Counters.Counter;

    // ==============================
    // STATE VARIABLES
    //
    Counters.Counter private _nonce;

    // ==============================
    // FUNCTIONS

    // Initializations
    constructor() {}

    //
    function random(uint _min, uint _max) internal returns (uint) {
        return random(_min, _max, msg.sender, 0, 0);
    }

    //
    function random(
        uint _min,
        uint _max,
        address _msgSender,
        uint256 _seedParam1
    ) internal returns (uint) {
        return random(_min, _max, _msgSender, _seedParam1, 0);
    }

    // Underlying implementation
    function random(
        uint _min,
        uint _max,
        address _msgSender,
        uint256 _seedParam1,
        uint256 _seedParam2
    ) public returns (uint) {
        _nonce.increment();
        return
            (uint256(
                keccak256(
                    abi.encode(
                        _msgSender,
                        _seedParam1,
                        _seedParam2,
                        block.prevrandao,
                        _nonce.current()
                    )
                )
            ) % _max) + _min;
    }

    // Underlying implementation
    function randomBytes32(
        address _msgSender,
        address _seedParam1,
        address _seedParam2
    ) public returns (bytes32) {
        _nonce.increment();
        return
            keccak256(
                abi.encode(
                    _msgSender,
                    _seedParam1,
                    _seedParam2,
                    block.prevrandao,
                    _nonce.current()
                )
            );
    }
}

// File: contracts\EskrowHelpers\EskrowStructs.sol

pragma solidity ^0.8.19;

abstract contract EskrowStructs {
    struct Escrow {
        bytes32 escrowId;
        address payable party1;
        address payable party2;
        address token1;
        address token2;
        uint256 token1RequiredQty;
        uint256 token1DepositedQty;
        uint256 token2RequiredQty;
        uint256 token2DepositedQty;
        uint expiryEpoch;
        uint settleFromEpoch;
        uint16 feeInPpt;
        bool isParty1LockRefund;
        bool isParty2LockRefund;
        bool hasParty1Withdrawn;
        bool hasParty2Withdrawn;
        string description;
    }

    struct EscrowExt {
        // struct Escrow
        bytes32 escrowId;
        address payable party1;
        address payable party2;
        address token1;
        address token2;
        uint256 token1RequiredQty;
        uint256 token1DepositedQty;
        uint256 token2RequiredQty;
        uint256 token2DepositedQty;
        uint expiryEpoch;
        uint settleFromEpoch;
        uint16 feeInPpt;
        bool isParty1LockRefund;
        bool isParty2LockRefund;
        bool hasParty1Withdrawn;
        bool hasParty2Withdrawn;
        string description;
        // -----
        // Extension
        uint256 token1FeeInQty;
        uint256 token2FeeInQty;
        bool isReadyToSettle;
        bool isExpired;
        bool isFullyWithdrawn;
    }
}

// File: contracts\EskrowHelpers\EscrowHelper.sol

pragma solidity ^0.8.19;

abstract contract EskrowHelper {
    function toEscrowExt(
        EskrowStructs.Escrow memory _escrow,
        uint256 _blockTime
    ) public pure returns (EskrowStructs.EscrowExt memory) {
        return
            EskrowStructs.EscrowExt({
                escrowId: _escrow.escrowId,
                party1: _escrow.party1,
                party2: _escrow.party2,
                token1: _escrow.token1,
                token2: _escrow.token2,
                token1RequiredQty: _escrow.token1RequiredQty,
                token1DepositedQty: _escrow.token1DepositedQty,
                token2RequiredQty: _escrow.token2RequiredQty,
                token2DepositedQty: _escrow.token2DepositedQty,
                feeInPpt: _escrow.feeInPpt,
                hasParty1Withdrawn: _escrow.hasParty1Withdrawn,
                hasParty2Withdrawn: _escrow.hasParty2Withdrawn,
                expiryEpoch: _escrow.expiryEpoch,
                settleFromEpoch: _escrow.settleFromEpoch,
                isParty1LockRefund: _escrow.isParty1LockRefund,
                isParty2LockRefund: _escrow.isParty2LockRefund,
                description: _escrow.description,
                token1FeeInQty: _calcFee(
                    _escrow.token1DepositedQty,
                    _escrow.feeInPpt
                ),
                token2FeeInQty: _calcFee(
                    _escrow.token2DepositedQty,
                    _escrow.feeInPpt
                ),
                isReadyToSettle: _isReadyToSettle(_escrow, _blockTime),
                isExpired: _isExpired(_escrow, _blockTime),
                isFullyWithdrawn: _isFullyWithdrawn(_escrow)
            });
    }

    // ====================

    // Fees calculations
    // 1 ppt == (1/1000 of 1%) == 0.001% == 0.00001 multiplier == 100,000 divisor.
    // 1% == 1000 in ppt. 0.01% == 0.01/1000 == 0.00001
    function _calcFee(
        uint256 _qty,
        uint16 _feeInPpt
    ) internal pure returns (uint256) {
        return ((_qty * _feeInPpt) / 100000);
    }

    // ====================
    function _isExpired(
        EskrowStructs.Escrow memory _escrow,
        uint _blockTime
    ) internal pure returns (bool) {
        return (_blockTime > _escrow.expiryEpoch);
    }

    function _isFullyWithdrawn(
        EskrowStructs.Escrow memory _escrow
    ) internal pure returns (bool) {
        return (_escrow.hasParty1Withdrawn && _escrow.hasParty2Withdrawn);
    }

    function _isPartiallyWithdrawn(
        EskrowStructs.Escrow memory _escrow
    ) internal pure returns (bool) {
        return
            (_escrow.hasParty1Withdrawn && !_escrow.hasParty2Withdrawn) ||
            (_escrow.hasParty2Withdrawn && !_escrow.hasParty1Withdrawn);
    }

    function _isFullyDeposited(
        EskrowStructs.Escrow memory _escrow
    ) internal pure returns (bool) {
        return
            (_escrow.token1DepositedQty >= _escrow.token1RequiredQty) &&
            (_escrow.token2DepositedQty >= _escrow.token2RequiredQty);
    }

    function _isPartiallyDeposited(
        EskrowStructs.Escrow memory _escrow
    ) internal pure returns (bool) {
        return
            !_isFullyDeposited(_escrow) &&
            (((_escrow.token1DepositedQty > 0) &&
                (_escrow.token1DepositedQty <= _escrow.token1RequiredQty)) ||
                ((_escrow.token2DepositedQty > 0) &&
                    (_escrow.token2DepositedQty <= _escrow.token2RequiredQty)));
    }

    function _isReadyToSettle(
        EskrowStructs.Escrow memory _escrow,
        uint _blockTime
    ) internal pure returns (bool) {
        return
            _isFullyDeposited(_escrow) &&
            (_blockTime >= _escrow.settleFromEpoch);
    }
}

// File: contracts\EskrowHelpers\EskrowEvents.sol

pragma solidity ^0.8.19;

abstract contract EskrowEvents {
    // ==============================
    // // EVENTS
    // event Checkpoint( string message );
    // event Checkpoint( uint256 value );
    // event Checkpoint( address value );

    event EscrowCreated(
        bytes32 indexed _escrowId,
        address indexed _party1,
        address indexed _party2
    );
    event EscrowRemoved(bytes32 indexed _escrowId, address _party);
    event EscrowFunded(
        bytes32 indexed _escrowId,
        address indexed _party,
        address indexed _token,
        uint256 _qty
    );
    event EscrowRefunded(
        bytes32 indexed _escrowId,
        address indexed _party,
        address indexed _token,
        uint256 _quantity
    );
    event EscrowSettled(
        bytes32 indexed _escrowId,
        address indexed _party,
        address _token,
        uint256 _quantity
    );

    event EscrowIsFullyFunded(
        bytes32 indexed _escrowId,
        address indexed _party1,
        address indexed _party2
    );

    event EscrowError(
        address indexed _origin,
        bytes32 indexed _escrowId,
        string indexed _method,
        uint32 _code
    );
}

// File: contracts\EskrowSub.sol

pragma solidity ^0.8.19;

contract EskrowSub is Ownable, EskrowEvents, EskrowHelper, RandomizerUnsafe {
    // ==============================
    // STATE VARIABLES
    //
    address payable internal eskrowMain;
    address public configErc20WithdrawalAddress;

    // ==============================
    // FUNCTIONS

    // Initializations
    constructor() {
        string memory contractName;
        contractName = "EskrowSub v1.5.3";

        eskrowMain = payable(address(0x0));
    }

    // Triggered when ETHER is sent to contract.
    // Note: Users should NEVER send ETHER (or ANY token) to contract.
    receive() external payable virtual {}

    // ==============================
    // ADMIN FUNCTIONS

    function setEskroMain(address payable _implementation) external onlyOwner {
        if (_implementation != address(0)) {
            eskrowMain = _implementation;
        }
    }

    function setConfigErc20WithdrawalAddress(
        address _wallet
    ) external onlyOwner {
        configErc20WithdrawalAddress = _wallet;
    }

    // Note: Users should NEVER send tokens to contract.
    // In case someone did, this allow admin to withdraw them.
    function adminWithdrawErc20Tokens(
        address _token
    ) external virtual onlyOwner returns (uint256 _qty) {
        require(
            configErc20WithdrawalAddress != address(0),
            "===> Invalid Withdrawal Address"
        );

        _qty = IERC20(_token).balanceOf(address(this));
        if (IERC20(_token).transfer(configErc20WithdrawalAddress, _qty)) {
            return _qty;
        }
        return 0;
    }

    // Do NOT send Ether to contract. Just in case, this allow admin to withdraw.
    function adminWithdrawEther(uint256 _gwei) external virtual onlyOwner {
        require(
            configErc20WithdrawalAddress != address(0),
            "===> Invalid Withdrawal Address"
        );
        payable(configErc20WithdrawalAddress).transfer(_gwei);
    }

    // ---------------
    // Generate a unique (through nonce) bytes32 escrowId.
    function generateEscrowId(
        address _party1,
        address _party2,
        address _msgSender
    ) private returns (bytes32 escrowId) {
        return randomBytes32(_msgSender, _party1, _party2);
    }

    //
    function _breakOnUnknownCaller() private view {
        require(_msgSender() == eskrowMain, "===> UNREGISTERED CALLER.");
    }

    // ==============================
    // ==============================
    // Function Group: Create Escrow
    function create(
        EskrowStructs.Escrow memory _escrow,
        address _msgSender
    ) external virtual returns (EskrowStructs.Escrow memory) {
        _breakOnUnknownCaller();

        // Perform class specific validations
        _escrow.escrowId = 0;
        uint32 code = _validateCreate(_msgSender, _escrow);

        if (code == 0) {
            _escrow.escrowId = generateEscrowId(
                _msgSender,
                _escrow.party1,
                _escrow.party2
            );
        }

        return _escrow;
    }

    // ==============================
    // Validate if a escrow if valid for creation
    // Parties cannot be 0x0 even for isAnyoneCanDeposit
    function _validateCreate(
        address _msgSender,
        EskrowStructs.Escrow memory _escrow
    ) internal virtual returns (uint32 code) {
        // Party and token addresses cannot be zero.
        if (
            (_escrow.party1 == address(0x0)) ||
            (_escrow.party2 == address(0x0)) ||
            (_escrow.token1 == address(0x0)) ||
            (_escrow.token2 == address(0x0))
        ) {
            emit EscrowError(_msgSender, 0x0, "create", 100020);
            return 100020;
        }

        // Party addresses cannot be same.
        if ((_escrow.party1 == _escrow.party2)) {
            emit EscrowError(_msgSender, 0x0, "create", 100030);
            return 100030;
        }

        // Required quantity, cannot be both zero.
        if ((_escrow.token1RequiredQty + _escrow.token2RequiredQty) == 0) {
            emit EscrowError(_msgSender, 0x0, "create", 100040);
            return 100040;
        }

        // Expiry must be in the future.
        if (_escrow.expiryEpoch <= block.timestamp) {
            emit EscrowError(_msgSender, 0x0, "create", 100050);
            return 100050;
        }

        // Earliest withdrawal must be on/or before expiry.
        if (_escrow.settleFromEpoch > _escrow.expiryEpoch) {
            emit EscrowError(_msgSender, 0x0, "create", 100060);
            return 100060;
        }
        return 0;
    }

    // ==============================

    // ==============================
    // Validates if escrow can be removed
    function validateRemove(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrow
    ) external virtual returns (uint32 code) {
        _breakOnUnknownCaller();

        EskrowStructs.EscrowExt memory _sid = toEscrowExt(
            _escrow,
            block.timestamp
        );

        if ((_msgInitiator != _sid.party1) && (_msgInitiator != _sid.party2)) {
            //Only parties can remove a escrow.
            emit EscrowError(_msgInitiator, _escrow.escrowId, "remove", 101020);
            return 101020;
        }

        // Partially deposited onwards need validation.
        // (New contract and zero deposit contracts can be deleted, no problem.)
        if ((_sid.token1DepositedQty + _sid.token2DepositedQty) != 0) {
            if (!(_sid.isFullyWithdrawn || _sid.isExpired)) {
                // Only expired or fully withdrawn escrow can be removed.
                emit EscrowError(
                    _msgInitiator,
                    _escrow.escrowId,
                    "remove",
                    101030
                );
                return 101030;
            }
        }
        return 0;
    }

    // ==============================

    // ==============================
    function validateDeposit(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrow,
        address _token,
        uint256 _quantity
    )
        external
        virtual
        returns (
            uint32 code,
            uint256 token1Qty,
            uint256 token2Qty,
            bool isFullyDeposited
        )
    {
        _breakOnUnknownCaller();

        // -----
        // Cannot be expired
        if (_isExpired(_escrow, block.timestamp)) {
            emit EscrowError(
                _msgInitiator,
                _escrow.escrowId,
                "deposit",
                102020
            );
            return (102020, 0, 0, false);
        }

        // Check that party/token combo is valid.
        if (
            !(((_msgInitiator == _escrow.party1) &&
                (_token == _escrow.token1)) ||
                ((_msgInitiator == _escrow.party2) &&
                    (_token == _escrow.token2)))
        ) {
            emit EscrowError(
                _msgInitiator,
                _escrow.escrowId,
                "deposit",
                102030
            );
            return (102030, 0, 0, false);
        }

        // Disallow over-deposit
        if (
            ((_msgInitiator == _escrow.party1) &&
                ((_escrow.token1DepositedQty + _quantity) >
                    _escrow.token1RequiredQty)) ||
            ((_msgInitiator == _escrow.party2) &&
                ((_escrow.token2DepositedQty + _quantity) >
                    _escrow.token2RequiredQty))
        ) {
            emit EscrowError(
                _msgInitiator,
                _escrow.escrowId,
                "deposit",
                102040
            );
            return (102040, 0, 0, false);
        }
        // -----

        // Increase the deposit counter
        if (_msgInitiator == _escrow.party1) {
            _escrow.token1DepositedQty += _quantity;
        }

        if (_msgInitiator == _escrow.party2) {
            _escrow.token2DepositedQty += _quantity;
        }

        return (
            0,
            _escrow.token1DepositedQty,
            _escrow.token2DepositedQty,
            _isFullyDeposited(_escrow)
        );
    }

    // ==============================

    // ==============================
    function validateRefund(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrow,
        bool _isByForce
    )
        external
        virtual
        returns (uint32 code, address token, address bene, uint256 qty)
    {
        _breakOnUnknownCaller();

        // State of a Eskrow contract:
        // Created --> Partially Deposited --> Fully Deposited --> Partially Withdrawn --> Fully Withdrawn --> Expired

        EskrowStructs.EscrowExt memory sid = toEscrowExt(
            _escrow,
            block.timestamp
        );
        if (!_isByForce) {
            if (
                (_msgInitiator != sid.party1) && (_msgInitiator != sid.party2)
            ) {
                emit EscrowError(
                    _msgInitiator,
                    _escrow.escrowId,
                    "refund",
                    103020
                );
                return (103020, address(0), address(0), 0);
            }

            if (
                ((_msgInitiator == _escrow.party1) &&
                    _escrow.isParty1LockRefund) ||
                ((_msgInitiator == _escrow.party2) &&
                    _escrow.isParty2LockRefund)
            ) {
                emit EscrowError(
                    _msgInitiator,
                    _escrow.escrowId,
                    "refund",
                    103030
                );
                return (103030, address(0), address(0), 0);
            }

            // Can still refund if isFullyDeposited if before SettleFrom.
            if (sid.isReadyToSettle) {
                emit EscrowError(
                    _msgInitiator,
                    _escrow.escrowId,
                    "refund",
                    103040
                );
                return (103040, address(0), address(0), 0);
            }
        }

        if (_msgInitiator == _escrow.party1) {
            bene = _escrow.party1;
            token = _escrow.token1;
            qty =
                _escrow.token1DepositedQty -
                _calcFee(_escrow.token1DepositedQty, _escrow.feeInPpt);
            _escrow.token1DepositedQty = 0;
        }
        if (_msgInitiator == _escrow.party2) {
            bene = _escrow.party2;
            token = _escrow.token2;
            qty =
                _escrow.token2DepositedQty -
                _calcFee(_escrow.token2DepositedQty, _escrow.feeInPpt);
            _escrow.token2DepositedQty = 0;
        }

        return (0, token, bene, qty);
    }

    // ==============================

    // ==============================
    function validateSettle(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrow
    )
        external
        virtual
        returns (uint32 code, address token, address bene, uint256 qty)
    {
        _breakOnUnknownCaller();

        // State of a Escrow contract:
        // Created --> Partially Deposited --> Fully Deposited --> Partially Withdrawn --> Fully Withdrawn --> Expired

        if (
            (_msgInitiator != _escrow.party1) &&
            (_msgInitiator != _escrow.party2)
        ) {
            emit EscrowError(_msgInitiator, _escrow.escrowId, "settle", 104020);
            return (104020, address(0), address(0), 0);
        }

        if (!_isReadyToSettle(_escrow, block.timestamp)) {
            emit EscrowError(_msgInitiator, _escrow.escrowId, "settle", 104030);
            return (104030, address(0), address(0), 0);
        }

        if (_msgInitiator == _escrow.party1) {
            bene = _escrow.party1;
            token = _escrow.token2;
            qty =
                _escrow.token2DepositedQty -
                _calcFee(_escrow.token2DepositedQty, _escrow.feeInPpt);
        }
        if (_msgInitiator == _escrow.party2) {
            bene = _escrow.party2;
            token = _escrow.token1;
            qty =
                _escrow.token1DepositedQty -
                _calcFee(_escrow.token1DepositedQty, _escrow.feeInPpt);
        }

        return (0, token, bene, qty);
    }
}