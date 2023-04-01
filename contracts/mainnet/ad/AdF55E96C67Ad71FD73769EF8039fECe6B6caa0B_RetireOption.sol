// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: GPL-3.0

///  This contract deals with the product retire logic.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../library/common/DataTypes.sol";
import "../product/interfaces/IProductPool.sol";
import "../product/interfaces/ICustomerPool.sol";

contract RetireOption {
    /**
     * notice Currency conversion calculation.
     * @param tokenInAmount Incoming quantity.
     * @param tokenOutAmount Outcoming quantity.
     * @param product Product info.
     */
    function closeWithSwapAmt(
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        DataTypes.ProductInfo memory product,
        address stableC
    ) external pure returns (DataTypes.ExchangeTotal memory) {
        if (DataTypes.ProductType.BUY_LOW == product.productType) {
            return DataTypes.ExchangeTotal(stableC, product.cryptoType, tokenInAmount, tokenOutAmount);
        } else {
            return DataTypes.ExchangeTotal(product.cryptoType, stableC, tokenInAmount, tokenOutAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
    struct PurchaseProduct {
        uint256 customerId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId;
        uint256 conditionAmount;
        uint256 customerQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 soldTotalAmount;
        uint256 sellStartTime;
        uint256 sellEndTime;
        uint256 saleTotalAmount;
        uint256 maturityDate;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
    }

    struct TransferHelperInfo {
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        TransferHelperStatus typeValue;
    }

    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }

    //typeValue 0: customer to this, 1: this to customer principal, 2: this to customer reward, 3: this to valut, 4: this to manageWallet, 5 guardian withdraw
    enum TransferHelperStatus {
        TOTHIS,
        TOCUSTOMERP,
        TOCUSTOMERR,
        TOVALUT,
        TOMANAGE,
        GUARDIANW
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../../library/common/DataTypes.sol";

interface ICustomerPool {
    function deleteSpecifiedProduct(uint256 _prod, uint256 _customerId) external returns (bool);

    function addCustomerByProduct(
        uint256 _pid,
        uint256 _customerId,
        address _customerAddress,
        uint256 _amount,
        address _token,
        uint256 _customerReward,
        uint256 _cryptoQuantity
    ) external returns (bool);

    function updateCustomerReward(uint256 _pid, uint256 _customerId, uint256 _customerReward) external returns (bool);

    function getProductList(uint256 _prod) external view returns (DataTypes.PurchaseProduct[] memory);

    function getSpecifiedProduct(
        uint256 _pid,
        uint256 _customerId
    ) external view returns (DataTypes.PurchaseProduct memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../../library/common/DataTypes.sol";

interface IProductPool {
    function getProductInfoByPid(uint256 productId) external view returns (DataTypes.ProductInfo memory);

    function getProductInfoList() external view returns (DataTypes.ProductInfo[] memory);

    function _s_retireProductAndUpdateInfo(
        uint256 productId,
        DataTypes.ProgressStatus resultByCondition
    ) external returns (bool);

    function updateSoldTotalAmount(uint256 productId, uint256 sellAmount) external returns (bool);
}