// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/pool/IRigoblockV3PoolActions.sol";
import "./interfaces/pool/IRigoblockV3PoolEvents.sol";
import "./interfaces/pool/IRigoblockV3PoolFallback.sol";
import "./interfaces/pool/IRigoblockV3PoolImmutable.sol";
import "./interfaces/pool/IRigoblockV3PoolInitializer.sol";
import "./interfaces/pool/IRigoblockV3PoolOwnerActions.sol";
import "./interfaces/pool/IRigoblockV3PoolState.sol";
import "./interfaces/pool/IStorageAccessible.sol";

/// @title Rigoblock V3 Pool Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3Pool is
    IERC20,
    IRigoblockV3PoolImmutable,
    IRigoblockV3PoolEvents,
    IRigoblockV3PoolFallback,
    IRigoblockV3PoolInitializer,
    IRigoblockV3PoolActions,
    IRigoblockV3PoolOwnerActions,
    IRigoblockV3PoolState,
    IStorageAccessible
{

}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity 0.8.17;

import "../IRigoblockV3Pool.sol";
import {LibSanitize} from "../../utils/libSanitize/LibSanitize.sol";
import {IAuthority as Authority} from "../interfaces/IAuthority.sol";

import {IPoolRegistry} from "../interfaces/IPoolRegistry.sol";

/// @title Pool Registry - Allows registration of pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract PoolRegistry is IPoolRegistry {
    /// @inheritdoc IPoolRegistry
    address public override authority;

    /// @inheritdoc IPoolRegistry
    address public override rigoblockDao;

    mapping(address => bytes32) private _mapIdByAddress;

    mapping(address => PoolMeta) private _poolMetaByAddress;

    /*
     * MODIFIERS
     */
    modifier onlyWhitelistedFactory() {
        require(Authority(authority).isWhitelistedFactory(msg.sender), "REGISTRY_FACTORY_NOT_WHITELISTED_ERROR");
        _;
    }

    modifier onlyPoolOperator(address pool) {
        require(IRigoblockV3Pool(payable(pool)).owner() == msg.sender, "REGISTRY_CALLER_IS_NOT_POOL_OWNER_ERROR");
        _;
    }

    modifier onlyRigoblockDao() {
        require(msg.sender == rigoblockDao, "REGISTRY_CALLER_NOT_DAO_ERROR");
        _;
    }

    modifier whenAddressFree(address pool) {
        require(_mapIdByAddress[pool] == bytes32(0), "REGISTRY_ADDRESS_ALREADY_TAKEN_ERROR");
        _;
    }

    modifier whenPoolRegistered(address pool) {
        require(_mapIdByAddress[pool] != bytes32(0), "REGISTRY_ADDRESS_NOT_REGISTERED_ERROR");
        _;
    }

    constructor(address newAuthority, address newRigoblockDao) {
        authority = newAuthority;
        rigoblockDao = newRigoblockDao;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @inheritdoc IPoolRegistry
    function register(
        address pool,
        string calldata name,
        string calldata symbol,
        bytes32 poolId
    ) external override onlyWhitelistedFactory whenAddressFree(pool) {
        _assertValidNameAndSymbol(name, symbol);
        _mapIdByAddress[pool] = poolId;

        emit Registered(
            msg.sender, // proxy factory
            pool,
            bytes32(bytes(name)),
            bytes32(bytes(symbol)),
            poolId
        );
    }

    /// @inheritdoc IPoolRegistry
    function setAuthority(address newAuthority) external override onlyRigoblockDao {
        require(newAuthority != authority, "REGISTRY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newAuthority), "REGISTRY_NEW_AUTHORITY_NOT_CONTRACT_ERROR");
        authority = newAuthority;
        emit AuthorityChanged(newAuthority);
    }

    /// @inheritdoc IPoolRegistry
    function setMeta(
        address pool,
        bytes32 key,
        bytes32 value
    ) external override onlyPoolOperator(pool) whenPoolRegistered(pool) {
        _poolMetaByAddress[pool].meta[key] = value;
        emit MetaChanged(pool, key, value);
    }

    /// @inheritdoc IPoolRegistry
    function setRigoblockDao(address newRigoblockDao) external override onlyRigoblockDao {
        require(newRigoblockDao != rigoblockDao, "REGISTRY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newRigoblockDao), "REGISTRY_NEW_DAO_NOT_CONTRACT_ERROR");
        rigoblockDao = newRigoblockDao;
        emit RigoblockDaoChanged(newRigoblockDao);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IPoolRegistry
    function getPoolIdFromAddress(address pool) external view override returns (bytes32 poolId) {
        poolId = _mapIdByAddress[pool];
    }

    /// @inheritdoc IPoolRegistry
    function getMeta(address pool, bytes32 key) external view override returns (bytes32 poolMeta) {
        return _poolMetaByAddress[pool].meta[key];
    }

    /*
     * INTERNAL FUNCTIONS
     */
    function _assertValidNameAndSymbol(string memory name, string memory symbol) internal pure {
        uint256 nameLength = bytes(name).length;
        // we always want to keep name lenght below 31, for logging bytes32 while making sure that the name toString
        // is stored at slot location and not in the pseudorandom slot allocated to strings longer than 31 bytes.
        require(nameLength >= uint256(4) && nameLength <= uint256(31), "REGISTRY_NAME_LENGTH_ERROR");

        uint256 symbolLength = bytes(symbol).length;
        require(symbolLength >= uint256(3) && symbolLength <= uint256(5), "REGISTRY_SYMBOL_LENGTH_ERROR");

        // check valid characters in name and symbol
        LibSanitize.assertIsValidCheck(name);
        LibSanitize.assertIsValidCheck(symbol);
        LibSanitize.assertIsUppercase(symbol);
    }

    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.7.0 <0.9.0;

/// @title Authority Interface - Allows interaction with the Authority contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IAuthority {
    /// @notice Adds a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionAdded(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes a permission for a role.
    /// @dev Possible roles are Role.ADAPTER, Role.FACTORY, Role.WHITELISTER
    /// @param from Address of the  method caller.
    /// @param target Address of the approved wallet.
    /// @param permissionType Enum type of permission.
    event PermissionRemoved(address indexed from, address indexed target, uint8 indexed permissionType);

    /// @notice Removes an approved method.
    /// @dev Removes a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event RemovedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    /// @notice Approves a new method.
    /// @dev Adds a mapping of method selector to adapter according to eip1967.
    /// @param from Address of the  method caller.
    /// @param adapter  Address of the adapter.
    /// @param selector Bytes4 of the method signature.
    event WhitelistedMethod(address indexed from, address indexed adapter, bytes4 indexed selector);

    enum Role {
        ADAPTER,
        FACTORY,
        WHITELISTER
    }

    /// @notice Mapping of permission type to bool.
    /// @param Mapping of type of permission to bool is authorized.
    struct Permission {
        mapping(Role => bool) authorized;
    }

    /// @notice Allows a whitelister to whitelist a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    /// @notice We do not save list of approved as better queried by events.
    function addMethod(bytes4 selector, address adapter) external;

    /// @notice Allows a whitelister to remove a method.
    /// @param selector Bytes4 hex of the method selector.
    /// @param adapter Address of the adapter implementing the method.
    function removeMethod(bytes4 selector, address adapter) external;

    /// @notice Allows owner to set extension adapter address.
    /// @param adapter Address of the target adapter.
    /// @param isWhitelisted Bool whitelisted.
    function setAdapter(address adapter, bool isWhitelisted) external;

    /// @notice Allows an admin to set factory permission.
    /// @param factory Address of the target factory.
    /// @param isWhitelisted Bool whitelisted.
    function setFactory(address factory, bool isWhitelisted) external;

    /// @notice Allows the owner to set whitelister permission.
    /// @param whitelister Address of the whitelister.
    /// @param isWhitelisted Bool whitelisted.
    /// @notice Whitelister permission is required to approve methods in extensions adapter.
    function setWhitelister(address whitelister, bool isWhitelisted) external;

    /// @notice Returns the address of the adapter associated to the signature.
    /// @param selector Hex of the method signature.
    /// @return Address of the adapter.
    function getApplicationAdapter(bytes4 selector) external view returns (address);

    /// @notice Provides whether a factory is whitelisted.
    /// @param target Address of the target factory.
    /// @return Bool is whitelisted.
    function isWhitelistedFactory(address target) external view returns (bool);

    /// @notice Provides whether an address is whitelister.
    /// @param target Address of the target whitelister.
    /// @return Bool is whitelisted.
    function isWhitelister(address target) external view returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    /// @notice Emitted when a token is transferred.
    /// @param from Address transferring the tokens.
    /// @param to Address receiving the tokens.
    /// @param value Number of token units.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when a token holder sets and approval.
    /// @param owner Address of the account setting the approval.
    /// @param spender Address of the allowed account.
    /// @param value Number of approved units.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Transfers token from holder to another address.
    /// @param to Address to send tokens to.
    /// @param value Number of token units to send.
    /// @return success Bool the transaction was successful.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice Allows spender to transfer tokens from the holder.
    /// @param from Address of the token holder.
    /// @param to Address to send tokens to.
    /// @param value Number of units to transfer.
    /// @return success Bool the transaction was successful.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice Allows a holder to approve a spender.
    /// @param spender Address of the token spender.
    /// @param value Number of units to be approved.
    /// @return success Bool the transaction was successful.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice Returns token balance for an address.
    /// @param who Address to query balance for.
    /// @return Number of units held.
    function balanceOf(address who) external view returns (uint256);

    /// @notice Returns token allowance of an address to another address.
    /// @param owner Address of token hodler.
    /// @param spender Address of the token spender.
    /// @return Number of allowed units.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns token decimals.
    /// @return Uint8 number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.7.0 <0.9.0;

/// @title Pool Registry Interface - Allows external interaction with pool registry.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IPoolRegistry {
    /// @notice Mapping of pool meta by pool key.
    /// @param meta Mapping of bytes32 key to bytes32 meta.
    struct PoolMeta {
        mapping(bytes32 => bytes32) meta;
    }

    /// @notice Emitted when Rigoblock Dao updates authority address.
    /// @param authority Address of the new authority contract.
    event AuthorityChanged(address indexed authority);

    /// @notice Emitted when pool owner updates meta data for its pool.
    /// @param pool Address of the pool.
    /// @param key Bytes32 key for indexing.
    /// @param value Bytes32 of the value associated with the key.
    event MetaChanged(address indexed pool, bytes32 indexed key, bytes32 value);

    /// @notice Emitted when a new pool is registered in registry.
    /// @param group Address of the pool factory.
    /// @param pool Address of the registered pool.
    /// @param name String name of the pool.
    /// @param symbol String name of the pool.
    /// @param id Bytes32 id of the pool.
    event Registered(
        address indexed group,
        address pool,
        bytes32 indexed name, // client can prune sybil pools
        bytes32 indexed symbol,
        bytes32 id
    );

    /// @notice Emitted when rigoblock Dao address is updated.
    /// @param rigoblockDao New Dao address.
    event RigoblockDaoChanged(address indexed rigoblockDao);

    /// @notice Returns the address of the Rigoblock authority contract.
    /// @return Address of the authority contract.
    function authority() external view returns (address);

    /// @notice Returns the address of the Rigoblock Dao.
    /// @return Address of the Rigoblock Dao.
    function rigoblockDao() external view returns (address);

    /// @notice Allows a factory which is an authority to register a pool.
    /// @param pool Address of the pool.
    /// @param name String name of the pool (31 characters/bytes or less).
    /// @param symbol String symbol of the pool (3 to 5 characters/bytes).
    /// @param poolId Bytes32 of the pool id.
    function register(
        address pool,
        string calldata name,
        string calldata symbol,
        bytes32 poolId
    ) external;

    /// @notice Allows Rigoblock governance to update authority.
    /// @param authority Address of the authority contract.
    function setAuthority(address authority) external;

    /// @notice Allows pool owner to set metadata for a pool.
    /// @param pool Address of the pool.
    /// @param key Bytes32 of the key.
    /// @param value Bytes32 of the value.
    function setMeta(
        address pool,
        bytes32 key,
        bytes32 value
    ) external;

    /// @notice Allows Rigoblock Dao to update its address.
    /// @dev Creates internal record.
    /// @param newRigoblockDao Address of the Rigoblock Dao.
    function setRigoblockDao(address newRigoblockDao) external;

    /// @notice Returns metadata for a given pool.
    /// @param pool Address of the pool.
    /// @param key Bytes32 key.
    /// @return poolMeta Meta by key.
    function getMeta(address pool, bytes32 key) external view returns (bytes32 poolMeta);

    /// @notice Returns the id of a pool from its address.
    /// @param pool Address of the pool.
    /// @return poolId bytes32 id of the pool.
    function getPoolIdFromAddress(address pool) external view returns (bytes32 poolId);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Actions Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolActions {
    /// @notice Allows a user to mint pool tokens on behalf of an address.
    /// @param recipient Address receiving the tokens.
    /// @param amountIn Amount of base tokens.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return recipientAmount Number of tokens minted to recipient.
    function mint(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable returns (uint256 recipientAmount);

    /// @notice Allows a pool holder to burn pool tokens.
    /// @param amountIn Number of tokens to burn.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return netRevenue Net amount of burnt pool tokens.
    function burn(uint256 amountIn, uint256 amountOutMin) external returns (uint256 netRevenue);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Events - Declares events of the pool contract.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolEvents {
    /// @notice Emitted when a new pool is initialized.
    /// @dev Pool is initialized at new pool creation.
    /// @param group Address of the factory.
    /// @param owner Address of the owner.
    /// @param baseToken Address of the base token.
    /// @param name String name of the pool.
    /// @param symbol String symbol of the pool.
    event PoolInitialized(
        address indexed group,
        address indexed owner,
        address indexed baseToken,
        string name,
        bytes8 symbol
    );

    /// @notice Emitted when new owner is set.
    /// @param old Address of the previous owner.
    /// @param current Address of the new owner.
    event NewOwner(address indexed old, address indexed current);

    /// @notice Emitted when pool operator updates NAV.
    /// @param poolOperator Address of the pool owner.
    /// @param pool Address of the pool.
    /// @param unitaryValue Value of 1 token in wei units.
    event NewNav(address indexed poolOperator, address indexed pool, uint256 unitaryValue);

    /// @notice Emitted when pool operator sets new mint fee.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param transactionFee Number of the new fee in wei.
    event NewFee(address indexed pool, address indexed who, uint16 transactionFee);

    /// @notice Emitted when pool operator updates fee collector address.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param feeCollector Address of the new fee collector.
    event NewCollector(address indexed pool, address indexed who, address feeCollector);

    /// @notice Emitted when pool operator updates minimum holding period.
    /// @param pool Address of the pool.
    /// @param minimumPeriod Number of seconds.
    event MinimumPeriodChanged(address indexed pool, uint48 minimumPeriod);

    /// @notice Emitted when pool operator updates the mint/burn spread.
    /// @param pool Address of the pool.
    /// @param spread Number of the spread in basis points.
    event SpreadChanged(address indexed pool, uint16 spread);

    /// @notice Emitted when pool operator sets a kyc provider.
    /// @param pool Address of the pool.
    /// @param kycProvider Address of the kyc provider.
    event KycProviderSet(address indexed pool, address indexed kycProvider);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Fallback Interface - Interface of the fallback method.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolFallback {
    /// @notice Delegate calls to pool extension.
    /// @dev Delegatecall restricted to owner, staticcall accessible by everyone.
    /// @dev Restricting delegatecall to owner effectively locks direct calls.
    fallback() external payable;

    /// @notice Allows transfers to pool.
    /// @dev Prevents accidental transfer to implementation contract.
    receive() external payable;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Immutable - Interface of the pool storage.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolImmutable {
    /// @notice Returns a string of the pool version.
    /// @return String of the pool implementation version.
    function VERSION() external view returns (string memory);

    /// @notice Returns the address of the authority contract.
    /// @return Address of the authority contract.
    function authority() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Initializer Interface - Allows initializing a pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolInitializer {
    /// @notice Initializes to pool storage.
    /// @dev Pool can only be initialized at creation, meaning this method cannot be called directly to implementation.
    function initializePool() external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Owner Actions Interface - Interface of the owner methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolOwnerActions {
    /// @notice Allows owner to decide where to receive the fee.
    /// @param feeCollector Address of the fee receiver.
    function changeFeeCollector(address feeCollector) external;

    /// @notice Allows pool owner to change the minimum holding period.
    /// @param minPeriod Time in seconds.
    function changeMinPeriod(uint48 minPeriod) external;

    /// @notice Allows pool owner to change the mint/burn spread.
    /// @param newSpread Number between 0 and 1000, in basis points.
    function changeSpread(uint16 newSpread) external;

    /// @notice Allows pool owner to set/update the user whitelist contract.
    /// @dev Kyc provider can be set to null, removing user whitelist requirement.
    /// @param kycProvider Address if the kyc provider.
    function setKycProvider(address kycProvider) external;

    /// @notice Allows pool owner to set a new owner address.
    /// @dev Method restricted to owner.
    /// @param newOwner Address of the new owner.
    function setOwner(address newOwner) external;

    /// @notice Allows pool owner to set the transaction fee.
    /// @param transactionFee Value of the transaction fee in basis points.
    function setTransactionFee(uint16 transactionFee) external;

    /// @notice Allows pool owner to set the pool price.
    /// @param unitaryValue Value of 1 token in wei units.
    function setUnitaryValue(uint256 unitaryValue) external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool State - Returns the pool view methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolState {
    /// @notice Returned pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string to facilitating client view.
    /// @param name String of the pool name (max 32 characters).
    /// @param symbol String of the pool symbol (from 3 to 5 characters).
    /// @param decimals Uint8 decimals.
    /// @param owner Address of the pool operator.
    /// @param baseToken Address of the base token of the pool (0 for base currency).
    struct ReturnedPool {
        string name;
        string symbol;
        uint8 decimals;
        address owner;
        address baseToken;
    }

    /// @notice Returns the struct containing pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string in the returned struct, unlocked is omitted as alwasy true.
    /// @return ReturnedPool struct.
    function getPool() external view returns (ReturnedPool memory);

    /// @notice Pool variables.
    /// @param minPeriod Minimum holding period in seconds.
    /// @param spread Value of spread in basis points (from 0 to +-10%).
    /// @param transactionFee Value of transaction fee in basis points (from 0 to 1%).
    /// @param feeCollector Address of the fee receiver.
    /// @param kycProvider Address of the kyc provider.
    struct PoolParams {
        uint48 minPeriod;
        uint16 spread;
        uint16 transactionFee;
        address feeCollector;
        address kycProvider;
    }

    /// @notice Returns the struct compaining pool parameters.
    /// @return PoolParams struct.
    function getPoolParams() external view returns (PoolParams memory);

    /// @notice Pool tokens.
    /// @param unitaryValue A token's unitary value in base token.
    /// @param totalSupply Number of total issued pool tokens.
    struct PoolTokens {
        uint256 unitaryValue;
        uint256 totalSupply;
    }

    /// @notice Returns the struct containing pool tokens info.
    /// @return PoolTokens struct.
    function getPoolTokens() external view returns (PoolTokens memory);

    /// @notice Returns the aggregate pool generic storage.
    /// @return poolInitParams The pool's initialization parameters.
    /// @return poolVariables The pool's variables.
    /// @return poolTokensInfo The pool's tokens info.
    function getPoolStorage()
        external
        view
        returns (
            ReturnedPool memory poolInitParams,
            PoolParams memory poolVariables,
            PoolTokens memory poolTokensInfo
        );

    /// @notice Pool holder account.
    /// @param userBalance Number of tokens held by user.
    /// @param activation Time when tokens become active.
    struct UserAccount {
        uint208 userBalance;
        uint48 activation;
    }

    /// @notice Returns a pool holder's account struct.
    /// @return UserAccount struct.
    function getUserAccount(address _who) external view returns (UserAccount memory);

    /// @notice Returns a string of the pool name.
    /// @dev Name maximum length 31 bytes.
    /// @return String of the name.
    function name() external view returns (string memory);

    /// @notice Returns the address of the owner.
    /// @return Address of the owner.
    function owner() external view returns (address);

    /// @notice Returns a string of the pool symbol.
    /// @return String of the symbol.
    function symbol() external view returns (string memory);

    /// @notice Returns the total amount of issued tokens for this pool.
    /// @return Number of total issued tokens.
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

/// @title IStorageAccessible - generic base interface that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
interface IStorageAccessible {
    /// @notice Reads `length` bytes of storage in the currents contract.
    /// @param offset - the offset in the current contract's storage in words to start reading from.
    /// @param length - the number of words (32 bytes) of data to read.
    /// @return Bytes string of the bytes that were read.
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /// @notice Reads bytes of storage at different storage locations.
    /// @dev Returns a string with values regarless of where they are stored, i.e. variable, mapping or struct.
    /// @param slots The array of storage slots to query into.
    /// @return Bytes string composite of different storage locations' value.
    function getStorageSlotsAt(uint256[] memory slots) external view returns (bytes memory);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Lib Sanitize - Sanitize strings in smart contracts.
/// @author Gabriele Rigo - <[email protected]>
library LibSanitize {
    function assertIsValidCheck(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        require(bStr[0] != bytes1(uint8(32)), "LIBSANITIZE_SPACE_AT_BEGINNING_ERROR");
        require(bStr[arrayLength - 1] != bytes1(uint8(32)), "LIBSANITIZE_SPACE_AT_END_ERROR");
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                (bStr[i] < bytes1(uint8(48)) ||
                    bStr[i] > bytes1(uint8(122)) ||
                    (bStr[i] > bytes1(uint8(57)) && bStr[i] < bytes1(uint8(65))) ||
                    (bStr[i] > bytes1(uint8(90)) && bStr[i] < bytes1(uint8(97)))) && bStr[i] != bytes1(uint8(32))
            ) revert("LIBSANITIZE_SPECIAL_CHARACTER_ERROR");
        }
    }

    function assertIsLowercase(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if ((bStr[i] >= bytes1(uint8(65))) && (bStr[i] <= bytes1(uint8(90))))
                revert("LIBSANITIZE_LOWERCASE_CHARACTER_ERROR");
        }
    }

    function assertIsUppercase(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if ((bStr[i] >= bytes1(uint8(97))) && (bStr[i] <= bytes1(uint8(122))))
                revert("LIBSANITIZE_UPPERCASE_CHARACTER_ERROR");
        }
    }
}