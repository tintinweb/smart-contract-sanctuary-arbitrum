// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStrategyVault} from "../interfaces/IStrategyVault.sol";
import {VaultGetter} from "./VaultGetter.sol";
import {IErrors} from "../interfaces/IErrors.sol";

library PositionSizer {
    //////////////////////////////////////////////
    //                 GETTER                   //
    //////////////////////////////////////////////

    function strategyCount() public pure returns (uint256) {
        return 4;
    }

    //////////////////////////////////////////////
    //                 EXTERNAL                 //
    //////////////////////////////////////////////
    /**
        @notice Fetches the weights for the vaults
        @dev If 1 then x% deployed in equalWeight or if 2 then x% deployed in customWeight. When 2, weights would
        return either fixed, cascading, or best return -- threshold could be assigned in these ways
        @param vaults the list of vaults to check
        @param epochIds the list of epochIds to check
        @param availableAmount the amount available to deposit
        @param weightStrategy the strategy to use for weights
     */
    function fetchWeights(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 availableAmount,
        uint256 weightStrategy
    ) external view returns (uint256[] memory amounts) {
        if (weightStrategy == 1)
            return _equalWeight(availableAmount, vaults.length);
        else if (weightStrategy < strategyCount()) {
            uint256[] memory weights = _fetchWeight(
                vaults,
                epochIds,
                weightStrategy
            );
            return _customWeight(availableAmount, vaults, weights);
        } else revert IErrors.InvalidWeightStrategy();
    }

    //////////////////////////////////////////////
    //                 INTERNAL                 //
    //////////////////////////////////////////////
    /**
        @notice Assigns the available amount across the vaults
        @param availableAmount the amount available to deposit
        @param length the length of the vaults
        @return amounts The list of amounts to deposit in each vault
     */
    function _equalWeight(
        uint256 availableAmount,
        uint256 length
    ) private pure returns (uint256[] memory amounts) {
        amounts = new uint256[](length);

        uint256 modulo = availableAmount % length;
        for (uint256 i = 0; i < length; ) {
            amounts[i] = availableAmount / length;
            if (modulo > 0) {
                amounts[i] += 1;
                modulo -= 1;
            }
            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Assigns the available amount in custom weights across the vaults
        @param availableAmount the amount available to deposit
        @param vaults the list of vaults to check
        @param customWeights the list of custom weights to check
        @return amounts The list of amounts to deposit in each vault
     */
    function _customWeight(
        uint256 availableAmount,
        address[] memory vaults,
        uint256[] memory customWeights
    ) internal pure returns (uint256[] memory amounts) {
        amounts = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ) {
            uint256 weight = customWeights[i];
            if (weight == 0) amounts[i] = 0;
            else amounts[i] = (availableAmount * weight) / 10_000;
            unchecked {
                i++;
            }
        }
    }

    //////////////////////////////////////////////
    //            INTERNAL - WEIGHT MATH        //
    //////////////////////////////////////////////
    /**
        @notice Fetches the weights dependent on the strategy
        @param vaults the list of vaults to check
        @param epochIds the list of epochIds to check
        @param weightStrategy the strategy to use for weights
        @return weights The list of weights to use
     */
    function _fetchWeight(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 weightStrategy
    ) internal view returns (uint256[] memory weights) {
        if (weightStrategy == 2) return _fixedWeight(vaults);
        if (weightStrategy == 3) return _thresholdWeight(vaults, epochIds);
    }

    /**
        @notice fetches the fixed weights from the strategy vault
        @param vaults the list of vaults to check
        @return weights The list of weights to use
     */
    function _fixedWeight(
        address[] memory vaults
    ) internal view returns (uint256[] memory weights) {
        weights = IStrategyVault(address(this)).fetchVaultWeights();
        if (weights.length != vaults.length) revert IErrors.LengthMismatch();
    }

    /**
        @notice Fetches the weights from strategy vault where appended value is threshold and rest are ids
        @dev Threshold assigns funds equally if threshold is passed
     */
    function _thresholdWeight(
        address[] memory vaults,
        uint256[] memory epochIds
    ) internal view returns (uint256[] memory weights) {
        uint256[] memory marketIds = IStrategyVault(address(this))
            .fetchVaultWeights();
        if (marketIds.length != vaults.length + 1)
            revert IErrors.LengthMismatch();

        // NOTE: Threshold is appended and weights are marketIds for V1 or empty for V2
        uint256 threshold = marketIds[marketIds.length - 1];
        weights = new uint256[](vaults.length);
        uint256[] memory validIds = new uint256[](vaults.length);
        uint256 validCount;

        for (uint256 i; i < vaults.length; ) {
            uint256 roi = _fetchReturn(vaults[i], epochIds[i], marketIds[i]);
            if (roi > threshold) {
                validCount += 1;
                validIds[i] = i;
            }
            unchecked {
                i++;
            }
        }
        if (validCount == 0) revert IErrors.NoValidThreshold();

        uint256 modulo = 10_000 % validCount;
        for (uint j; j < validCount; ) {
            uint256 location = validIds[j];
            weights[location] = 10_000 / validCount;
            if (modulo > 0) {
                weights[location] += 1;
                modulo -= 1;
            }
            unchecked {
                j++;
            }
        }
    }

    //////////////////////////////////////////////
    //            INTERNAL - ROI CALCS        //
    //////////////////////////////////////////////
    /**
        @notice Fetches the roi for a list of vaults
        @param vaults the list of vaults
        @param epochIds the list of epochIds
        @param marketIds the list of marketIds
        @return roi The list of rois
     */
    function _fetchReturns(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256[] memory marketIds
    ) internal view returns (uint256[] memory roi) {
        for (uint256 i = 0; i < vaults.length; ) {
            roi[i] = _fetchReturn(vaults[i], epochIds[i], marketIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Fetches the roi for a vault
        @param vault the vault  
        @param epochId the epochId to check
        @param marketId the marketId to check
        @return roi The roi for the vault
     */
    function _fetchReturn(
        address vault,
        uint256 epochId,
        uint256 marketId
    ) private view returns (uint256 roi) {
        return VaultGetter.getRoi(vault, epochId, marketId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IStrategyVault {
    function deployFunds() external;

    function withdrawFunds() external;

    function weightProportion() external view returns (uint16);

    function vaultWeights() external view returns (uint256[] memory);

    function vaultWeights(uint256) external view returns (uint256);

    function threshold() external view returns (uint256);

    function fetchVaultWeights() external view returns (uint256[] memory);

    function asset() external view returns (ERC20 asset);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IErrors} from "../interfaces/IErrors.sol";
import {IEarthquake} from "../interfaces/IEarthquake.sol";
import {IEarthquakeFactory} from "../interfaces/IEarthquakeFactory.sol";

library VaultGetter {
    /**
        @notice Checks if the list of vaults being provided are valid Y2K vaults
        @dev Checks if address !=0, checks if asset !=0, and checks if emissionToken is valid
        @param vaults the list of vaults to check
     */
    function checkVaultsValid(address[] calldata vaults) public view {
        for (uint256 i = 0; i < vaults.length; ) {
            checkVaultValid(IEarthquake(vaults[i]));

            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Gets the list of epochIds for the vault that are active along with vaultType
        @dev Vaults are only valid where the most recent epoch can be deposited to
        @param vaults the list of vaults to check
        @return epochIds validVaults vaultType - the list of epochIds for the vaults, the list of valid vaults, and the list of vault types
     */
    function fetchEpochIds(
        address[] memory vaults
    )
        public
        view
        returns (
            uint256[] memory epochIds,
            address[] memory validVaults,
            uint256[] memory vaultType
        )
    {
        uint256 validCount;
        epochIds = new uint256[](vaults.length);
        validVaults = new address[](vaults.length);
        vaultType = new uint256[](vaults.length);

        for (uint256 i = 0; i < vaults.length; ) {
            IEarthquake vault = IEarthquake(vaults[i]);

            bool valid;
            (valid, epochIds[i], vaultType[i]) = epochValid(vault);
            unchecked {
                i++;
            }

            if (!valid) {
                continue;
            }

            validVaults[validCount] = address(vault);
            unchecked {
                validCount++;
            }
        }
    }

    /**
        @notice Checks if a vault has a valid epoch
        @dev Vault is valid where length >0, most recent epochId has not ended, and most recent epochId has not begun. When
        vaults is V1 calls differ hence the use of a try/catch block returning vaultType depending on block
        @param vault the vault to check
        @return valid epochId vaultType - the validity of the vault, the epochId, and the vaultType
     */
    function epochValid(
        IEarthquake vault
    ) public view returns (bool, uint256, uint256) {
        try vault.epochsLength() returns (uint256 epochLength) {
            if (epochLength == 0) return (false, 0, 0);

            uint256 epochId = vault.epochs(epochLength - 1);
            if (vault.idEpochEnded(epochId)) return (false, 0, 0);

            if (block.timestamp > vault.idEpochBegin(epochId))
                return (false, 0, 0);
            return (true, epochId, 1);
        } catch {
            try vault.getEpochsLength() returns (uint256 epochLength) {
                if (epochLength == 0) return (false, 0, 0);

                uint256 epochId = vault.epochs(epochLength - 1);
                (uint40 epochBegin, uint40 epochEnd, ) = vault.getEpochConfig(
                    epochId
                );

                if (block.timestamp > epochEnd) return (false, 0, 0);
                if (block.timestamp > epochBegin) return (false, 0, 0);
                return (true, epochId, 2);
            } catch {
                return (false, 0, 0);
            }
        }
    }

    /**
        @notice Gets the roi for an epochId for an Earthquake vault
        @dev Roi is calculated as the counterPartyVault supply / vault supply * 10_000 (for an epochId)
        @param vault the vault to check
        @param epochId the epochId to check
        @param marketId the marketId to check
     */
    function getRoi(
        address vault,
        uint256 epochId,
        uint256 marketId
    ) public view returns (uint256) {
        uint256 vaultSupply = IEarthquake(vault).totalSupply(epochId);

        address counterVault;
        IEarthquake iVault = IEarthquake(vault);
        try iVault.counterPartyVault() returns (address vaultAddr) {
            counterVault = vaultAddr;
        } catch {
            address[] memory vaults = IEarthquakeFactory(iVault.factory())
                .getVaults(marketId);
            counterVault = vaults[0] == vault ? vaults[1] : vaults[0];
        }

        uint256 counterSupply = IEarthquake(counterVault).totalSupply(epochId);
        return (counterSupply * 10_000) / vaultSupply;
    }

    /**
        @notice Checks if the vault has key inputs
        @dev Vault could be dupped with these inputs but as usage is for our inputs only
        it's more of a sanity check the vault input being used by an admin is valid
        @param _vault the vault to check
     */
    function checkVaultValid(IEarthquake _vault) public view {
        if (address(_vault) == address(0)) revert IErrors.InvalidVaultAddress();

        if (address(_vault.asset()) == address(0))
            revert IErrors.InvalidVaultAsset();

        if (_vault.controller() == address(0))
            revert IErrors.InvalidVaultController();

        if (_vault.treasury() == address(0)) revert IErrors.InvalidTreasury();

        try _vault.emissionsToken() returns (address emissionsToken) {
            if (emissionsToken == address(0))
                revert IErrors.InvalidVaultEmissions();
            if (_vault.counterPartyVault() == address(0))
                revert IErrors.InvalidVaultCounterParty();
        } catch {
            // NOTE: V1 vaults do not have emissionsToken storage variable
        }
    }

    /**
        @notice Checks if the market is valid
        @dev if the factory returns an empty array then the market is not valid - where market is a vault address
        @param _vault the vault to check
        @param _marketId the marketId to check
     */
    function checkMarketValid(
        IEarthquake _vault,
        uint256 _marketId
    ) public view {
        // NOTE: Factory will vary but implementation for calls is the same
        IEarthquakeFactory factory = IEarthquakeFactory(
            address(_vault.factory())
        );
        address[] memory vaults = factory.getVaults(_marketId);
        if (vaults[0] == address(0)) revert IErrors.MarketNotExist();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IErrors {
    // Generic Errors
    error InvalidInput();
    error InsufficientBalance();

    // Vault Errors
    error VaultNotApproved();
    error FundsNotDeployed();
    error FundsAlreadyDeployed();
    error InvalidLengths();
    error InvalidUnqueueAmount();
    error InvalidWeightId();
    error InvalidQueueSize();
    error InvalidQueueId();
    error InvalidArrayLength();
    error InvalidDepositAmount();
    error ZeroShares();
    error QueuedAmountInsufficient();
    error NoQueuedWithdrawals();
    error QueuedWithdrawalPending();
    error UnableToUnqueue();
    error PositionClosePending();

    // Hook Errors
    error Unauthorized();
    error VaultSet();
    error AssetIdNotSet();
    error InvalidPathCount();
    error OutdatedPathInfo();
    error InvalidToken();

    // Queue Contract Errors
    error InvalidAsset();

    // Getter Errors
    error InvalidVaultAddress();
    error InvalidVaultAsset();
    error InvalidVaultEmissions();
    error MarketNotExist();
    error InvalidVaultController();
    error InvalidVaultCounterParty();
    error InvalidTreasury();

    // Position Sizer
    error InvalidWeightStrategy();
    error ProportionUnassigned();
    error LengthMismatch();
    error NoValidThreshold();

    // DEX Errors
    error InvalidPath();
    error InvalidCaller();
    error InvalidMinOut(uint256 amountOut);
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

pragma solidity 0.8.18;

interface IEarthquake {
    function asset() external view returns (address asset);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function depositETH(uint256 pid, address to) external payable;

    function epochs() external view returns (uint256[] memory);

    function epochs(uint256 i) external view returns (uint256);

    function epochsLength() external view returns (uint256);

    function getEpochsLength() external view returns (uint256);

    function idEpochBegin(uint256 id) external view returns (uint256);

    function idEpochEnded(uint256 id) external view returns (bool);

    function getVaults(uint256 pid) external view returns (address[2] memory);

    function emissionsToken() external view returns (address emissionsToken);

    function controller() external view returns (address controller);

    function treasury() external view returns (address treasury);

    function counterPartyVault() external view returns (address counterParty);

    function totalSupply(uint256 id) external view returns (uint256);

    function factory() external view returns (address factory);

    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function getEpochConfig(
        uint256
    ) external view returns (uint40, uint40, uint40);

    function getEpochDepositFee(
        uint256 id,
        uint256 assets
    ) external view returns (uint256, uint256);
}

pragma solidity 0.8.18;

interface IEarthquakeFactory {
    function asset(uint256 _marketId) external view returns (address asset);

    function getVaults(uint256) external view returns (address[] memory);
}