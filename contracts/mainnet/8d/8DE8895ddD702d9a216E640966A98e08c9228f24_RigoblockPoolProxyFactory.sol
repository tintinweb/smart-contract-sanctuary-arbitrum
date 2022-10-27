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

// SPDX-License-Identifier: Apache-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IRigoblockPoolProxy {
    /// @notice Emitted when implementation written to proxy storage.
    /// @dev Emitted also at first variable initialization.
    /// @param newImplementation Address of the new implementation.
    event Upgraded(address indexed newImplementation);
}

// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2017-2022 RigoBlock, Rigo Investment Sagl, Rigo Intl.

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

/// @title Pool Proxy Factory Interface - Allows external interaction with Pool Proxy Factory.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockPoolProxyFactory {
    /// @notice Emitted when a new pool is created.
    /// @param poolAddress Address of the new pool.
    event PoolCreated(address poolAddress);

    /// @notice Emitted when a new implementation is set by the Rigoblock Dao.
    /// @param implementation Address of the new implementation.
    event Upgraded(address indexed implementation);

    /// @notice Emitted when registry address is upgraded by the Rigoblock Dao.
    /// @param registry Address of the new registry.
    event RegistryUpgraded(address indexed registry);

    /// @notice Returns the implementation address for the pool proxies.
    /// @return Address of the implementation.
    function implementation() external view returns (address);

    /// @notice Creates a new Rigoblock pool.
    /// @param name String of the name.
    /// @param symbol String of the symbol.
    /// @param baseToken Address of the base token.
    /// @return newPoolAddress Address of the new pool.
    /// @return poolId Id of the new pool.
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external returns (address newPoolAddress, bytes32 poolId);

    /// @notice Allows Rigoblock Dao to update factory pool implementation.
    /// @param newImplementation Address of the new implementation contract.
    function setImplementation(address newImplementation) external;

    /// @notice Allows owner to update the registry.
    /// @param newRegistry Address of the new registry.
    function setRegistry(address newRegistry) external;

    /// @notice Returns the address of the pool registry.
    /// @return Address of the registry.
    function getRegistry() external view returns (address);

    /// @notice Pool initialization parameters.
    /// @params name String of the name (max 31 characters).
    /// @params symbol bytes8 symbol.
    /// @params owner Address of the owner.
    /// @params baseToken Address of the base token.
    struct Parameters {
        string name;
        bytes8 symbol;
        address owner;
        address baseToken;
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view returns (Parameters memory);
}

// SPDX-License-Identifier: Apache-2.0-or-later
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

import "../interfaces/IRigoblockPoolProxy.sol";
import "../interfaces/IRigoblockPoolProxyFactory.sol";

/// @title RigoblockPoolProxy - Proxy contract forwards calls to the implementation address returned by the admin.
/// @author Gabriele Rigo - <[email protected]>
contract RigoblockPoolProxy is IRigoblockPoolProxy {
    // implementation slot is used to store implementation address, a contract which implements the pool logic.
    // Reduced deployment cost by using internal variable.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Sets address of implementation contract.
    constructor() payable {
        // store implementation address in implementation slot value
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        address implementation = IRigoblockPoolProxyFactory(msg.sender).implementation();
        getImplementation().implementation = implementation;
        emit Upgraded(implementation);

        // initialize pool
        // abi.encodeWithSelector(IRigoblockPool.initializePool.selector)
        (, bytes memory returnData) = implementation.delegatecall(abi.encodeWithSelector(0x250e6de0));

        // we must assert initialization didn't fail, otherwise it could fail silently and still deploy the pool.
        require(returnData.length == 0, "POOL_INITIALIZATION_FAILED_ERROR");
    }

    /* solhint-disable no-complex-fallback */
    /// @notice Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        address implementation = getImplementation().implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /* solhint-enable no-complex-fallback */

    /// @notice Implementation slot is accessed directly.
    /// @dev Saves gas compared to using storage slot library.
    /// @param implementation Address of the implementation.
    struct ImplementationSlot {
        address implementation;
    }

    /// @notice Method to read/write from/to implementation slot.
    /// @return s Storage slot of the pool implementation.
    function getImplementation() private pure returns (ImplementationSlot storage s) {
        assembly {
            s.slot := _IMPLEMENTATION_SLOT
        }
    }
}

// SPDX-License-Identifier: Apache-2.0-or-later
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

pragma solidity 0.8.17;

import "./RigoblockPoolProxy.sol";
import {IPoolRegistry as PoolRegistry} from "../interfaces/IPoolRegistry.sol";
import "../interfaces/IRigoblockPoolProxyFactory.sol";

/// @title Rigoblock Pool Proxy Factory contract - allows creation of new Rigoblock pools.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract RigoblockPoolProxyFactory is IRigoblockPoolProxyFactory {
    /// @inheritdoc IRigoblockPoolProxyFactory
    address public override implementation;

    address private _registry;

    Parameters private _parameters;

    modifier onlyRigoblockDao() {
        require(PoolRegistry(getRegistry()).rigoblockDao() == msg.sender, "FACTORY_CALLER_NOT_DAO_ERROR");
        _;
    }

    constructor(address newImplementation, address registry) {
        implementation = newImplementation;
        _registry = registry;
    }

    /*
     * PUBLIC FUNCTIONS
     */
    /// @inheritdoc IRigoblockPoolProxyFactory
    function createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) external override returns (address newPoolAddress, bytes32 poolId) {
        (bytes32 newPoolId, RigoblockPoolProxy proxy) = _createPool(name, symbol, baseToken);
        newPoolAddress = address(proxy);
        poolId = newPoolId;
        try PoolRegistry(getRegistry()).register(newPoolAddress, name, symbol, poolId) {
            emit PoolCreated(newPoolAddress);
        } catch Error(string memory reason) {
            revert(reason);
        } catch (bytes memory returnData) {
            revert(string(returnData));
        }
    }

    /// @inheritdoc IRigoblockPoolProxyFactory
    function setImplementation(address newImplementation) external override onlyRigoblockDao {
        require(newImplementation != implementation, "FACTORY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newImplementation), "FACTORY_NEW_IMPLEMENTATION_NOT_CONTRACT_ERROR");
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    /// @inheritdoc IRigoblockPoolProxyFactory
    function setRegistry(address newRegistry) external override onlyRigoblockDao {
        require(newRegistry != getRegistry(), "FACTORY_SAME_INPUT_ADDRESS_ERROR");
        require(_isContract(newRegistry), "FACTORY_NEW_REGISTRY_NOT_CONTRACT_ERROR");
        _registry = newRegistry;
        emit RegistryUpgraded(newRegistry);
    }

    /// @notice Returns the pool initialization parameters at proxy deploy.
    /// @return Tuple of the pool parameters.
    function parameters() external view override returns (Parameters memory) {
        return _parameters;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IRigoblockPoolProxyFactory
    function getRegistry() public view override returns (address) {
        return _registry;
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Creates a pool and routes to eventful.
    /// @param name String of the name.
    /// @param  symbol String of the symbol.
    /// @param  baseToken Address of the base token.
    function _createPool(
        string calldata name,
        string calldata symbol,
        address baseToken
    ) internal returns (bytes32 salt, RigoblockPoolProxy newProxy) {
        // we omit the encoding params in the constructor in order to guarantee same address for name and owner
        salt = keccak256(abi.encode(name, msg.sender));

        // we write to storage to allow proxy to read initialization parameters
        _parameters = Parameters({name: name, symbol: bytes8(bytes(symbol)), owner: msg.sender, baseToken: baseToken});

        // constructor is null to guarantee same create2 deployed address
        try new RigoblockPoolProxy{salt: salt}() returns (RigoblockPoolProxy proxy) {
            newProxy = proxy;
        } catch Error(string memory revertReason) {
            revert(revertReason);
        } catch (bytes memory) {
            revert("FACTORY_CREATE2_FAILED_ERROR");
        }

        delete _parameters;
    }

    /// @dev Returns whether an address is a contract.
    /// @return Bool target address has code.
    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}