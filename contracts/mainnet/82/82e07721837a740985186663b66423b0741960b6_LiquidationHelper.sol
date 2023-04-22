// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/ERC20.sol";
import "libraries/CauldronLib.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/ICauldronV2.sol";
import "interfaces/ICauldronV3.sol";
import "interfaces/ICauldronV4.sol";

/// @title LiquidationHelper
/// @notice Helper contract to liquidate accounts using max borrow amount or a part of it.
/// The required MiM is transferred from the liquidator to the BentoBox in case there's not enough balance
/// inside the user degenbox to cover the liquidation.
contract LiquidationHelper {
    error ErrInvalidCauldronVersion(uint8 cauldronVersion);

    ERC20 public mim;

    constructor(ERC20 _mim) payable {
        mim = _mim;
    }

    function isLiquidatable(ICauldronV2 cauldron, address account) public view returns (bool) {
        return !CauldronLib.isSolvent(cauldron, account);
    }

    function previewMaxLiquidation(
        ICauldronV2 cauldron,
        address account
    ) external view returns (bool liquidatable, uint256 requiredMIMAmount, uint256 adjustedBorrowPart, uint256 returnedCollateralAmount) {
        adjustedBorrowPart = cauldron.userBorrowPart(account);
        (liquidatable, requiredMIMAmount, adjustedBorrowPart, returnedCollateralAmount) = previewLiquidation(
            cauldron,
            account,
            adjustedBorrowPart
        );
    }

    function previewLiquidation(
        ICauldronV2 cauldron,
        address account,
        uint256 borrowPart
    ) public view returns (bool liquidatable, uint256 requiredMIMAmount, uint256 adjustedBorrowPart, uint256 returnedCollateralAmount) {
        liquidatable = isLiquidatable(cauldron, account);
        (returnedCollateralAmount, adjustedBorrowPart, requiredMIMAmount) = CauldronLib.getLiquidationCollateralAndBorrowAmount(
            ICauldronV2(cauldron),
            account,
            borrowPart
        );
    }

    /// @notice Liquidate an account using max borrow amount
    function liquidateMax(
        address cauldron,
        address account,
        uint8 cauldronVersion
    ) external returns (uint256 collateralAmount, uint256 adjustedBorrowPart, uint256 requiredMimAmount) {
        return liquidateMaxTo(cauldron, account, msg.sender, cauldronVersion);
    }

    /// @notice Liquidate an account using max borrow amount and send the collateral to a different address
    function liquidateMaxTo(
        address cauldron,
        address account,
        address recipient,
        uint8 cauldronVersion
    ) public returns (uint256 collateralAmount, uint256 adjustedBorrowPart, uint256 requiredMimAmount) {
        uint256 borrowPart = ICauldronV2(cauldron).userBorrowPart(account);
        return liquidateTo(cauldron, account, recipient, borrowPart, cauldronVersion);
    }

    /// @notice Liquidate an account using a part of the borrow amount
    function liquidate(
        address cauldron,
        address account,
        uint256 borrowPart,
        uint8 cauldronVersion
    ) external returns (uint256 collateralAmount, uint256 adjustedBorrowPart, uint256 requiredMimAmount) {
        return liquidateTo(cauldron, account, msg.sender, borrowPart, cauldronVersion);
    }

    /// @notice Liquidate an account using a part of the borrow amount and send the collateral to a different address
    function liquidateTo(
        address cauldron,
        address account,
        address recipient,
        uint256 borrowPart,
        uint8 cauldronVersion
    ) public returns (uint256 collateralAmount, uint256 adjustedBorrowPart, uint256 requiredMimAmount) {
        (collateralAmount, adjustedBorrowPart, requiredMimAmount) = CauldronLib.getLiquidationCollateralAndBorrowAmount(
            ICauldronV2(cauldron),
            account,
            borrowPart
        );

        IBentoBoxV1 box = IBentoBoxV1(ICauldronV2(cauldron).bentoBox());
        uint256 shareMIMBefore = _transferRequiredMIMToCauldronDegenBox(box, requiredMimAmount);

        address masterContract = address(ICauldronV2(cauldron).masterContract());
        box.setMasterContractApproval(address(this), masterContract, true, 0, 0, 0);

        _liquidate(cauldron, account, adjustedBorrowPart, cauldronVersion);
        box.setMasterContractApproval(address(this), masterContract, false, 0, 0, 0);

        // withdraw/refund any MiM left and withdraw collateral to wallet
        box.withdraw(mim, address(this), msg.sender, 0, box.balanceOf(mim, address(this)) - shareMIMBefore);

        {
            IERC20 collateral = ICauldronV2(cauldron).collateral();
            box.withdraw(collateral, address(this), recipient, 0, box.balanceOf(collateral, address(this)));
        }
    }

    function _liquidate(address cauldron, address account, uint256 borrowPart, uint8 cauldronVersion) internal {
        address[] memory users = new address[](1);
        users[0] = account;
        uint256[] memory maxBorrowParts = new uint256[](1);
        maxBorrowParts[0] = borrowPart;

        if (cauldronVersion <= 2) {
            ICauldronV2(cauldron).liquidate(users, maxBorrowParts, address(this), address(0));
        } else if (cauldronVersion >= 3) {
            ICauldronV3(cauldron).liquidate(users, maxBorrowParts, address(this), address(0), new bytes(0));
        } else {
            revert ErrInvalidCauldronVersion(cauldronVersion);
        }
    }

    /// @notice Transfer MiM from the liquidator to the BentoBox
    function _transferRequiredMIMToCauldronDegenBox(IBentoBoxV1 box, uint256 amount) internal returns (uint256 shareMIMBefore) {
        shareMIMBefore = box.balanceOf(mim, address(this));
        mim.transferFrom(msg.sender, address(box), amount);
        box.deposit(mim, address(box), address(this), amount, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "BoringSolidity/libraries/BoringERC20.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/ICauldronV3.sol";
import "interfaces/ICauldronV4.sol";
import "libraries/MathLib.sol";

library CauldronLib {
    using BoringERC20 for IERC20;
    using RebaseLibrary for Rebase;

    uint256 internal constant EXCHANGE_RATE_PRECISION = 1e18;
    uint256 internal constant BPS_PRECISION = 1e4;
    uint256 internal constant COLLATERIZATION_RATE_PRECISION = 1e5;
    uint256 internal constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;
    uint256 internal constant DISTRIBUTION_PART = 10;
    uint256 internal constant DISTRIBUTION_PRECISION = 100;

    /// @dev example: 200 is 2% interests
    function getInterestPerSecond(uint256 interestBips) internal pure returns (uint64 interestsPerSecond) {
        return uint64((interestBips * 316880878) / 100); // 316880878 is the precomputed integral part of 1e18 / (36525 * 3600 * 24)
    }

    function getInterestPerYearFromInterestPerSecond(uint64 interestPerSecond) internal pure returns (uint64 interestPerYearBips) {
        return (interestPerSecond * 100) / 316880878;
    }

    function getUserBorrowAmount(ICauldronV2 cauldron, address user) internal view returns (uint256 borrowAmount) {
        Rebase memory totalBorrow = getTotalBorrowWithAccruedInterests(cauldron);
        return (cauldron.userBorrowPart(user) * totalBorrow.elastic) / totalBorrow.base;
    }

    // total borrow with on-fly accrued interests
    function getTotalBorrowWithAccruedInterests(ICauldronV2 cauldron) internal view returns (Rebase memory totalBorrow) {
        totalBorrow = cauldron.totalBorrow();
        (uint64 lastAccrued, , uint64 INTEREST_PER_SECOND) = cauldron.accrueInfo();
        uint256 elapsedTime = block.timestamp - lastAccrued;

        if (elapsedTime != 0 && totalBorrow.base != 0) {
            totalBorrow.elastic = totalBorrow.elastic + uint128((uint256(totalBorrow.elastic) * INTEREST_PER_SECOND * elapsedTime) / 1e18);
        }
    }

    function getOracleExchangeRate(ICauldronV2 cauldron) internal view returns (uint256) {
        IOracle oracle = IOracle(cauldron.oracle());
        bytes memory oracleData = cauldron.oracleData();
        return oracle.peekSpot(oracleData);
    }

    function getUserCollateral(ICauldronV2 cauldron, address account) internal view returns (uint256 amount, uint256 value) {
        IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
        uint256 share = cauldron.userCollateralShare(account);

        amount = bentoBox.toAmount(cauldron.collateral(), share, false);
        value = (amount * EXCHANGE_RATE_PRECISION) / getOracleExchangeRate(cauldron);
    }

    function getUserPositionInfo(
        ICauldronV2 cauldron,
        address account
    )
        internal
        view
        returns (
            uint256 ltvBps,
            uint256 healthFactor,
            uint256 borrowValue,
            uint256 collateralValue,
            uint256 liquidationPrice,
            uint256 collateralAmount
        )
    {
        (collateralAmount, collateralValue) = getUserCollateral(cauldron, account);

        borrowValue = getUserBorrowAmount(cauldron, account);
        ltvBps = (borrowValue * BPS_PRECISION) / collateralValue;

        uint256 COLLATERALIZATION_RATE = cauldron.COLLATERIZATION_RATE(); // 1e5 precision

        // example with WBTC (8 decimals)
        // 18 + 8 + 5 - 5 - 8 - 10 = 8 decimals
        IERC20 collateral = cauldron.collateral();
        uint256 collateralPrecision = 10 ** collateral.safeDecimals();
        liquidationPrice =
            (borrowValue * collateralPrecision ** 2 * 1e5) /
            COLLATERALIZATION_RATE /
            collateralAmount /
            EXCHANGE_RATE_PRECISION;

        healthFactor = MathLib.subWithZeroFloor(EXCHANGE_RATE_PRECISION, (EXCHANGE_RATE_PRECISION * liquidationPrice * getOracleExchangeRate(cauldron)) / collateralPrecision ** 2);
    }

    /// @notice the liquidator will get "MIM borrowPart" worth of collateral + liquidation fee incentive but borrowPart needs to be adjusted to take in account
    /// the sSpell distribution taken off the liquidation fee. This function takes in account the bad debt repayment in case
    /// the borrowPart give less collateral than it should.
    /// @param cauldron Cauldron contract
    /// @param account Account to liquidate
    /// @param borrowPart Amount of MIM debt to liquidate
    /// @return collateralAmount Amount of collateral that the liquidator will receive
    /// @return adjustedBorrowPart Adjusted borrowPart to take in account position with bad debt where the
    ///                            borrowPart give out more collateral than what the user has.
    /// @return requiredMim MIM amount that the liquidator will need to pay back to get the collateralShare
    function getLiquidationCollateralAndBorrowAmount(
        ICauldronV2 cauldron,
        address account,
        uint256 borrowPart
    ) internal view returns (uint256 collateralAmount, uint256 adjustedBorrowPart, uint256 requiredMim) {
        uint256 exchangeRate = getOracleExchangeRate(cauldron);
        Rebase memory totalBorrow = getTotalBorrowWithAccruedInterests(cauldron);
        IBentoBoxV1 box = IBentoBoxV1(cauldron.bentoBox());
        uint256 collateralShare = cauldron.userCollateralShare(account);
        IERC20 collateral = cauldron.collateral();

        // cap to the maximum amount of debt that can be liquidated in case the cauldron has bad debt
        {
            Rebase memory bentoBoxTotals = box.totals(collateral);

            // how much debt can be liquidated
            uint256 maxBorrowPart = (bentoBoxTotals.toElastic(collateralShare, false) * 1e23) /
                (cauldron.LIQUIDATION_MULTIPLIER() * exchangeRate);
            maxBorrowPart = totalBorrow.toBase(maxBorrowPart, false);

            if (borrowPart > maxBorrowPart) {
                borrowPart = maxBorrowPart;
            }
        }

        // convert borrowPart to debt
        requiredMim = totalBorrow.toElastic(borrowPart, false);

        // convert borrowPart to collateralShare
        {
            Rebase memory bentoBoxTotals = box.totals(collateral);

            // how much collateral share the liquidator will get from the given borrow amount
            collateralShare = bentoBoxTotals.toBase(
                (requiredMim * cauldron.LIQUIDATION_MULTIPLIER() * exchangeRate) /
                    (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                false
            );
            collateralAmount = box.toAmount(collateral, collateralShare, false);
        }

        // add the sSpell distribution part
        {
            requiredMim +=
                ((((requiredMim * cauldron.LIQUIDATION_MULTIPLIER()) / LIQUIDATION_MULTIPLIER_PRECISION) - requiredMim) *
                    DISTRIBUTION_PART) /
                DISTRIBUTION_PRECISION;

            IERC20 mim = cauldron.magicInternetMoney();

            // convert back and forth to amount to compensate for rounded up toShare conversion inside `liquidate`
            requiredMim = box.toAmount(mim, box.toShare(mim, requiredMim, true), true);
        }

        adjustedBorrowPart = borrowPart;
    }

    function isSolvent(ICauldronV2 cauldron, address account) internal view returns (bool) {
        IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
        Rebase memory totalBorrow = getTotalBorrowWithAccruedInterests(cauldron);
        uint256 exchangeRate = getOracleExchangeRate(cauldron);
        IERC20 collateral = cauldron.collateral();
        uint256 COLLATERIZATION_RATE = cauldron.COLLATERIZATION_RATE();
        uint256 collateralShare = cauldron.userCollateralShare(account);
        uint256 borrowPart = cauldron.userBorrowPart(account);

        if (borrowPart == 0) {
            return true;
        } else if (collateralShare == 0) {
            return false;
        } else {
            return
                bentoBox.toAmount(
                    collateral,
                    (collateralShare * (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION)) * COLLATERIZATION_RATE,
                    false
                ) >= (borrowPart * totalBorrow.elastic * exchangeRate) / totalBorrow.base;
        }
    }

    function getCollateralPrice(ICauldronV2 cauldron) internal view returns (uint256) {
        IERC20 collateral = cauldron.collateral();
        uint256 collateralPrecision = 10 ** collateral.safeDecimals();
        return (EXCHANGE_RATE_PRECISION * collateralPrecision) / getOracleExchangeRate(cauldron);
    }

    function decodeInitData(
        bytes calldata data
    )
        internal
        pure
        returns (
            address collateral,
            address oracle,
            bytes memory oracleData,
            uint64 INTEREST_PER_SECOND,
            uint256 LIQUIDATION_MULTIPLIER,
            uint256 COLLATERIZATION_RATE,
            uint256 BORROW_OPENING_FEE
        )
    {
        (collateral, oracle, oracleData, INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi
            .decode(data, (address, address, bytes, uint64, uint256, uint256, uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IStrategy.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";

interface ICauldronV2 {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function accrueInfo() external view returns (uint64, uint128, uint64);

    function BORROW_OPENING_FEE() external view returns (uint256);

    function COLLATERIZATION_RATE() external view returns (uint256);

    function LIQUIDATION_MULTIPLIER() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function bentoBox() external view returns (address);

    function feeTo() external view returns (address);

    function masterContract() external view returns (ICauldronV2);

    function collateral() external view returns (IERC20);

    function setFeeTo(address newFeeTo) external;

    function accrue() external;

    function totalBorrow() external view returns (Rebase memory);

    function userBorrowPart(address account) external view returns (uint256);

    function userCollateralShare(address account) external view returns (uint256);

    function withdrawFees() external;

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function addCollateral(address to, bool skim, uint256 share) external;

    function removeCollateral(address to, uint256 share) external;

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

    function reduceSupply(uint256 amount) external;

    function magicInternetMoney() external view returns (IERC20);

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV2.sol";

interface ICauldronV3 is ICauldronV2 {
    function borrowLimit() external view returns (uint128 total, uint128 borrowPartPerAddres);

    function changeInterestRate(uint64 newInterestRate) external;

    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) external;

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper,
        bytes calldata swapperData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV3.sol";

interface ICauldronV4 is ICauldronV3 {
    function setBlacklistedCallee(address callee, bool blacklisted) external;

    function blacklistedCallees(address callee) external view returns (bool);

    function repayForAll(uint128 amount, bool skim) external returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MathLib {
    function max(uint256[] memory values) internal pure returns (uint256) {
        uint256 maxValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] > maxValue) {
                maxValue = values[i];
            }
        }
        return maxValue;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256[] memory values) internal pure returns (uint256) {
        uint256 minValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] < minValue) {
                minValue = values[i];
            }
        }
        return minValue;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function subWithZeroFloor(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}