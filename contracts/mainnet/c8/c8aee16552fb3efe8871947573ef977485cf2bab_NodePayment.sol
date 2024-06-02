/**
 *Submitted for verification at Arbiscan.io on 2024-06-02
*/

// File: IReferral.sol


pragma solidity ^0.8.24;
 
interface IReferral {
    function useReferralCode(
        string calldata _referralCode
    ) external returns (address);

    function percentRebate() external returns (uint8);

    function getReferralCodeDetails(
        string calldata _referralCode
    ) external view returns (string memory, address, uint256, uint8, uint8);
}


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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

// File: NodePayment.sol


pragma solidity ^0.8.24;




contract NodePayment is Ownable {
    IERC20 public TOKENPAYMENT;
    IReferral public REFERRAL;

    constructor(
        address _owner,
        address _referral,
        address _TOKENPAYMENT
    ) Ownable(_owner) {
        REFERRAL = IReferral(_referral);
        TOKENPAYMENT = IERC20(_TOKENPAYMENT);
    }

    // node id -> NodeDetails
    mapping(uint256 => NodeDetails) public nodeSale;
    uint256 public currentNodeID;

    // node id -> owner node id -> address
    mapping(uint256 => mapping(uint256 => address)) public ownerNode;
    // node id -> currentOwnerNodeID
    mapping(uint256 => uint256) public currentOwnerNodeID;

    struct NodeDetails {
        bool exist;
        bool open;
        uint256 id;
        string name;
        uint256 slotAvailable;
        uint256 price; // pricePerMonth
        bool isPerMonth; // if not price = permanent
        uint8 per3MonthDiscount;
        uint8 per6MonthDiscount;
        uint8 per9MonthDiscount;
        uint8 per12MonthDiscount;
    }

    event BuySubscription(
        address indexed user,
        uint256 indexed nodeID,
        uint256 ownerNodeID,
        uint256 month,
        uint256 totalPrice,
        string referralCode,
        uint256 date
    );

    event BuyNode(
        address indexed user,
        uint256 indexed nodeID,
        uint256 ownerNodeID,
        uint256 month,
        uint256 totalPrice,
        string referralCode,
        uint256 date
    );

    modifier existNodeID(uint256 _nodeID) {
        require(nodeSale[_nodeID].exist, 'This nodeID does not exist');
        _;
    }

    modifier isOpen(uint256 _nodeID) {
        require(nodeSale[_nodeID].open, 'node sale close');
        _;
    }

    modifier slotAvailable(uint256 _nodeID) {
        require(nodeSale[_nodeID].slotAvailable > 0, 'node sold out');
        _;
    }

    modifier isPerMonth(uint256 _nodeID) {
        require(nodeSale[_nodeID].isPerMonth, 'node not per month');
        _;
    }

    modifier isOwnerNode(uint256 _nodeID, uint256 _ownerNodeID) {
        require(
            ownerNode[_nodeID][_ownerNodeID] == msg.sender,
            'sender not owner this node'
        );
        _;
    }

    function buySubscription(
        uint256 _nodeID,
        uint256 _month,
        uint256 _currentOwnerNodeID,
        string calldata _referralCode
    )
        public
        existNodeID(_nodeID)
        isOwnerNode(_nodeID, _currentOwnerNodeID)
        isOpen(_nodeID)
        isPerMonth(_nodeID)
    {
        uint256 totalPrice;
        NodeDetails storage node = nodeSale[_nodeID];
        totalPrice = calculationDiscountPerMonth(
            _nodeID,
            node.price * _month,
            _month
        );

        if (bytes(_referralCode).length > 0) {
            address ownerReferral = REFERRAL.useReferralCode(_referralCode);
            (, , , uint8 percentDiscount, uint8 percentRebate) = REFERRAL
                .getReferralCodeDetails(_referralCode);
            if (percentDiscount > 0) {
                totalPrice = (totalPrice * (100 - percentDiscount)) / 100;
            }
            uint256 referralRecive = (totalPrice * percentRebate) / 100;
            uint256 dappRecive = totalPrice - referralRecive;

            TOKENPAYMENT.transferFrom(
                msg.sender,
                ownerReferral,
                referralRecive
            );
            TOKENPAYMENT.transferFrom(msg.sender, owner(), dappRecive);
        } else {
            TOKENPAYMENT.transferFrom(msg.sender, owner(), totalPrice);
        }

        emit BuySubscription(
            msg.sender,
            _nodeID,
            _currentOwnerNodeID,
            _month,
            totalPrice,
            _referralCode,
            block.timestamp
        );
    }

    function buyNode(
        uint256 _nodeID,
        uint256 _month,
        string calldata _referralCode
    ) public existNodeID(_nodeID) isOpen(_nodeID) slotAvailable(_nodeID) {
        uint256 totalPrice;
        NodeDetails storage node = nodeSale[_nodeID];
        if (node.isPerMonth) {
            totalPrice = calculationDiscountPerMonth(
                _nodeID,
                node.price * _month,
                _month
            );
        } else {
            totalPrice = calculationDiscountPerMonth(
                _nodeID,
                node.price,
                _month
            );
        }

        if (bytes(_referralCode).length > 0) {
            address ownerReferral = REFERRAL.useReferralCode(_referralCode);
            (, , , uint8 percentDiscount, uint8 percentRebate) = REFERRAL
                .getReferralCodeDetails(_referralCode);
            if (percentDiscount > 0) {
                totalPrice = (totalPrice * (100 - percentDiscount)) / 100;
            }
            uint256 referralRecive = (totalPrice * percentRebate) / 100;
            uint256 dappRecive = totalPrice - referralRecive;

            TOKENPAYMENT.transferFrom(
                msg.sender,
                ownerReferral,
                referralRecive
            );
            TOKENPAYMENT.transferFrom(msg.sender, owner(), dappRecive);
        } else {
            TOKENPAYMENT.transferFrom(msg.sender, owner(), totalPrice);
        }

        node.slotAvailable--;
        ownerNode[_nodeID][currentOwnerNodeID[_nodeID]] = msg.sender;

        emit BuyNode(
            msg.sender,
            _nodeID,
            currentOwnerNodeID[_nodeID],
            _month,
            totalPrice,
            _referralCode,
            block.timestamp
        );

        currentOwnerNodeID[_nodeID]++;
    }

    function calculationDiscountPerMonth(
        uint256 _nodeID,
        uint256 totalPrice,
        uint256 _month
    ) public view returns (uint256) {
        if (_month >= 0 && _month < 3) {
            return totalPrice;
        }
        if (_month >= 3 && _month < 6) {
            return
                (totalPrice * (100 - nodeSale[_nodeID].per3MonthDiscount)) /
                100;
        }
        if (_month >= 6 && _month < 9) {
            return
                (totalPrice * (100 - nodeSale[_nodeID].per6MonthDiscount)) /
                100;
        }
        if (_month >= 9 && _month < 12) {
            return
                (totalPrice * (100 - nodeSale[_nodeID].per9MonthDiscount)) /
                100;
        }
        return
            (totalPrice * (100 - nodeSale[_nodeID].per12MonthDiscount)) / 100;
    }

    function createNewNodeSale(
        string calldata name,
        uint256 _price,
        bool _isPerMonth
    ) public onlyOwner {
        nodeSale[currentNodeID] = NodeDetails(
            true,
            false,
            currentNodeID,
            name,
            0,
            _price,
            _isPerMonth,
            0,
            0,
            0,
            0
        );
        currentNodeID++;
    }

    function updateOpen(uint256 _nodeID, bool _open) public onlyOwner {
        nodeSale[_nodeID].open = _open;
    }

    function updateName(
        uint256 _nodeID,
        string calldata _name
    ) public onlyOwner {
        nodeSale[_nodeID].name = _name;
    }

    function updateSlotAvailable(
        uint256 _nodeID,
        uint256 _slotAvailable
    ) public onlyOwner {
        nodeSale[_nodeID].slotAvailable = _slotAvailable;
    }

    function updatePrice(uint256 _nodeID, uint256 _price) public onlyOwner {
        nodeSale[_nodeID].price = _price;
    }

    function updateIsPerMonth(
        uint256 _nodeID,
        bool _isPerMonth
    ) public onlyOwner {
        nodeSale[_nodeID].isPerMonth = _isPerMonth;
    }

    function updatePerMonthDiscount(
        uint256 _nodeID,
        uint8 _per3MonthDiscount,
        uint8 _per6MonthDiscount,
        uint8 _per9MonthDiscount,
        uint8 _per12MonthDiscount
    ) public onlyOwner {
        require(_per3MonthDiscount <= 100);
        require(_per6MonthDiscount <= 100);
        require(_per9MonthDiscount <= 100);
        require(_per12MonthDiscount <= 100);
        nodeSale[_nodeID].per3MonthDiscount = _per3MonthDiscount;
        nodeSale[_nodeID].per6MonthDiscount = _per6MonthDiscount;
        nodeSale[_nodeID].per9MonthDiscount = _per9MonthDiscount;
        nodeSale[_nodeID].per12MonthDiscount = _per12MonthDiscount;
    }

    function setTOKENPAYMENT(address _TOKENPAYMENT) public onlyOwner {
        TOKENPAYMENT = IERC20(_TOKENPAYMENT);
    }
}