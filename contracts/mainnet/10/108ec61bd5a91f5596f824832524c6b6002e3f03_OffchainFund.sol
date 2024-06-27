// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.13;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IOffchainFundUser} from "src/interfaces/IOffchainFundUser.sol";
import {IOffchainFundAdmin} from "src/interfaces/IOffchainFundAdmin.sol";

interface IOffchainFund is
    IOffchainFundUser,
    IOffchainFundAdmin,
    IAccessControl,
    IERC20,
    IERC20Metadata
{
    struct Order {
        uint256 epoch;
        uint256 amount;
    }

    /// @dev Net asset value of the fund
    /// @return nav Net asset value
    function nav() external view returns (uint256 nav);

    /// @dev Maximum `USDC` balance that can be held
    /// @return cap Maximum `USDC` balance that can be held
    function cap() external view returns (uint256 cap);

    /// @dev Minimum `USDC` balance that can be deposited
    /// @return min Minimum `USDC` balance that can be deposited
    function min() external view returns (uint256 min);

    /// @dev Current increment for the net asset value updates
    /// @return epoch Current increment for the net asset value updates
    function epoch() external view returns (uint256 epoch);

    /// @dev Price per share as calculated by the net asset value
    /// @return currentPrice Price per share
    function currentPrice() external view returns (uint256 currentPrice);

    /// @dev Total number of shares
    /// @return totalShares Total number of shares
    function totalShares() external view returns (uint256 totalShares);

    /// @dev State of a user's pending deposits
    /// @param account Address that placed the order
    /// @return epoch The epoch of the deposit
    /// @return amount The amount of `USDC` deposited
    function userDeposits(
        address account
    ) external view returns (uint256 epoch, uint256 amount);

    /// @dev State of a user's pending redemptions
    /// @param account Address that placed the order
    /// @return epoch The epoch of the redeem
    /// @return amount The amount of fund shares to redeem
    function userRedemptions(
        address account
    ) external view returns (uint256 epoch, uint256 amount);

    /// @dev Checks criteria for receiving fund shares
    /// @param account Address that placed the order
    /// @return canProcess Whether the order can be processed or not
    /// @return message The message for why the order can/can't be processed
    function canProcessDeposit(
        address account
    ) external returns (bool canProcess, string memory message);

    /// @dev Checks criteria for receiving `USDC`
    /// @param account Address that placed the order
    /// @return canProcess Whether the order can be processed or not
    /// @return message The message for why the order can/can't be processed
    function canProcessRedeem(
        address account
    ) external returns (bool canProcess, string memory message);

    /// @dev Checks that the address is a member of the whitelist
    /// @param account Address that placed the order
    /// @return _isWhitelisted Whether the address is a member of the whitelist
    function isWhitelisted(
        address account
    ) external view returns (bool _isWhitelisted);
}

contract OffchainFund is Ownable, AccessControl, ERC20, IOffchainFund {
    bytes32 public constant WHITELIST =
        keccak256(abi.encode("offchain.fund.whitelist"));

    uint8 public immutable DECIMAL_FACTOR;

    IERC20 public immutable usdc;

    bool public drained = false;

    uint256 public cap = 0;
    uint256 public min = 1e6;

    uint256 public epoch = 1;
    uint256 public currentPrice = 1e8;

    uint256 public tempMint = 0;
    uint256 public pendingDeposits = 0;
    uint256 public currentDeposits = 0;

    uint256 public tempBurn = 0;
    uint256 public pendingRedemptions = 0;
    uint256 public currentRedemptions = 0;

    uint256 public preDrainDepositCount = 0;
    uint256 public postDrainDepositCount = 0;

    uint256 public currentDepositCount = 0;

    mapping(address => Order) public userDeposits;
    mapping(address => Order) public userRedemptions;

    constructor(
        address owner,
        address usdc_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _transferOwnership(owner);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);

        usdc = IERC20(usdc_);

        DECIMAL_FACTOR = IERC20Metadata(usdc_).decimals();
    }

    /// @notice Transfer `USDC` to the contract
    /// @param assets Number of `USDC` tokens to be transferred to the contract
    function refill(uint256 assets) external {
        assert(usdc.transferFrom(_msgSender(), address(this), assets));

        emit Refill(_msgSender(), epoch, assets);
    }

    /// @notice Place order to receive fund shares by depositing `USDC`
    /// @param assets Number of `USDC` tokens to deposit
    function deposit(uint256 assets) external onlyRole(WHITELIST) {
        uint256 amount;
        uint256 balance;

        require(assets >= min, "deposit is less than the minimum");
        require(
            cap >= pendingDeposits + assets,
            "deposit would exceed epoch cap"
        );

        (bool valid, ) = _canProcessDeposit(_msgSender());
        require(!valid, "user has unprocessed userDeposits");

        balance = usdc.balanceOf(address(this));

        assert(usdc.transferFrom(_msgSender(), address(this), assets));

        // Ensure any fee taken on the transfer is accounted for

        amount = usdc.balanceOf(address(this)) - balance;

        // We restrict a user from adding to their deposit if they had made one
        // before `drain` was called.

        if (drained) {
            uint256 userEpoch = userDeposits[_msgSender()].epoch;

            require(
                userEpoch == 0 || userEpoch == epoch + 1,
                "cannot add to deposit after drain"
            );

            userDeposits[_msgSender()].epoch = epoch + 1;
            postDrainDepositCount = userDeposits[_msgSender()].amount == 0
                ? postDrainDepositCount + 1
                : postDrainDepositCount;
        } else {
            userDeposits[_msgSender()].epoch = epoch;
            preDrainDepositCount = userDeposits[_msgSender()].amount == 0
                ? preDrainDepositCount + 1
                : preDrainDepositCount;
        }

        pendingDeposits += amount;
        userDeposits[_msgSender()].amount += amount;

        emit Deposit(_msgSender(), epoch, amount);
    }

    /// @notice Process the batch of deposit orders for accounts to receive fund shares
    /// @param accountList Address list that placed orders
    function batchProcessDeposit(address[] calldata accountList) external {
        address account;

        uint256 length = accountList.length;
        for (uint256 i = 0; i < length; ++i) {
            account = accountList[i];
            (bool valid, ) = _canProcessDeposit(account);

            if (!valid) continue;

            _processDeposit(account);
        }
    }

    /// @notice Process the deposit order for account to receive fund shares
    /// @param account Address that placed the order
    function processDeposit(address account) external {
        (bool valid, string memory message) = _canProcessDeposit(account);
        require(valid, message);

        _processDeposit(account);
    }

    /// @notice Process the redeem order for an account to receive `USDC`
    /// @param account Address that placed the order
    function _processDeposit(address account) private {
        // sanity checks, should never fail, added just in case

        assert(currentPrice > 0);

        assert(currentDepositCount > 0);

        uint256 assets = userDeposits[account].amount;

        assert(currentDeposits >= assets);

        uint256 shares = (assets * 1e8 * 1e18) /
            (currentPrice * 10 ** DECIMAL_FACTOR);

        delete userDeposits[account];

        currentDepositCount--;
        currentDeposits -= assets;

        // Safety restriction to prevent overflow from rounding
        tempMint -= Math.min(shares, tempMint);

        address recipient = _isWhitelisted(account) ? account : owner();

        _mint(recipient, shares);

        emit ProcessDeposit(
            _msgSender(),
            recipient,
            epoch,
            shares,
            assets,
            currentPrice
        );
    }

    /// @notice Checks criteria for receiving fund shares
    /// @param account Address that placed the order
    /// @return bool Whether the order can be processed or not
    /// @return string The message for why the order can/can't be processed
    function canProcessDeposit(
        address account
    ) external view returns (bool, string memory) {
        return _canProcessDeposit(account);
    }

    /// @notice Checks criteria for receiving fund shares
    /// @param account Address that placed the order
    /// @return bool Whether the order can be processed or not
    /// @return string The message for why the order can/can't be processed
    function _canProcessDeposit(
        address account
    ) private view returns (bool, string memory) {
        if (userDeposits[account].epoch == 0)
            return (false, "account has no mint order");

        if (userDeposits[account].epoch >= epoch)
            return (false, "nav has not been updated for mint");

        return (true, "");
    }

    /// @notice Place order to receive `USDC` by burning fund shares
    /// @param shares Number of fund tokens to burn
    function redeem(uint256 shares) external onlyRole(WHITELIST) {
        (bool valid, ) = _canProcessRedeem(_msgSender());
        require(!valid, "user has unprocessed redemptions");

        _burnFrom(_msgSender(), shares);

        pendingRedemptions += shares;

        userRedemptions[_msgSender()].epoch = drained ? epoch + 1 : epoch;
        userRedemptions[_msgSender()].amount += shares;

        emit Redeem(_msgSender(), epoch, shares);
    }

    /// @notice Process the batch of redeem orders for accounts to receive `USDC`
    /// @param accountList Address list that placed orders
    function batchProcessRedeem(
        address[] calldata accountList
    ) external onlyOwner {
        address account;

        uint256 length = accountList.length;
        for (uint256 i = 0; i < length; ++i) {
            account = accountList[i];
            (bool valid, ) = _canProcessRedeem(account);

            if (!valid) continue;

            _processRedeem(account);
        }
    }

    /// @notice Process the redeem order for an account to receive `USDC`
    /// @param account Address that placed the order
    function processRedeem(address account) external onlyOwner {
        (bool valid, string memory message) = _canProcessRedeem(account);
        require(valid, message);

        _processRedeem(account);
    }

    /// @notice Process the redeem order for an account to receive `USDC`
    /// @param account Address that placed the order
    function _processRedeem(address account) private {
        uint256 shares = userRedemptions[account].amount;
        uint256 value = (shares * currentPrice) / 1e8;

        // sanity checks, should never fail, added just in case

        assert(currentRedemptions > 0);
        assert(currentRedemptions >= shares);

        uint256 contractsUsdcBalance = usdc.balanceOf(address(this));

        assert(contractsUsdcBalance > 0);

        uint256 balance = contractsUsdcBalance -
            Math.min(contractsUsdcBalance, pendingDeposits);

        uint256 available = (shares * balance * 1e18) /
            (currentRedemptions * 10 ** DECIMAL_FACTOR);

        currentRedemptions -= shares;

        address recipient = _isWhitelisted(account) ? account : owner();

        if (value > available) {
            /**
             *
             * This calculation can be done in one of two ways:
             *
             * 1) Take the percentage of the total value being redeemed and
             *    subract it from the order:
             *
             *    (amount * (value - available)) / value
             *
             * 2) Take the amount of tokens required to transfer out the amount
             *    of value the user is redeeming:
             *
             *    (available * 1e8) / currentPrice
             *
             * Both methods are mathematically identical since:
             *
             *    amount * (available / value)
             *       = amount * (available / (currentPrice * amount) / 1e8)
             *       = (available * 1e8) / currentPrice
             *
             */

            // Safety restriction to prevent overflow in case of rounding
            uint256 deduct = Math.min(
                (available * 1e8) / currentPrice,
                userRedemptions[account].amount
            );

            userRedemptions[account].epoch = epoch;
            userRedemptions[account].amount -= deduct;

            pendingRedemptions += userRedemptions[account].amount;

            // Safety restriction to prevent overflow from rounding
            available = Math.min(
                (available * 10 ** DECIMAL_FACTOR) / 1e18,
                contractsUsdcBalance
            );

            assert(usdc.transfer(recipient, available));

            emit ProcessRedeem(
                _msgSender(),
                recipient,
                epoch,
                deduct,
                available,
                currentPrice,
                false
            );

            return;
        }

        delete userRedemptions[account];

        // Safety restriction to prevent overflow in case of rounding
        value = Math.min(
            (value * 10 ** DECIMAL_FACTOR) / 1e18,
            contractsUsdcBalance
        );

        assert(usdc.transfer(recipient, value));

        emit ProcessRedeem(
            _msgSender(),
            recipient,
            epoch,
            shares,
            value,
            currentPrice,
            true
        );
    }

    /// @notice Checks criteria for receiving `USDC`
    /// @param account Address that placed the order
    /// @return bool Whether the order can be processed or not
    /// @return string The message for why the order can/can't be processed
    function canProcessRedeem(
        address account
    ) external view returns (bool, string memory) {
        return _canProcessRedeem(account);
    }

    /// @notice Checks criteria for receiving `USDC`
    /// @param account Address that placed the order
    /// @return bool Whether the order can be processed or not
    /// @return string The message for why the order can/can't be processed
    function _canProcessRedeem(
        address account
    ) private view returns (bool, string memory) {
        if (userRedemptions[account].epoch == 0)
            return (false, "account has no redeem order");

        if (userRedemptions[account].epoch >= epoch)
            return (false, "nav has not been updated for redeem");

        return (true, "");
    }

    /// @notice Pulls the maximum amount of available `USDC`
    function drain() external onlyOwner {
        require(!drained, "price has not been updated");

        drained = true;

        uint256 assets = pendingDeposits;

        currentDeposits += pendingDeposits;
        pendingDeposits = 0;

        uint256 shares = pendingRedemptions;

        currentRedemptions += pendingRedemptions;
        pendingRedemptions = 0;

        tempBurn = shares;

        assert(usdc.transfer(_msgSender(), assets));

        emit Drain(_msgSender(), epoch, assets, shares);
    }

    /// @notice Update the NAV per share for the fund and increment the epoch
    /// @param price New share price
    function update(uint256 price) external onlyOwner {
        require(price > 0, "price cannot be set to 0");
        require(drained, "user deposits have not been pulled");

        require(
            currentDepositCount == 0,
            "deposits have not been fully processed"
        );

        ++epoch;

        drained = false;
        currentPrice = price;

        currentDepositCount = preDrainDepositCount;
        preDrainDepositCount = postDrainDepositCount;
        postDrainDepositCount = 0;

        tempBurn = 0;
        tempMint =
            (currentDeposits * 1e8 * 1e18) /
            (currentPrice * 10 ** DECIMAL_FACTOR);

        emit Update(_msgSender(), epoch, currentPrice, totalShares());
    }

    /// @notice Net asset value of the fund
    /// @return uint256 Net asset value of the fund
    function nav() external view returns (uint256) {
        return (currentPrice * totalShares()) / 1e8;
    }

    /// @notice Total supply of shares
    /// @return uint256 Total supply of shares
    function totalShares() public view returns (uint256) {
        return tempMint + tempBurn + pendingRedemptions + totalSupply();
    }

    /// @notice Sets the limit on USDC accepted per epoch
    /// @param cap_ The new limit on deposits
    function adjustCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    /// @notice Sets the minimum deposit amount
    /// @param min_ The new minimum deposit
    function adjustMin(uint256 min_) external onlyOwner {
        min = min_;
    }

    /// @notice Adds an address to the whitelist
    /// @param account Address to add to the whitelist
    function addToWhitelist(address account) external {
        grantRole(WHITELIST, account);
    }

    /// @notice Process batch of addresses to be whitelisted
    /// @param accounts Address list to add to whitlist
    function batchAddToWhitelist(address[] calldata accounts) external {
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; ++i) {
            grantRole(WHITELIST, accounts[i]);
        }
    }

    /// @notice Process batch of addresses to be removed the whitelist
    /// @param account Address to remove from the whitelist
    function removeFromWhitelist(address account) external {
        revokeRole(WHITELIST, account);
    }

    /// @notice Process batch of addresses to be removed from whitelist
    /// @param accounts Address list to remove from whitlist
    function batchRemoveFromWhitelist(address[] calldata accounts) external {
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; ++i) {
            revokeRole(WHITELIST, accounts[i]);
        }
    }

    /// @notice Checks that the address is a member of the whitelist
    /// @param account Address that placed the order
    /// @return bool Whether the address is a member of the whitelist
    function isWhitelisted(address account) external view returns (bool) {
        return _isWhitelisted(account);
    }

    /// @notice Checks that the address is a member of the whitelist
    /// @param account Address that placed the order
    /// @return bool Whether the address is a member of the whitelist
    function _isWhitelisted(address account) private view returns (bool) {
        return hasRole(WHITELIST, account);
    }

    /// @notice transfer `ETH` to the sender/owner
    function recover() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /// @notice transfer `ERC-20` tokens to the sender/owner
    /// @param token_ Asset transferred out
    /// @return bool Status of the transfer
    function recover(address token_) external onlyOwner returns (bool) {
        IERC20 token = IERC20(token_);

        return token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        require(
            to == address(0) || hasRole(WHITELIST, to),
            "receiver address is not in the whitelist"
        );

        require(
            from == address(0) || hasRole(WHITELIST, from),
            "sender address is not in the whitelist"
        );
    }

    function _burnFrom(address account, uint256 amount) private {
        _spendAllowance(account, address(this), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IOffchainFundUser {
    /// @dev Emitted when `USDC` is deposited to the fund
    /// @param sender The sender of the `USDC`
    /// @param epoch The epoch of the deposit
    /// @param assets The amount of `USDC` deposited
    event Deposit(
        address indexed sender,
        uint256 indexed epoch,
        uint256 assets
    );

    /// @dev Emitted when fund shares redeem order is placed
    /// @param sender The sender of the redeem order
    /// @param epoch The epoch of the redeem order
    /// @param shares The amount of fund shares to redeem
    event Redeem(address indexed sender, uint256 indexed epoch, uint256 shares);

    /// @dev The asset of the fund
    /// @return usdc `USDC` token
    function usdc() external view returns (IERC20 usdc);

    /// @dev Place order to receive fund shares by depositing `USDC`
    /// @param amount The amount of `USDC` to deposit
    function deposit(uint256 amount) external;

    /// @dev Place order to receive `USDC` by burning fund shares
    /// @param shares The amount of shares to redeem
    function redeem(uint256 shares) external;
}

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.13;

interface IOffchainFundAdmin {
    /// @dev Emitted when the owner Refills the contract with USDC
    /// @param sender The sender of the `USDC`
    /// @param epoch The epoch of the refill
    /// @param assets The amount of `USDC` refilled
    event Refill(address indexed sender, uint256 indexed epoch, uint256 assets);

    /// @dev Emitted when the funds are drained from the contract
    /// @param sender The caller of the drain() function
    /// @param epoch The epoch of the drain
    /// @param assets The amount of `USDC` drained
    /// @param shares The amount of shares to be burned
    event Drain(
        address indexed sender,
        uint256 indexed epoch,
        uint256 assets,
        uint256 shares
    );

    /// @dev Emitted when the price is updated and the epoch starts
    /// @param sender The caller of the update() function
    /// @param epoch The epoch of the update
    /// @param price The new price of the share
    /// @param totalShares The total amount of shares available
    event Update(
        address indexed sender,
        uint256 indexed epoch,
        uint256 price,
        uint256 totalShares
    );

    /// @dev Emitted when the deposit order is processed
    /// @param sender The caller of the processDeposit() function
    /// @param account The account that placed the deposit order
    /// @param epoch The current epoch
    /// @param shares The amount of shares received
    /// @param assets The amount of `USDC` deposited
    /// @param price The price of the share
    event ProcessDeposit(
        address indexed sender,
        address indexed account,
        uint256 indexed epoch,
        uint256 shares,
        uint256 assets,
        uint256 price
    );

    /// @dev Emitted when the redeem order is processed
    /// @param sender The caller of the processRedeem() function
    /// @param account The account that placed the redeem order
    /// @param epoch The current epoch
    /// @param shares The amount of shares burned
    /// @param assets The amount of `USDC` received
    /// @param price The price of the share
    /// @param filled Whether the order was fully filled or not
    event ProcessRedeem(
        address indexed sender,
        address indexed account,
        uint256 indexed epoch,
        uint256 shares,
        uint256 assets,
        uint256 price,
        bool filled
    );

    /// @dev Total deposits submitted in the current epoch
    /// @return _pendingDeposits Total deposits submitted in the current epoch
    function pendingDeposits() external view returns (uint256 _pendingDeposits);

    /// @dev All passed passed available to be processed on a price update
    /// @return _currentDeposits All passed passed available to be processed on a price update
    function currentDeposits() external view returns (uint256 _currentDeposits);

    /// @dev Number of accounts with current deposits
    /// @return _currentDepositCount Number of accounts with current deposits
    function currentDepositCount()
        external
        view
        returns (uint256 _currentDepositCount);

    /// @dev Returns whether the Fund is drained (cut-off) of deposits or not
    /// @return _drained whether the Fund is drained (cut-off) of deposits or not
    function drained() external view returns (bool _drained);

    /// @dev Number of accounts with pre-drain deposits
    /// @return _preDrainDepositCount Number of accounts with pre-drain deposits
    function preDrainDepositCount()
        external
        view
        returns (uint256 _preDrainDepositCount);

    /// @dev Number of accounts with post-drain deposits
    /// @return _postDrainDepositCount Number of accounts with post-drain deposits
    function postDrainDepositCount()
        external
        view
        returns (uint256 _postDrainDepositCount);

    /// @dev Total redemptions submitted in the current epoch
    /// @return _pendingRedemptions Total redemptions submitted in the current epoch
    function pendingRedemptions()
        external
        view
        returns (uint256 _pendingRedemptions);

    /// @dev All passed redemptions available to be processed
    /// @return _currentRedemptions All passed redemptions available to be processed
    function currentRedemptions()
        external
        view
        returns (uint256 _currentRedemptions);

    /// @dev Sets the limit on USDC accepted per epoch
    /// @param cap_ The new limit on deposits
    function adjustCap(uint256 cap_) external;

    /// @dev Sets the minimum deposit amount
    /// @param min_ The new minimum deposit
    function adjustMin(uint256 min_) external;

    /// @dev Adds an address to the whitelist
    /// @param account Address to add to the whitelist
    function addToWhitelist(address account) external;

    /// @dev Removes address from the whitelist
    /// @param account Address to remove from the whitelist
    function removeFromWhitelist(address account) external;

    /// @dev Process batch of addresses to be whitelisted
    /// @param accounts Address list to add to whitlist
    function batchAddToWhitelist(address[] calldata accounts) external;

    /// @dev Process batch of addresses to be removed the whitelist
    /// @param accounts Address list to remove from the whitelist
    function batchRemoveFromWhitelist(address[] calldata accounts) external;

    /// @dev Pulls the maximum amount of available `USDC`
    function drain() external;

    /// @dev Update the NAV per share for the fund and increment the epoch
    /// @param price New share price
    function update(uint256 price) external;

    /// @dev Transfer `USDC` to the contract
    /// @param assets Number of `USDC` tokens to be transferred to the contract
    function refill(uint256 assets) external;

    /// @dev Process the redeem order for an account to receive `USDC`
    /// @param account Address that placed the order
    function processRedeem(address account) external;

    /// @dev Process the deposit order for account to receive fund shares
    /// @param account Address that placed the order
    function processDeposit(address account) external;

    /// @dev Process the batch of deposit orders for accounts to receive fund shares
    /// @param accountList Address list that placed orders
    function batchProcessDeposit(address[] calldata accountList) external;

    /// @dev Process the batch of redeem orders for accounts to receive `USDC`
    /// @param accountList Address list that placed orders
    function batchProcessRedeem(address[] calldata accountList) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}