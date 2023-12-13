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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBrewlabsDiscountManager} from "./libs/IBrewlabsDiscountManager.sol";

contract BrewlabsAirdrop is Ownable {
    uint256 public constant DISCOUNT_MAX = 10_000;

    uint256 public commission = 0.00089 ether;
    uint256 public commissionLimit = 3 ether;
    uint256 public maxTxLimit = 200;

    /* options for 50% discount */
    address[] private tokensForDiscount;

    /* list of addresses for no fee */
    address[] private whitelist;

    address discountMgr;
    address public feeAddress = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;

    /* events */
    event AddedToWhitelist(address addr);
    event RemovedFromWhitelist(address addr);

    event AddedToDicountList(address token);
    event RemovedFromDicountList(address token);

    event DiscountMgrUpdated(address addr);
    event FeeAddressUpdated(address addr);

    event CommissionUpdated(uint256 amount);
    event CommissionLimitUpdated(uint256 amount);
    event CommissionTxLimitUpdated(uint256 amount);

    constructor() {}

    /* Airdrop Begins */
    function multiTransfer(
        address token,
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external payable {
        require(token != address(0x0), "Invalid token");
        require(
            addresses.length <= maxTxLimit,
            "GAS Error: max airdrop limit is 200 addresses"
        );
        require(
            addresses.length == amounts.length,
            "Mismatch between Address and token count"
        );

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                amounts[i] > 0,
                "Airdrop token amount must be greater than zero."
            );
            sum += amounts[i];
        }

        require(
            IERC20(token).balanceOf(msg.sender) >= sum,
            "Not enough tokens in wallet"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20(token).transferFrom(msg.sender, addresses[i], amounts[i]);
        }

        uint256 fee = estimateServiceFee(token, addresses.length);
        if (fee > 0) {
            require(msg.value == fee, "must send correct fee");

            payable(feeAddress).transfer(fee);
        }
    }

    function multiTransfer_fixed(
        address token,
        address[] calldata addresses,
        uint256 amount
    ) external payable {
        require(token != address(0x0), "Invalid token");
        require(
            addresses.length <= maxTxLimit,
            "GAS Error: max airdrop limit is 200 addresses"
        );
        require(amount > 0, "Airdrop token amount must be greater than zero.");

        uint256 sum = amount * addresses.length;
        require(
            IERC20(token).balanceOf(msg.sender) >= sum,
            "Not enough tokens in wallet"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20(token).transferFrom(msg.sender, addresses[i], amount);
        }

        uint256 fee = estimateServiceFee(token, addresses.length);
        if (fee > 0) {
            require(msg.value == fee, "must send correct fee");

            payable(feeAddress).transfer(fee);
        }
    }

    function estimateServiceFee(
        address token,
        uint256 count
    ) public view returns (uint256) {
        if (isInWhitelist(msg.sender)) return 0;

        uint256 fee = commission * count;
        if (fee > commissionLimit) fee = commissionLimit;

        if (isInDiscountList(token)) return fee / 2;

        if (discountMgr != address(0)) {
            uint256 discount = IBrewlabsDiscountManager(discountMgr).discountOf(
                msg.sender
            );
            fee = (fee * (DISCOUNT_MAX - discount)) / DISCOUNT_MAX;
        }
        return fee;
    }

    function addToDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == false,
            "Already added to token list for discount"
        );

        tokensForDiscount.push(token);

        emit AddedToDicountList(token);
    }

    function removeFromDiscount(address token) external onlyOwner {
        require(token != address(0x0), "Invalid address");
        require(
            isInDiscountList(token) == true,
            "Not exist in token list for discount"
        );

        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                tokensForDiscount[i] = tokensForDiscount[
                    tokensForDiscount.length - 1
                ];
                tokensForDiscount[tokensForDiscount.length - 1] = address(0x0);
                tokensForDiscount.pop();
                break;
            }
        }

        emit RemovedFromDicountList(token);
    }

    function isInDiscountList(address token) public view returns (bool) {
        for (uint256 i = 0; i < tokensForDiscount.length; i++) {
            if (tokensForDiscount[i] == token) {
                return true;
            }
        }

        return false;
    }

    function addToWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == false, "Already added to whitelsit");

        whitelist.push(addr);

        emit AddedToWhitelist(addr);
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");
        require(isInWhitelist(addr) == true, "Not exist in whitelist");

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist[whitelist.length - 1] = address(0x0);
                whitelist.pop();
                break;
            }
        }

        emit RemovedFromWhitelist(addr);
    }

    function isInWhitelist(address addr) public view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == addr) {
                return true;
            }
        }

        return false;
    }

    function setFeeAddress(address addr) external onlyOwner {
        require(addr != address(0x0), "Invalid address");

        feeAddress = addr;

        emit FeeAddressUpdated(addr);
    }

    function setDiscountMgrAddress(address addr) external onlyOwner {
        require(
            addr == address(0) || isContract(addr),
            "Invalid discount manager"
        );
        discountMgr = addr;

        emit DiscountMgrUpdated(addr);
    }

    function setCommission(uint256 _commission) external onlyOwner {
        require(_commission > 0, "Invalid amount");
        commission = _commission;

        emit CommissionUpdated(_commission);
    }

    function setCommissionLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");
        commissionLimit = _limit;

        emit CommissionLimitUpdated(_limit);
    }

    function setMaxTxLimit(uint256 _txLimit) external onlyOwner {
        require(_txLimit > 0, "Invalid amount");
        maxTxLimit = _txLimit;

        emit CommissionTxLimitUpdated(_txLimit);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBrewlabsDiscountManager {
    function discountOf(address _to) external view returns (uint256);
}