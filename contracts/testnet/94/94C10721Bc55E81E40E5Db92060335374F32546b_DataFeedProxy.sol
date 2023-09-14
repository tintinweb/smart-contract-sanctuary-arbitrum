// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistryAdminned is ISelfMulticall {
    function accessControlRegistry() external view returns (address);

    function adminRoleDescription() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlRegistryAdminned.sol";

interface IAccessControlRegistryAdminnedWithManager is
    IAccessControlRegistryAdminned
{
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDapiServer.sol";
import "./IBeaconUpdatesWithSignedData.sol";

interface IApi3ServerV1 is IOevDapiServer, IBeaconUpdatesWithSignedData {
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function dataFeeds(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IBeaconUpdatesWithSignedData is IDataFeedServer {
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bytes32 beaconId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../access-control-registry/interfaces/IAccessControlRegistryAdminnedWithManager.sol";
import "./IDataFeedServer.sol";

interface IDapiServer is
    IAccessControlRegistryAdminnedWithManager,
    IDataFeedServer
{
    event SetDapiName(
        bytes32 indexed dataFeedId,
        bytes32 indexed dapiName,
        address sender
    );

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function dapiNameSetterRole() external view returns (bytes32);

    function dapiNameHashToDataFeedId(
        bytes32 dapiNameHash
    ) external view returns (bytes32 dataFeedId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/IExtendedSelfMulticall.sol";

interface IDataFeedServer is IExtendedSelfMulticall {
    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) external returns (bytes32 beaconSetId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDataFeedServer.sol";
import "./IDapiServer.sol";

interface IOevDapiServer is IOevDataFeedServer, IDapiServer {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IOevDataFeedServer is IDataFeedServer {
    event UpdatedOevProxyBeaconWithSignedData(
        bytes32 indexed beaconId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedOevProxyBeaconSetWithSignedData(
        bytes32 indexed beaconSetId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event Withdrew(
        address indexed oevProxy,
        address oevBeneficiary,
        uint256 amount
    );

    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable;

    function withdraw(address oevProxy) external;

    function oevProxyToBalance(
        address oevProxy
    ) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDataFeedProxy.sol";
import "../interfaces/IApi3ServerV1.sol";

/// @title An immutable proxy contract that is used to read a specific data
/// feed (Beacon or Beacon set) of a specific Api3ServerV1 contract
/// @notice In an effort to reduce the bytecode of this contract, its
/// constructor arguments are validated by ProxyFactory, rather than
/// internally. If you intend to deploy this contract without using
/// ProxyFactory, you are recommended to implement an equivalent validation.
/// @dev See DapiProxy.sol for comments about usage
contract DataFeedProxy is IDataFeedProxy {
    /// @notice Api3ServerV1 address
    address public immutable override api3ServerV1;
    /// @notice Data feed ID
    bytes32 public immutable override dataFeedId;

    /// @param _api3ServerV1 Api3ServerV1 address
    /// @param _dataFeedId Data feed (Beacon or Beacon set) ID
    constructor(address _api3ServerV1, bytes32 _dataFeedId) {
        api3ServerV1 = _api3ServerV1;
        dataFeedId = _dataFeedId;
    }

    /// @notice Reads the data feed that this proxy maps to
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function read()
        external
        view
        virtual
        override
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = IApi3ServerV1(api3ServerV1).readDataFeedWithId(
            dataFeedId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProxy.sol";

interface IDataFeedProxy is IProxy {
    function dataFeedId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISelfMulticall.sol";

interface IExtendedSelfMulticall is ISelfMulticall {
    function getChainId() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function containsBytecode(address account) external view returns (bool);

    function getBlockNumber() external view returns (uint256);

    function getBlockTimestamp() external view returns (uint256);

    function getBlockBasefee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISelfMulticall {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory returndata);

    function tryMulticall(
        bytes[] calldata data
    ) external returns (bool[] memory successes, bytes[] memory returndata);
}