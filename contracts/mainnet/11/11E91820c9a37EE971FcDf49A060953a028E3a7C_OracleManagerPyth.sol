// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IOracle is INameVersion {

    function symbol() external view returns (string memory);

    function symbolId() external view returns (bytes32);

    function timestamp() external view returns (uint256);

    function value() external view returns (uint256);

    function getValue() external view returns (uint256);

    function getValueWithJump() external returns (uint256 val, int256 jump);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManagerPyth is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function timestamp(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function getValueWithJump(bytes32 symbolId) external returns (uint256 val, int256 jump);

    function lastSignatureTimestamp(bytes32 pythId) external view returns (uint256);

    function getUpdateFee(uint256 length) external view returns (uint256);

    function updateValues(bytes[] memory vaas, bytes32[] memory ids) external payable returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';

interface IOracleOffChainPyth is IOracle {

    event NewValue(uint256 indexed timestamp, uint256 indexed value);

    function delayAllowance() external view returns (uint256);

    function lastSignatureTimestamp() external view returns (uint256);

    function oracleManager() external view returns (address);

    function pythId() external view returns (bytes32);

    function updateValue(uint256 timestamp_, uint256 value_) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import './IOracleOffChainPyth.sol';
import './IOracleManagerPyth.sol';
import '../library/SafeMath.sol';
import '../utils/NameVersion.sol';
import '../utils/Admin.sol';

contract OracleManagerPyth is IOracleManagerPyth, NameVersion, Admin {

    using SafeMath for uint256;
    using SafeMath for int256;

    address public pyth;
    // pythId => oracleAddress
    mapping (bytes32 => address) _oracles;
    // symbolId => pythId
    mapping (bytes32 => bytes32) _pythIds;

    constructor (address pyth_) NameVersion('OracleManagerPyth', '3.0.4') {
        pyth = pyth_;
    }

    function getOracle(bytes32 symbolId) public view returns (address) {
        return _oracles[_pythIds[symbolId]];
    }

    function getOracle(string memory symbol) external view returns (address) {
        return getOracle(keccak256(abi.encodePacked(symbol)));
    }

    function setOracle(address oracleAddress) external _onlyAdmin_ {
        IOracleOffChainPyth oracle = IOracleOffChainPyth(oracleAddress);
        require(oracle.oracleManager() == address(this));
        bytes32 symbolId = oracle.symbolId();
        bytes32 pythId = oracle.pythId();
        _oracles[pythId] = oracleAddress;
        _pythIds[symbolId] = pythId;
        emit NewOracle(symbolId, oracleAddress);
    }

    function delOracle(bytes32 symbolId) public _onlyAdmin_ {
        delete _oracles[_pythIds[symbolId]];
        delete _pythIds[symbolId];
        emit NewOracle(symbolId, address(0));
    }

    function delOracle(string memory symbol) external {
        delOracle(keccak256(abi.encodePacked(symbol)));
    }

    function retrieveETH(address to) external _onlyAdmin_ {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success);
        }
    }

    function value(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[_pythIds[symbolId]];
        require(oracle != address(0), 'OracleManagerPyth.value: no oracle');
        return IOracle(oracle).value();
    }

    function timestamp(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[_pythIds[symbolId]];
        require(oracle != address(0), 'OracleManagerPyth.timestamp: no oracle');
        return IOracle(oracle).timestamp();
    }

    function lastSignatureTimestamp(bytes32 pythId) public view returns (uint256) {
        address oracle = _oracles[pythId];
        require(oracle != address(0), 'OracleManagerPyth.lastSignatureTimestamp: no oracle');
        return IOracleOffChainPyth(oracle).lastSignatureTimestamp();
    }

    function getValue(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[_pythIds[symbolId]];
        require(oracle != address(0), 'OracleManagerPyth.getValue: no oracle');
        return IOracle(oracle).getValue();
    }

    function getValueWithJump(bytes32 symbolId) external returns (uint256 val, int256 jump) {
        address oracle = _oracles[_pythIds[symbolId]];
        require(oracle != address(0), 'OracleManagerPyth.getValueWithHistory: no oracle');
        return IOracle(oracle).getValueWithJump();
    }

    function getUpdateFee(uint256 length) external view returns (uint256) {
        return IPyth(pyth).getUpdateFee(length);
    }

    function updateValues(bytes[] memory vaas, bytes32[] memory ids)
    external payable returns (bool)
    {
        (bool success, bytes memory res) = address(pyth).call{value: msg.value}(
            abi.encodeWithSelector(
                IPyth.parsePriceFeedUpdates.selector, vaas, ids, 0, type(uint64).max
            )
        );
        if (success) {
            IPyth.PriceFeed[] memory priceFeeds = abi.decode(res, (IPyth.PriceFeed[]));
            for (uint256 i = 0; i < priceFeeds.length; i++) {
                uint256 _timestamp = priceFeeds[i].price.publishTime;
                uint256 _price = int256(priceFeeds[i].price.price).itou() * (
                    10 ** (int256(18) + priceFeeds[i].price.expo).itou()
                );

                address oracle = _oracles[priceFeeds[i].id];
                require(oracle != address(0), 'OracleManagerPyth.updateValues: no oracle');
                IOracleOffChainPyth(oracle).updateValue(_timestamp, _price);
            }
            return true;
        } else {
            return false;
        }
    }

}

interface IPyth {

    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }

    function getUpdateFee(
        uint updateDataSize
    ) external view returns (uint feeAmount);

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PriceFeed[] memory priceFeeds);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}