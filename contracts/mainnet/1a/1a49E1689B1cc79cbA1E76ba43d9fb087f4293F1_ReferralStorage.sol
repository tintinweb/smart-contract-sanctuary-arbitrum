// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../access/interfaces/IAdmin.sol";

interface ITimelock is IAdmin {
    function marginFeeBasisPoints() external view returns (uint256);

    function enableLeverage(address _vault) external;

    function disableLeverage(address _vault) external;

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled)
        external;

    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../peripherals/interfaces/ITimelock.sol";
import "./interfaces/IReferralStorage.sol";

contract ReferralStorage is Ownable, IReferralStorage {
    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    uint256 public constant BASIS_POINTS = 10000;

    mapping(address => uint256) public override referrerDiscountShares; // to override default value in tier
    mapping(address => uint256) public override referrerTiers; // link between user <> tier
    mapping(uint256 => Tier) public tiers;

    mapping(address => bool) public isHandler;

    mapping(bytes32 => address) public override codeOwners;
    mapping(address => bytes32) public override traderReferralCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external override onlyOwner {
        require(
            _totalRebate <= BASIS_POINTS,
            "ReferralStorage: invalid totalRebate"
        );
        require(
            _discountShare <= BASIS_POINTS,
            "ReferralStorage: invalid discountShare"
        );

        tiers[_tierId] = Tier({
            totalRebate: _totalRebate,
            discountShare: _discountShare
        });

        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referrer, uint256 _tierId)
        external
        override
        onlyOwner
    {
        require(_tierId != 0, "ReferralStorage: should not 0");
        require(
            tiers[_tierId].totalRebate != 0,
            "ReferralStorage: invalid tierId"
        );

        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(
            _discountShare <= BASIS_POINTS,
            "ReferralStorage: invalid discountShare"
        );

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    function setTraderReferralCode(address _account, bytes32 _code)
        external
        override
        onlyHandler
    {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(
            codeOwners[_code] == address(0),
            "ReferralStorage: code already exists"
        );

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount)
        external
        override
        onlyOwner
    {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function getTraderReferralInfo(address _account)
        external
        view
        override
        returns (bytes32, address)
    {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        require(
            _account != codeOwners[_code],
            "ReferralStorage: referred by himself"
        );

        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);

    function traderReferralCodes(address _account)
        external
        view
        returns (bytes32);

    function referrerDiscountShares(address _account)
        external
        view
        returns (uint256);

    function referrerTiers(address _account) external view returns (uint256);

    function getTraderReferralInfo(address _account)
        external
        view
        returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external;

    function setReferrerTier(address _referrer, uint256 _tierId) external;

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}