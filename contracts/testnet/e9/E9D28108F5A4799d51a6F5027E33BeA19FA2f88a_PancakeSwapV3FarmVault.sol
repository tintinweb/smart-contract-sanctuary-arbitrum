// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FarmExecutionUpkeepInterface} from "./FarmExecutionUpkeepInterface.sol";

abstract contract FarmExecutionUpkeep is FarmExecutionUpkeepInterface {
    function checkUpkeep(
        bytes calldata checkData_
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = _shouldPerformUpkeep();

        if (!upkeepNeeded) {
            return (false, performData);
        }

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData_) external override {
        if (!_shouldPerformUpkeep()) {
            return;
        }

        _performUpkeep(performData_);
    }

    function _performUpkeep(bytes calldata performData_) internal virtual;

    function _shouldPerformUpkeep() internal view virtual returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface FarmExecutionUpkeepInterface is AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {MiviaManagerInterface} from "../interfaces/MiviaManagerInterface.sol";

interface FarmManagerInterface is IERC165 {
    function miviaManager()
        external
        view
        returns (MiviaManagerInterface miviaManagerContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {MiviaManagerInterface} from "../interfaces/MiviaManagerInterface.sol";
import {FarmManagerInterface} from "./FarmManagerInterface.sol";
import {StrategyInterface} from "./StrategyInterface.sol";
import {FarmVaultInterface} from "./FarmVaultInterface.sol";
import {FarmExecutionUpkeep} from "./FarmExecutionUpkeep.sol";

abstract contract FarmVault is FarmVaultInterface, ERC165, FarmExecutionUpkeep {
    error FarmVault__InvalidFarmManager();
    error FarmVault__StrategyAlreadySet();
    error FarmVault__StrategyNotSet();
    error FarmVault__NotValidStrategy();

    MiviaManagerInterface public immutable miviaManager;
    FarmManagerInterface public immutable farmManager;
    StrategyInterface public strategy;

    modifier isStrategySet() {
        if (address(strategy) == address(0)) revert FarmVault__StrategyNotSet();
        _;
    }

    constructor(address farmManager_) {
        // if (
        //     !FarmManagerInterface(farmManager_).supportsInterface(
        //         type(FarmManagerInterface).interfaceId
        //     )
        // ) revert FarmVault__InvalidFarmManager();
        // farmManager = FarmManagerInterface(farmManager_);
        // miviaManager = farmManager.miviaManager();
        farmManager = FarmManagerInterface(address(0));
        miviaManager = MiviaManagerInterface(address(0));
    }

    function setStrategy(address strategyAddress_) external {
        if (address(strategy) != address(0))
            revert FarmVault__StrategyAlreadySet();
        if (
            !StrategyInterface(strategyAddress_).supportsInterface(
                type(StrategyInterface).interfaceId
            )
        ) revert FarmVault__NotValidStrategy();

        strategy = StrategyInterface(strategyAddress_);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(FarmVaultInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {StrategyInterface} from "./StrategyInterface.sol";

interface FarmVaultInterface is IERC165 {
    function setStrategy(address strategyAddress) external;

    function strategy() external returns (StrategyInterface strategyContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface StrategyInterface is IERC165 {
    function checkRebalance() external view returns (bool);

    function rebalance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PancakeSwapV3FarmVaultInterface} from "./PancakeSwapV3FarmVaultInterface.sol";
import {FarmVault, IERC165} from "../../farms/FarmVault.sol";

contract PancakeSwapV3FarmVault is PancakeSwapV3FarmVaultInterface, FarmVault {
    constructor(address farmManager_) FarmVault(farmManager_) {}

    uint256 public counter;

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(FarmVault, IERC165) returns (bool) {
        return
            interfaceId == type(PancakeSwapV3FarmVaultInterface).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// rebalance strategy
    function _performUpkeep(
        bytes calldata performData_
    ) internal virtual override {
        counter++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../interfaces/FarmVaultInterface.sol";

interface PancakeSwapV3FarmVaultInterface is FarmVaultInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../farms/FarmVaultInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../mivia/MiviaManagerInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface MiviaManagerInterface is IERC165 {}