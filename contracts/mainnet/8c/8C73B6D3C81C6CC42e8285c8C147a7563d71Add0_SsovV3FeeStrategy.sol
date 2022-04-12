// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import {IFeeStrategy} from "../interfaces/IFeeStrategy.sol";

contract SsovV3FeeStrategy is Ownable, IFeeStrategy {
    struct FeeStructure {
        /// @dev Purchase Fee in 1e8: x% of the price of the underlying asset * the amount of options being bought
        uint256 purchaseFeePercentage;
        /// @dev Settlement Fee in 1e8: x% of the settlement price
        uint256 settlementFeePercentage;
    }

    /// @dev ssov address => FeeStructure
    mapping(address => FeeStructure) public ssovFeeStructures;

    /// @notice Emitted on update of a ssov fee structure
    /// @param ssov address of ssov
    /// @param feeStructure FeeStructure of the ssov
    event FeeStructureUpdated(address ssov, FeeStructure feeStructure);

    /// @notice Update the fee structure of an ssov
    /// @dev Can only be called by owner
    /// @param ssov target ssov
    /// @param feeStructure FeeStructure for the ssov
    function updateSsovFeeStructure(
        address ssov,
        FeeStructure calldata feeStructure
    ) external onlyOwner {
        ssovFeeStructures[ssov] = feeStructure;
        emit FeeStructureUpdated(ssov, feeStructure);
    }

    /// @notice Calculate Fees for purchase
    /// @param price price of underlying in 1e8 precision
    /// @param strike strike price of the option in 1e8 precision
    /// @param amount amount of options being bought in 1e18 precision
    /// @param finalFee in USD in 1e8 precision
    function calculatePurchaseFees(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256 finalFee) {
        (uint256 purchaseFeePercentage, ) = getSsovFeeStructure(msg.sender);

        finalFee = ((purchaseFeePercentage * amount * price) / 1e10) / 1e18;

        if (price < strike) {
            uint256 feeMultiplier = (((strike * 100) / (price)) - 100) + 100;
            finalFee = (feeMultiplier * finalFee) / 100;
        }
    }

    /// @notice Calculate Fees for settlement
    /// @param pnl PnL of the settlement
    /// @return finalFee in the precision of pnl
    function calculateSettlementFees(uint256 pnl)
        external
        view
        returns (uint256 finalFee)
    {
        (, uint256 settlementFeePercentage) = getSsovFeeStructure(msg.sender);

        finalFee = (settlementFeePercentage * pnl) / 1e10;
    }

    /// @notice Returns the fee structure of an ssov
    /// @param ssov target ssov
    function getSsovFeeStructure(address ssov)
        public
        view
        returns (uint256 purchaseFeePercentage, uint256 settlementFeePercentage)
    {
        FeeStructure memory feeStructure = ssovFeeStructures[ssov];

        purchaseFeePercentage = feeStructure.purchaseFeePercentage;
        settlementFeePercentage = feeStructure.settlementFeePercentage;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFeeStrategy {
    function calculatePurchaseFees(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function calculateSettlementFees(uint256) external view returns (uint256);
}