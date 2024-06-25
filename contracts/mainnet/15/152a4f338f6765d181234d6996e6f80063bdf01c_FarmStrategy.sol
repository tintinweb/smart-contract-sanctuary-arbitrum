// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    StrategyModule,
    SickleFactory,
    Sickle,
    ConnectorRegistry
} from "contracts/modules/StrategyModule.sol";
import { IFarmConnector } from "contracts/interfaces/IFarmConnector.sol";
import {
    DepositParams,
    HarvestParams,
    WithdrawParams,
    CompoundParams
} from "contracts/structs/FarmStrategyStructs.sol";
import { ZapLib } from "contracts/libraries/ZapLib.sol";
import { FeesLib } from "contracts/libraries/FeesLib.sol";
import { TransferLib } from "contracts/libraries/TransferLib.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";
import { SwapLib } from "contracts/libraries/SwapLib.sol";

library FarmStrategyFees {
    bytes4 constant Deposit = bytes4(keccak256("FarmDepositFee"));
    bytes4 constant Harvest = bytes4(keccak256("FarmHarvestFee"));
    bytes4 constant Compound = bytes4(keccak256("FarmCompoundFee"));
    bytes4 constant Withdraw = bytes4(keccak256("FarmWithdrawFee"));
}

contract FarmStrategy is StrategyModule {
    struct Libraries {
        TransferLib transferLib;
        SwapLib swapLib;
        FeesLib feesLib;
        ZapLib zapLib;
    }

    error TokenOutRequired();

    ZapLib public immutable zapLib;
    SwapLib public immutable swapLib;
    TransferLib public immutable transferLib;
    FeesLib public immutable feesLib;

    address public immutable strategyAddress;

    constructor(
        SickleFactory factory,
        ConnectorRegistry connectorRegistry,
        Libraries memory libraries
    ) StrategyModule(factory, connectorRegistry) {
        zapLib = libraries.zapLib;
        swapLib = libraries.swapLib;
        transferLib = libraries.transferLib;
        feesLib = libraries.feesLib;
        strategyAddress = address(this);
    }

    function deposit(
        DepositParams calldata params,
        address[] memory sweepTokens,
        address approved,
        bytes32 referralCode
    ) public payable {
        if (params.tokensIn.length != params.amountsIn.length) {
            revert SickleRegistry.ArrayLengthMismatch();
        }
        if (params.tokensIn.length == 0) {
            revert TransferLib.TokenInRequired();
        }
        Sickle sickle = getOrDeploySickle(msg.sender, approved, referralCode);

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);

        targets[0] = address(transferLib);
        data[0] = abi.encodeCall(
            TransferLib.transferTokensFromUser,
            (
                params.tokensIn,
                params.amountsIn,
                strategyAddress,
                FarmStrategyFees.Deposit
            )
        );

        targets[1] = address(zapLib);
        data[1] = abi.encodeCall(ZapLib.zapIn, (params.zapData));

        targets[2] =
            connectorRegistry.connectorOf(params.stakingContractAddress);
        data[2] = abi.encodeCall(
            IFarmConnector.deposit,
            (
                params.stakingContractAddress,
                params.zapData.addLiquidityData.lpToken,
                params.extraData
            )
        );

        if (sweepTokens.length > 0) {
            targets[3] = address(transferLib);
            data[3] =
                abi.encodeCall(TransferLib.transferTokensToUser, (sweepTokens));
        }

        sickle.multicall{ value: msg.value }(targets, data);
    }

    function compound(
        CompoundParams calldata params,
        address[] memory sweepTokens
    ) external {
        Sickle sickle = getSickle(msg.sender);

        address[] memory targets = new address[](5);
        bytes[] memory data = new bytes[](5);

        address farmConnector =
            connectorRegistry.connectorOf(params.claimContractAddress);

        targets[0] = farmConnector;
        data[0] = abi.encodeCall(
            IFarmConnector.claim,
            (params.claimContractAddress, params.claimExtraData)
        );

        targets[1] = address(feesLib);
        data[1] = abi.encodeCall(
            FeesLib.chargeFees,
            (strategyAddress, FarmStrategyFees.Compound, params.rewardTokens)
        );

        targets[2] = address(zapLib);
        data[2] = abi.encodeCall(ZapLib.zapIn, (params.zapData));

        targets[3] = farmConnector;
        data[3] = abi.encodeCall(
            IFarmConnector.deposit,
            (
                params.depositContractAddress,
                params.zapData.addLiquidityData.lpToken,
                params.depositExtraData
            )
        );

        if (sweepTokens.length > 0) {
            targets[4] = address(transferLib);
            data[4] =
                abi.encodeCall(TransferLib.transferTokensToUser, (sweepTokens));
        }

        sickle.multicall(targets, data);
    }

    function withdraw(
        WithdrawParams calldata params,
        address[] memory sweepTokens
    ) public {
        if (params.tokensOut.length == 0) {
            revert TokenOutRequired();
        }

        Sickle sickle = getSickle(msg.sender);

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);

        address farmConnector =
            connectorRegistry.connectorOf(params.stakingContractAddress);
        targets[0] = farmConnector;
        data[0] = abi.encodeCall(
            IFarmConnector.withdraw,
            (
                params.stakingContractAddress,
                params.zapData.removeLiquidityData.lpAmountIn,
                params.extraData
            )
        );

        targets[1] = address(zapLib);
        data[1] = abi.encodeCall(ZapLib.zapOut, (params.zapData));

        targets[2] = address(feesLib);
        data[2] = abi.encodeCall(
            FeesLib.chargeFees,
            (strategyAddress, FarmStrategyFees.Withdraw, params.tokensOut)
        );

        if (sweepTokens.length > 0) {
            targets[3] = address(transferLib);
            data[3] =
                abi.encodeCall(TransferLib.transferTokensToUser, (sweepTokens));
        }

        sickle.multicall(targets, data);
    }

    function harvest(
        HarvestParams calldata params,
        address[] memory sweepTokens
    ) public {
        Sickle sickle = getSickle(msg.sender);

        address[] memory targets = new address[](4);
        bytes[] memory data = new bytes[](4);

        address farmConnector =
            connectorRegistry.connectorOf(params.stakingContractAddress);
        targets[0] = farmConnector;
        data[0] = abi.encodeCall(
            IFarmConnector.claim,
            (params.stakingContractAddress, params.extraData)
        );

        targets[1] = address(swapLib);
        data[1] = abi.encodeCall(SwapLib.swapMultiple, (params.swaps));
        targets[2] = address(feesLib);
        data[2] = abi.encodeCall(
            FeesLib.chargeFees,
            (strategyAddress, FarmStrategyFees.Harvest, params.tokensOut)
        );

        if (sweepTokens.length > 0) {
            targets[3] = address(transferLib);
            data[3] =
                abi.encodeCall(TransferLib.transferTokensToUser, (sweepTokens));
        }

        sickle.multicall(targets, data);
    }

    function exit(
        HarvestParams calldata harvestParams,
        WithdrawParams calldata withdrawParams,
        address[] memory sweepTokens
    ) external {
        // Sweep is handled by the withdraw
        harvest(harvestParams, new address[](0));
        withdraw(withdrawParams, sweepTokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleFactory, Sickle } from "contracts/SickleFactory.sol";
import { ConnectorRegistry } from "contracts/ConnectorRegistry.sol";
import { AccessControlModule } from "contracts/modules/AccessControlModule.sol";

contract StrategyModule is AccessControlModule {
    ConnectorRegistry public immutable connectorRegistry;

    constructor(
        SickleFactory factory,
        ConnectorRegistry connectorRegistry_
    ) AccessControlModule(factory) {
        connectorRegistry = connectorRegistry_;
    }

    function getSickle(address owner) public view returns (Sickle) {
        Sickle sickle = Sickle(payable(factory.sickles(owner)));
        if (address(sickle) == address(0)) {
            revert SickleNotDeployed();
        }
        return sickle;
    }

    function getOrDeploySickle(
        address owner,
        address approved,
        bytes32 referralCode
    ) public returns (Sickle) {
        return
            Sickle(payable(factory.getOrDeploy(owner, approved, referralCode)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmConnector {
    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable;

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external;

    function claim(address target, bytes memory extraData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ZapInData, ZapOutData } from "contracts/libraries/ZapLib.sol";
import { SwapData } from "contracts/interfaces/ILiquidityConnector.sol";

struct DepositParams {
    address stakingContractAddress;
    address[] tokensIn;
    uint256[] amountsIn;
    ZapInData zapData;
    bytes extraData;
}

struct WithdrawParams {
    address stakingContractAddress;
    bytes extraData;
    ZapOutData zapData;
    address[] tokensOut;
}

struct HarvestParams {
    address stakingContractAddress;
    SwapData[] swaps;
    bytes extraData;
    address[] tokensOut;
}

struct CompoundParams {
    address claimContractAddress;
    bytes claimExtraData;
    address[] rewardTokens;
    ZapInData zapData;
    address depositContractAddress;
    bytes depositExtraData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import {
    ILiquidityConnector,
    SwapData,
    AddLiquidityData,
    RemoveLiquidityData
} from "contracts/interfaces/ILiquidityConnector.sol";
import { SwapLib } from "contracts/libraries/SwapLib.sol";
import { ConnectorRegistry } from "contracts/ConnectorRegistry.sol";
import { DelegateModule } from "contracts/modules/DelegateModule.sol";

struct ZapInData {
    SwapData[] swaps;
    AddLiquidityData addLiquidityData;
}

struct ZapOutData {
    RemoveLiquidityData removeLiquidityData;
    SwapData[] swaps;
}

contract ZapLib is DelegateModule {
    error LiquidityAmountError(); // 0x4d0ab6b4

    SwapLib public immutable swapLib;
    ConnectorRegistry public immutable connectorRegistry;

    constructor(ConnectorRegistry connectorRegistry_, SwapLib swapLib_) {
        connectorRegistry = connectorRegistry_;
        swapLib = swapLib_;
    }

    function zapIn(ZapInData memory zapData) external payable {
        uint256 swapDataLength = zapData.swaps.length;
        for (uint256 i; i < swapDataLength;) {
            _delegateTo(
                address(swapLib),
                abi.encodeCall(SwapLib.swap, (zapData.swaps[i]))
            );
            unchecked {
                i++;
            }
        }

        if (zapData.addLiquidityData.lpToken == address(0)) {
            return;
        }

        bool atLeastOneNonZero = false;

        AddLiquidityData memory addLiquidityData = zapData.addLiquidityData;
        uint256 addLiquidityDataTokensLength = addLiquidityData.tokens.length;
        for (uint256 i; i < addLiquidityDataTokensLength; i++) {
            if (addLiquidityData.tokens[i] == address(0)) {
                continue;
            }
            if (addLiquidityData.desiredAmounts[i] == 0) {
                addLiquidityData.desiredAmounts[i] =
                    IERC20(addLiquidityData.tokens[i]).balanceOf(address(this));
            }
            if (addLiquidityData.desiredAmounts[i] > 0) {
                atLeastOneNonZero = true;
                // In case there is USDT or similar dust approval, revoke it
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i], addLiquidityData.router, 0
                );
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i],
                    addLiquidityData.router,
                    addLiquidityData.desiredAmounts[i]
                );
            }
        }

        if (!atLeastOneNonZero) {
            revert LiquidityAmountError();
        }

        address routerConnector =
            connectorRegistry.connectorOf(addLiquidityData.router);

        _delegateTo(
            routerConnector,
            abi.encodeCall(ILiquidityConnector.addLiquidity, (addLiquidityData))
        );

        for (uint256 i; i < addLiquidityDataTokensLength;) {
            if (addLiquidityData.tokens[i] != address(0)) {
                // Revoke any dust approval in case the amount was estimated
                SafeTransferLib.safeApprove(
                    addLiquidityData.tokens[i], addLiquidityData.router, 0
                );
            }
            unchecked {
                i++;
            }
        }
    }

    function zapOut(ZapOutData memory zapData) external {
        if (zapData.removeLiquidityData.lpToken != address(0)) {
            if (zapData.removeLiquidityData.lpAmountIn > 0) {
                SafeTransferLib.safeApprove(
                    zapData.removeLiquidityData.lpToken,
                    zapData.removeLiquidityData.router,
                    zapData.removeLiquidityData.lpAmountIn
                );
            }
            address routerConnector = connectorRegistry.connectorOf(
                zapData.removeLiquidityData.router
            );
            _delegateTo(
                address(routerConnector),
                abi.encodeCall(
                    ILiquidityConnector.removeLiquidity,
                    zapData.removeLiquidityData
                )
            );
        }

        uint256 swapDataLength = zapData.swaps.length;
        for (uint256 i; i < swapDataLength;) {
            _delegateTo(
                address(swapLib),
                abi.encodeCall(SwapLib.swap, (zapData.swaps[i]))
            );
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { WETH } from "solmate/tokens/WETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Sickle } from "contracts/Sickle.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

contract FeesLib {
    event FeeCharged(
        address strategy, bytes4 feeDescriptor, uint256 amount, address token
    );
    event TransactionCostCharged(address recipient, uint256 amount);

    /// @notice Fees library version
    uint256 public constant VERSION = 1;

    /// @notice Sickle registry address
    SickleRegistry public immutable registry;

    /// @notice WETH9 token address
    WETH public immutable weth;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(SickleRegistry registry_, WETH weth_) {
        registry = registry_;
        weth = weth_;
    }

    /**
     * @notice Strategy contract charges fee to user depending on the type of
     * action and sends funds to the collector address
     * @param strategy Address of the strategy contract
     * @param feeDescriptor Descriptor of the fee to be charged
     * @param feeToken Address of the token from which an amount will be
     * @param feeBasis Amount to be charged (zero if on full amount)
     * charged (zero address if native token)
     */
    function chargeFee(
        address strategy,
        bytes4 feeDescriptor,
        address feeToken,
        uint256 feeBasis
    ) public payable returns (uint256 remainder) {
        uint256 fee = registry.feeRegistry(
            keccak256(abi.encodePacked(strategy, feeDescriptor))
        );

        if (feeBasis == 0) {
            if (feeToken == ETH) {
                uint256 wethBalance = weth.balanceOf(address(this));
                if (wethBalance > 0) {
                    weth.withdraw(wethBalance);
                }
                feeBasis = address(this).balance;
            } else {
                feeBasis = IERC20(feeToken).balanceOf(address(this));
            }
        }

        if (fee == 0) {
            return feeBasis;
        }

        uint256 amountToCharge = feeBasis * fee / 10_000;

        if (feeToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            SafeTransferLib.safeTransferETH(
                registry.collector(), amountToCharge
            );
        } else {
            SafeTransferLib.safeTransfer(
                feeToken, registry.collector(), amountToCharge
            );
        }

        emit FeeCharged(strategy, feeDescriptor, amountToCharge, feeToken);
        return feeBasis - amountToCharge;
    }

    function chargeFees(
        address strategy,
        bytes4 feeDescriptor,
        address[] memory feeTokens
    ) external {
        for (uint256 i = 0; i < feeTokens.length;) {
            chargeFee(strategy, feeDescriptor, feeTokens[i], 0);
            unchecked {
                i++;
            }
        }
    }

    function getBalance(
        Sickle sickle,
        address token
    ) public view returns (uint256) {
        if (token == ETH) {
            return weth.balanceOf(address(sickle));
        }
        return IERC20(token).balanceOf(address(sickle));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MsgValueModule } from "contracts/modules/MsgValueModule.sol";
import { WETH } from "lib/solmate/src/tokens/WETH.sol";
import { Sickle } from "contracts/Sickle.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { IERC20 } from
    "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { FeesLib } from "contracts/libraries/FeesLib.sol";
import { DelegateModule } from "contracts/modules/DelegateModule.sol";

contract TransferLib is MsgValueModule, DelegateModule {
    error ArrayLengthMismatch();
    error TokenInRequired();

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    WETH public immutable weth;

    FeesLib public immutable feesLib;

    constructor(FeesLib feseLib_, WETH weth_) {
        feesLib = feseLib_;
        weth = weth_;
    }

    /// @dev Transfers the balance of {token} from the contract to the
    /// sickle owner
    /// @param token Address of the token to transfer
    function transferTokenToUser(address token) public payable {
        address recipient = Sickle(payable(address(this))).owner();
        if (token == address(0)) {
            return;
        }
        if (token == ETH) {
            uint256 wethBalance = weth.balanceOf(address(this));
            if (wethBalance > 0) {
                weth.withdraw(wethBalance);
            }
            if (address(this).balance > 0) {
                SafeTransferLib.safeTransferETH(
                    recipient, address(this).balance
                );
            }
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                SafeTransferLib.safeTransfer(token, recipient, balance);
            }
        }
    }

    /// @dev Transfers all balances of {tokens} and/or ETH from the contract
    /// to the sickle owner
    /// @param tokens An array of token addresses
    function transferTokensToUser(address[] memory tokens) external payable {
        for (uint256 i = 0; i != tokens.length;) {
            transferTokenToUser(tokens[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @dev Transfers {amountIn} of {tokenIn} from the user to the Sickle
    /// contract, charging the fees and converting the amount to WETH if
    /// necessary
    /// @param tokenIn Address of the token to transfer
    /// @param amountIn Amount of the token to transfer
    /// @param strategy Address of the caller strategy
    /// @param feeSelector Selector of the caller function
    function transferTokenFromUser(
        address tokenIn,
        uint256 amountIn,
        address strategy,
        bytes4 feeSelector
    ) public payable {
        _checkMsgValue(amountIn, tokenIn == ETH);

        _transferTokenFromUser(tokenIn, amountIn, strategy, feeSelector);
    }

    /// @dev Transfers {amountIn} of {tokenIn} from the user to the Sickle
    /// contract, charging the fees and converting the amount to WETH if
    /// necessary
    /// @param tokensIn Addresses of the tokens to transfer
    /// @param amountsIn Amounts of the tokens to transfer
    /// @param strategy Address of the caller strategy
    /// @param feeSelector Selector of the caller function
    function transferTokensFromUser(
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        address strategy,
        bytes4 feeSelector
    ) external payable {
        if (tokensIn.length != amountsIn.length) {
            revert ArrayLengthMismatch();
        }
        if (tokensIn.length == 0) {
            revert TokenInRequired();
        }
        bool hasEth = false;

        for (uint256 i = 0; i < tokensIn.length; i++) {
            if (tokensIn[i] == ETH) {
                _checkMsgValue(amountsIn[i], true);
                hasEth = true;
            }
            _transferTokenFromUser(
                tokensIn[i], amountsIn[i], strategy, feeSelector
            );
        }

        if (!hasEth) {
            // Revert if ETH was sent but not used
            _checkMsgValue(0, false);
        }
    }

    /* Internal functions */

    function _transferTokenFromUser(
        address tokenIn,
        uint256 amountIn,
        address strategy,
        bytes4 feeSelector
    ) internal {
        if (tokenIn != ETH) {
            SafeTransferLib.safeTransferFrom(
                tokenIn,
                Sickle(payable(address(this))).owner(),
                address(this),
                amountIn
            );
        }

        bytes memory result = _delegateTo(
            address(feesLib),
            abi.encodeCall(
                FeesLib.chargeFee, (strategy, feeSelector, tokenIn, 0)
            )
        );
        uint256 remainder = abi.decode(result, (uint256));

        if (tokenIn == ETH) {
            weth.deposit{ value: remainder }();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Admin } from "contracts/base/Admin.sol";

library SickleRegistryEvents {
    event CollectorChanged(address newCollector);
    event FeesUpdated(bytes32[] feeHashes, uint256[] feesInBP);
    event ReferralCodeCreated(bytes32 indexed code, address indexed referrer);

    // Multicall caller and target whitelist status changes
    event CallerStatusChanged(address caller, bool isWhitelisted);
    event TargetStatusChanged(address target, bool isWhitelisted);
}

/// @title SickleRegistry contract
/// @author vfat.tools
/// @notice Manages the whitelisted contracts and the collector address
contract SickleRegistry is Admin {
    /// ERRORS ///

    error ArrayLengthMismatch(); // 0xa24a13a6
    error FeeAboveMaxLimit(); // 0xd6cf7b5e
    error InvalidReferralCode(); // 0xe55b4629

    /// STORAGE ///

    /// @notice Address of the fee collector
    address public collector;

    /// @notice Tracks the contracts that can be called through Sickle multicall
    /// @return True if the contract is a whitelisted target
    mapping(address => bool) public isWhitelistedTarget;

    /// @notice Tracks the contracts that can call Sickle multicall
    /// @return True if the contract is a whitelisted caller
    mapping(address => bool) public isWhitelistedCaller;

    /// @notice Keeps track of the referrers and their associated code
    mapping(bytes32 => address) public referralCodes;

    /// @notice Mapping for fee hashes (hash of the strategy contract addresses
    /// and the function selectors) and their associated fees
    /// @return The fee in basis points to apply to the transaction amount
    mapping(bytes32 => uint256) public feeRegistry;

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    /// @param collector_ Address of the collector
    constructor(address admin_, address collector_) Admin(admin_) {
        collector = collector_;
    }

    /// @notice Updates the whitelist status for multiple multicall targets
    /// @param targets Addresses of the contracts to update
    /// @param isApproved New status for the contracts
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedTargets(
        address[] calldata targets,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < targets.length;) {
            isWhitelistedTarget[targets[i]] = isApproved;
            emit SickleRegistryEvents.TargetStatusChanged(
                targets[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Updates the fee collector address
    /// @param newCollector Address of the new fee collector
    /// @custom:access Restricted to protocol admin.
    function updateCollector(address newCollector) external onlyAdmin {
        collector = newCollector;
        emit SickleRegistryEvents.CollectorChanged(newCollector);
    }

    /// @notice Update the whitelist status for multiple multicall callers
    /// @param callers Addresses of the callers
    /// @param isApproved New status for the caller
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedCallers(
        address[] calldata callers,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < callers.length;) {
            isWhitelistedCaller[callers[i]] = isApproved;
            emit SickleRegistryEvents.CallerStatusChanged(
                callers[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Associates a referral code to the address of the caller
    function setReferralCode(bytes32 referralCode) external {
        if (referralCodes[referralCode] != address(0)) {
            revert InvalidReferralCode();
        }

        referralCodes[referralCode] = msg.sender;
        emit SickleRegistryEvents.ReferralCodeCreated(referralCode, msg.sender);
    }

    /// @notice Update the fees for multiple strategy functions
    /// @param feeHashes Array of fee hashes
    /// @param feesArray Array of fees to apply (in basis points)
    /// @custom:access Restricted to protocol admin.
    function setFees(
        bytes32[] calldata feeHashes,
        uint256[] calldata feesArray
    ) external onlyAdmin {
        if (feeHashes.length != feesArray.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < feeHashes.length;) {
            if (feesArray[i] <= 500) {
                // maximum fee of 5%
                feeRegistry[feeHashes[i]] = feesArray[i];
            } else {
                revert FeeAboveMaxLimit();
            }
            unchecked {
                ++i;
            }
        }

        emit SickleRegistryEvents.FeesUpdated(feeHashes, feesArray);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { DelegateModule } from "contracts/modules/DelegateModule.sol";
import { ConnectorRegistry } from "contracts/ConnectorRegistry.sol";
import {
    ILiquidityConnector,
    SwapData
} from "contracts/interfaces/ILiquidityConnector.sol";

contract SwapLib is DelegateModule {
    error SwapAmountZero();

    ConnectorRegistry immutable connectorRegistry;

    constructor(ConnectorRegistry connectorRegistry_) {
        connectorRegistry = connectorRegistry_;
    }

    function swap(SwapData memory swapData) external payable {
        _swap(swapData);
    }

    function swapMultiple(SwapData[] memory swapData) external {
        uint256 swapDataLength = swapData.length;
        for (uint256 i; i < swapDataLength;) {
            _swap(swapData[i]);
            unchecked {
                i++;
            }
        }
    }

    /* Internal Functions */

    function _swap(SwapData memory swapData) internal {
        address tokenIn = swapData.tokenIn;

        if (swapData.amountIn == 0) {
            swapData.amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        if (swapData.amountIn == 0) {
            revert SwapAmountZero();
        }

        // In case there is USDT dust approval, revoke it
        SafeTransferLib.safeApprove(tokenIn, swapData.router, 0);

        SafeTransferLib.safeApprove(tokenIn, swapData.router, swapData.amountIn);

        address connectorAddress =
            connectorRegistry.connectorOf(swapData.router);

        ILiquidityConnector routerConnector =
            ILiquidityConnector(connectorAddress);

        _delegateTo(
            address(routerConnector),
            abi.encodeCall(routerConnector.swapExactTokensForTokens, swapData)
        );

        // Revoke any approval after swap in case the swap amount was estimated
        SafeTransferLib.safeApprove(tokenIn, swapData.router, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";
import { Sickle } from "contracts/Sickle.sol";
import { Admin } from "contracts/base/Admin.sol";

/// @title SickleFactory contract
/// @author vfat.tools
/// @notice Factory deploying new Sickle contracts
contract SickleFactory is Admin {
    /// EVENTS ///

    /// @notice Emitted when a new Sickle contract is deployed
    /// @param admin Address receiving the admin rights of the Sickle contract
    /// @param sickle Address of the newly deployed Sickle contract
    event Deploy(address indexed admin, address sickle);

    /// @notice Thrown when the caller is not whitelisted
    /// @param caller Address of the non-whitelisted caller
    error CallerNotWhitelisted(address caller); // 0x252c8273

    /// @notice Thrown when the factory is not active and a deploy is attempted
    error NotActive(); // 0x80cb55e2

    /// @notice Thrown when a Sickle contract is already deployed for a user
    error SickleAlreadyDeployed(); //0xf6782ef1

    /// STORAGE ///

    mapping(address => address) private _sickles;
    mapping(address => address) private _admins;
    mapping(address => bytes32) public _referralCodes;

    /// @notice Address of the SickleRegistry contract
    SickleRegistry public immutable registry;

    /// @notice Address of the Sickle implementation contract
    address public immutable implementation;

    /// @notice Address of the previous SickleFactory contract (if applicable)
    SickleFactory public immutable previousFactory;

    /// @notice Whether the factory is active (can deploy new Sickle contracts)
    bool public isActive = true;

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    /// @param sickleRegistry_ Address of the SickleRegistry contract
    /// @param sickleImplementation_ Address of the Sickle implementation
    /// contract
    /// @param previousFactory_ Address of the previous SickleFactory contract
    /// if applicable
    constructor(
        address admin_,
        address sickleRegistry_,
        address sickleImplementation_,
        address previousFactory_
    ) Admin(admin_) {
        registry = SickleRegistry(sickleRegistry_);
        implementation = sickleImplementation_;
        previousFactory = SickleFactory(previousFactory_);
    }

    /// @notice Update the isActive flag.
    /// @dev Effectively pauses and unpauses new Sickle deployments.
    /// @custom:access Restricted to protocol admin.
    function setActive(bool active) external onlyAdmin {
        isActive = active;
    }

    function _deploy(
        address admin,
        address approved,
        bytes32 referralCode
    ) internal returns (address sickle) {
        sickle = Clones.cloneDeterministic(
            implementation, keccak256(abi.encode(admin))
        );
        Sickle(payable(sickle)).initialize(admin, approved);
        _sickles[admin] = sickle;
        _admins[sickle] = admin;
        if (referralCode != bytes32(0)) {
            _referralCodes[sickle] = referralCode;
        }
        emit Deploy(admin, sickle);
    }

    function _getSickle(address admin) internal returns (address sickle) {
        sickle = _sickles[admin];
        if (sickle != address(0)) {
            return sickle;
        }
        if (address(previousFactory) != address(0)) {
            sickle = previousFactory.sickles(admin);
            if (sickle != address(0)) {
                _sickles[admin] = sickle;
                _admins[sickle] = admin;
                _referralCodes[sickle] = previousFactory.referralCodes(sickle);
                return sickle;
            }
        }
    }

    /// @notice Predict the address of a Sickle contract for a specific user
    /// @param admin Address receiving the admin rights of the Sickle contract
    /// @return sickle Address of the predicted Sickle contract
    function predict(address admin) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(admin));
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    /// @notice Returns the Sickle contract for a specific user
    /// @param admin Address that owns the Sickle contract
    /// @return sickle Address of the Sickle contract
    function sickles(address admin) external view returns (address sickle) {
        sickle = _sickles[admin];
        if (sickle == address(0) && address(previousFactory) != address(0)) {
            sickle = previousFactory.sickles(admin);
        }
    }

    /// @notice Returns the admin for a specific Sickle contract
    /// @param sickle Address of the Sickle contract
    /// @return admin Address that owns the Sickle contract
    function admins(address sickle) external view returns (address admin) {
        admin = _admins[sickle];
        if (admin == address(0) && address(previousFactory) != address(0)) {
            admin = previousFactory.admins(sickle);
        }
    }

    /// @notice Returns the referral code for a specific Sickle contract
    /// @param sickle Address of the Sickle contract
    /// @return referralCode Referral code for the user
    function referralCodes(address sickle)
        external
        view
        returns (bytes32 referralCode)
    {
        referralCode = _referralCodes[sickle];
        if (
            referralCode == bytes32(0) && address(previousFactory) != address(0)
        ) {
            referralCode = previousFactory.referralCodes(sickle);
        }
    }

    /// @notice Deploys a new Sickle contract for a specific user, or returns
    /// the existing one if it exists
    /// @param admin Address receiving the admin rights of the Sickle contract
    /// @param referralCode Referral code for the user
    /// @return sickle Address of the deployed Sickle contract
    function getOrDeploy(
        address admin,
        address approved,
        bytes32 referralCode
    ) external returns (address sickle) {
        if (!isActive) {
            revert NotActive();
        }
        if (!registry.isWhitelistedCaller(msg.sender)) {
            revert CallerNotWhitelisted(msg.sender);
        }
        if ((sickle = _getSickle(admin)) != address(0)) {
            return sickle;
        }
        return _deploy(admin, approved, referralCode);
    }

    /// @notice Deploys a new Sickle contract for a specific user
    /// @dev Sickle contracts are deployed with create2, the address of the
    /// admin is used as a salt, so all the Sickle addresses can be pre-computed
    /// and only 1 Sickle will exist per address
    /// @param referralCode Referral code for the user
    /// @return sickle Address of the deployed Sickle contract
    function deploy(
        address approved,
        bytes32 referralCode
    ) external returns (address sickle) {
        if (!isActive) {
            revert NotActive();
        }
        if (_getSickle(msg.sender) != address(0)) {
            revert SickleAlreadyDeployed();
        }
        return _deploy(msg.sender, approved, referralCode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Admin } from "contracts/base/Admin.sol";
import { TimelockAdmin } from "contracts/base/TimelockAdmin.sol";

error ConnectorNotRegistered(address target);

interface ICustomConnectorRegistry {
    function connectorOf(address target) external view returns (address);
}

contract ConnectorRegistry is Admin, TimelockAdmin {
    event ConnectorChanged(address target, address connector);
    event CustomRegistryAdded(address registry);
    event CustomRegistryRemoved(address registry);

    error ConnectorAlreadySet(address target);
    error ConnectorNotSet(address target);

    ICustomConnectorRegistry[] public customRegistries;
    mapping(ICustomConnectorRegistry => bool) public isCustomRegistry;

    mapping(address target => address connector) private connectors_;

    constructor(
        address admin_,
        address timelockAdmin_
    ) Admin(admin_) TimelockAdmin(timelockAdmin_) { }

    /// @notice Update connector addresses for a batch of targets.
    /// @dev Controls which connector contracts are used for the specified
    /// targets.
    /// @custom:access Restricted to protocol admin.
    function setConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] != address(0)) {
                revert ConnectorAlreadySet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    function updateConnectors(
        address[] calldata targets,
        address[] calldata connectors
    ) external onlyTimelockAdmin {
        for (uint256 i; i != targets.length;) {
            if (connectors_[targets[i]] == address(0)) {
                revert ConnectorNotSet(targets[i]);
            }
            connectors_[targets[i]] = connectors[i];
            emit ConnectorChanged(targets[i], connectors[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Append an address to the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function addCustomRegistry(ICustomConnectorRegistry registry)
        external
        onlyAdmin
    {
        customRegistries.push(registry);
        isCustomRegistry[registry] = true;
        emit CustomRegistryAdded(address(registry));
    }

    /// @notice Replace an address in the custom registries list.
    /// @custom:access Restricted to protocol admin.
    function updateCustomRegistry(
        uint256 index,
        ICustomConnectorRegistry newRegistry
    ) external onlyTimelockAdmin {
        address oldRegistry = address(customRegistries[index]);
        isCustomRegistry[customRegistries[index]] = false;
        emit CustomRegistryRemoved(oldRegistry);
        customRegistries[index] = newRegistry;
        isCustomRegistry[newRegistry] = true;
        if (address(newRegistry) != address(0)) {
            emit CustomRegistryAdded(address(newRegistry));
        }
    }

    function connectorOf(address target) external view returns (address) {
        address connector = connectors_[target];
        if (connector != address(0)) {
            return connector;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return _connector;
                    }
                } catch {
                    // Ignore
                }
            }

            unchecked {
                ++i;
            }
        }

        revert ConnectorNotRegistered(target);
    }

    function hasConnector(address target) external view returns (bool) {
        if (connectors_[target] != address(0)) {
            return true;
        }

        uint256 length = customRegistries.length;
        for (uint256 i; i != length;) {
            if (address(customRegistries[i]) != address(0)) {
                try customRegistries[i].connectorOf(target) returns (
                    address _connector
                ) {
                    if (_connector != address(0)) {
                        return true;
                    }
                } catch {
                    // Ignore
                }

                unchecked {
                    ++i;
                }
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Sickle } from "contracts/Sickle.sol";
import { SickleFactory } from "contracts/SickleFactory.sol";

contract AccessControlModule {
    SickleFactory public immutable factory;

    error NotOwner(address sender); // 30cd7471
    error NotApproved();
    error SickleNotDeployed();
    error NotRegisteredSickle();

    constructor(SickleFactory factory_) {
        factory = factory_;
    }

    modifier onlyRegisteredSickle() {
        if (factory.admins(address(this)) == address(0)) {
            revert NotRegisteredSickle();
        }

        _;
    }

    // @dev allow access only to the sickle's owner or addresses approved by him
    // to use only for functions such as claiming rewards or compounding rewards
    modifier onlyApproved(Sickle sickle) {
        // Here we check if the Sickle  was really deployed, this gives use the
        // guarantee that the contract that we are going to call is genuine
        if (factory.admins(address(sickle)) == address(0)) {
            revert SickleNotDeployed();
        }

        if (sickle.approved() != msg.sender) revert NotApproved();

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHTransferFailed();
    error TransferFromFailed();
    error TransferFailed();
    error ApproveFailed();

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) revert ETHTransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        if (!success) revert TransferFromFailed();
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert TransferFailed();
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        if (!success) revert ApproveFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DelegateModule {
    function _delegateTo(
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = to.delegatecall(data);

        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleStorage } from "contracts/base/SickleStorage.sol";
import { Multicall } from "contracts/base/Multicall.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

/// @title Sickle contract
/// @author vfat.tools
/// @notice Sickle facilitates farming and interactions with MasterChef
/// contracts
/// @dev Base contract inheriting from all the other "manager" contracts
contract Sickle is SickleStorage, Multicall {
    /// @notice Function to receive ETH
    receive() external payable { }

    /// @param sickleRegistry_ Address of the SickleRegistry contract
    constructor(SickleRegistry sickleRegistry_)
        initializer
        Multicall(sickleRegistry_)
    {
        _Sickle_initialize(address(0), address(0));
    }

    /// @param sickleOwner_ Address of the Sickle owner
    function initialize(
        address sickleOwner_,
        address approved_
    ) external initializer {
        _Sickle_initialize(sickleOwner_, approved_);
    }

    /// INTERNALS ///

    function _Sickle_initialize(
        address sickleOwner_,
        address approved_
    ) internal {
        SickleStorage._SickleStorage_initialize(sickleOwner_, approved_);
    }

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // id
        uint256, // value
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, // operator
        address, // from
        uint256[] calldata, // ids
        uint256[] calldata, // values
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MsgValueModule {
    error IncorrectMsgValue();

    function _checkMsgValue(uint256 inputAmount, bool isNative) internal {
        if (
            // Input is native token but user sent incorrect amount
            (isNative && inputAmount != msg.value)
            // Input is ERC20 but user sent native token as well
            || (!isNative && msg.value > 0)
        ) {
            revert IncorrectMsgValue();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Admin contract
/// @author vfat.tools
/// @notice Provides an administration mechanism allowing restricted functions
abstract contract Admin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the admin
    error NotAdminError(); //0xb5c42b3b

    /// EVENTS ///

    /// @notice Emitted when a new admin is set
    /// @param oldAdmin Address of the old admin
    /// @param newAdmin Address of the new admin
    event AdminSet(address oldAdmin, address newAdmin);

    /// STORAGE ///

    /// @notice Address of the current admin
    address public admin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    constructor(address admin_) {
        emit AdminSet(admin, admin_);
        admin = admin_;
    }

    /// @notice Sets a new admin
    /// @param newAdmin Address of the new admin
    /// @custom:access Restricted to protocol admin.
    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TimelockAdmin contract
/// @author vfat.tools
/// @notice Provides an timelockAdministration mechanism allowing restricted
/// functions
abstract contract TimelockAdmin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the timelockAdmin
    error NotTimelockAdminError();

    /// EVENTS ///

    /// @notice Emitted when a new timelockAdmin is set
    /// @param oldTimelockAdmin Address of the old timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    event TimelockAdminSet(address oldTimelockAdmin, address newTimelockAdmin);

    /// STORAGE ///

    /// @notice Address of the current timelockAdmin
    address public timelockAdmin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the timelockAdmin
    modifier onlyTimelockAdmin() {
        if (msg.sender != timelockAdmin) revert NotTimelockAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param timelockAdmin_ Address of the timelockAdmin
    constructor(address timelockAdmin_) {
        emit TimelockAdminSet(timelockAdmin, timelockAdmin_);
        timelockAdmin = timelockAdmin_;
    }

    /// @notice Sets a new timelockAdmin
    /// @dev Can only be called by the current timelockAdmin
    /// @param newTimelockAdmin Address of the new timelockAdmin
    function setTimelockAdmin(address newTimelockAdmin)
        external
        onlyTimelockAdmin
    {
        emit TimelockAdminSet(timelockAdmin, newTimelockAdmin);
        timelockAdmin = newTimelockAdmin;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Initializable } from
    "@openzeppelin/contracts/proxy/utils/Initializable.sol";

library SickleStorageEvents {
    event ApprovedAddressChanged(address newApproved);
}

/// @title SickleStorage contract
/// @author vfat.tools
/// @notice Base storage of the Sickle contract
/// @dev This contract needs to be inherited by stub contracts meant to be used
/// with `delegatecall`
abstract contract SickleStorage is Initializable {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the owner of the Sickle contract
    error NotOwnerError(); // 0x74a21527

    /// @notice Thrown when the caller is not a strategy contract or the
    /// Flashloan Stub
    error NotStrategyError(); // 0x4581ba62

    /// STORAGE ///

    /// @notice Address of the owner
    address public owner;

    /// @notice An address that can be set by the owner of the Sickle contract
    /// in order to trigger specific functions.
    address public approved;

    /// MODIFIERS ///

    /// @dev Restricts a function call to the owner, however if the admin was
    /// not set yet,
    /// the modifier will not restrict the call, this allows the SickleFactory
    /// to perform
    /// some calls on the user's behalf before passing the admin rights to them
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    /// INITIALIZATION ///

    /// @param owner_ Address of the owner of this Sickle contract
    function _SickleStorage_initialize(
        address owner_,
        address approved_
    ) internal onlyInitializing {
        owner = owner_;
        approved = approved_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Sets the approved address of this Sickle
    /// @param newApproved Address meant to be approved by the owner
    function setApproved(address newApproved) external onlyOwner {
        approved = newApproved;
        emit SickleStorageEvents.ApprovedAddressChanged(newApproved);
    }

    /// @notice Checks if `caller` is either the owner of the Sickle contract
    /// or was approved by them
    /// @param caller Address to check
    /// @return True if `caller` is either the owner of the Sickle contract
    function isOwnerOrApproved(address caller) public view returns (bool) {
        return caller == owner || caller == approved;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SickleStorage } from "contracts/base/SickleStorage.sol";
import { SickleRegistry } from "contracts/SickleRegistry.sol";

/// @title Multicall contract
/// @author vfat.tools
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is SickleStorage {
    /// ERRORS ///

    error MulticallParamsMismatchError(); // 0xc1e637c9

    /// @notice Thrown when the target contract is not whitelisted
    /// @param target Address of the non-whitelisted target
    error TargetNotWhitelisted(address target); // 0x47ccabe7

    /// @notice Thrown when the caller is not whitelisted
    /// @param caller Address of the non-whitelisted caller
    error CallerNotWhitelisted(address caller); // 0x252c8273

    /// STORAGE ///

    /// @notice Address of the SickleRegistry contract
    /// @dev Needs to be immutable so that it's accessible for Sickle proxies
    SickleRegistry public immutable registry;

    /// INITIALIZATION ///

    /// @param registry_ Address of the SickleRegistry contract
    constructor(SickleRegistry registry_) initializer {
        registry = registry_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Batch multiple calls together (calls or delegatecalls)
    /// @param targets Array of targets to call
    /// @param data Array of data to pass with the calls
    function multicall(
        address[] calldata targets,
        bytes[] calldata data
    ) external payable {
        if (targets.length != data.length) {
            revert MulticallParamsMismatchError();
        }

        if (!registry.isWhitelistedCaller(msg.sender)) {
            revert CallerNotWhitelisted(msg.sender);
        }

        for (uint256 i = 0; i != data.length;) {
            if (targets[i] == address(0)) {
                unchecked {
                    ++i;
                }
                continue; // No-op
            }

            if (targets[i] != address(this)) {
                if (!registry.isWhitelistedTarget(targets[i])) {
                    revert TargetNotWhitelisted(targets[i]);
                }
            }

            (bool success, bytes memory result) =
                targets[i].delegatecall(data[i]);

            if (!success) {
                if (result.length == 0) revert();
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}