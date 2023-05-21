/**
 *Submitted for verification at Arbiscan on 2023-05-21
*/

pragma solidity ^0.8.7;


// SPDX-License-Identifier: MIT
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

interface IFactory {
    function WETH() external view returns (address);

    function dexAggregator() external view returns (address);

    function protocolFeePercent() external view returns (uint256);

    function protocolFeeTo() external view returns (address);

    function pools(uint256) external view returns (address);

    function poolLength() external view returns (uint256);

    function poolIndex(address) external view returns (uint256);

    function poolByQuoteToken(address) external view returns (address);

    function collaterals(uint256) external view returns (address);

    function collateralLength() external view returns (uint256);

    function collateralLT(address) external view returns (uint256);
}

interface IPool {
    struct PositionToken {
        address token;
        uint256 amount;
        uint256 entryPrice;
        uint256 liqPrice;
    }
    struct Position {
        bytes32 positionId;
        address trader;
        address creator;
        PositionToken collateral;
        PositionToken baseToken;
        uint256 quoteTokenAmount;
        uint256 stoplossPrice;
        uint256 deadline;
        uint256 fee;
        uint256 protocolFee;
        address dex;
        uint256 status; // 0: opening, 1: completed, 2: stopped, 3: stoploss, 4: liquidated
        uint256 createdTime;
    }
    struct PositionOpenParams {
        address trader;
        address collateral;
        uint256 collateralAmount;
        address baseToken;
        uint256 baseTokenAmount;
        uint256 minBaseTokenPrice;
        uint256 quoteTokenAmount;
        uint256 stoplossPrice;
        uint256 deadline;
        address dex;
    }

    function factory() external view returns (address);

    function quoteToken() external view returns (address);

    function quoteReserve() external view returns (uint256);

    function accumulatedProtocolFee() external view returns (uint256);

    function quoteInDebt() external view returns (uint256);

    function interest() external view returns (uint256);

    function baseTokens(uint256) external view returns (address);

    function baseTokenLength() external view returns (uint256);

    function baseTokenIndex(address) external view returns (uint256);

    function baseTokenLT(address) external view returns (uint256);

    function position(uint256) external view returns (Position memory);

    function positionIndex(bytes32) external view returns (uint256);

    function openingPositionIds(uint256) external view returns (bytes32);

    function openingPositionIdIndex(bytes32) external view returns (uint256);

    function openingPositionLength() external view returns (uint256);

    function userPositionLength(address) external view returns (uint256);

    function positionIdByUser(
        address _user,
        uint256 _index
    ) external view returns (bytes32);

    function availableLiquidity() external view returns (uint256);

    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256);

    function healthCheck(
        PositionToken memory _collateral,
        PositionToken memory _baseToken,
        address _dex
    ) external view returns (bool);

    function healthCheckByPositionId(bytes32) external view returns (bool);

    function preview(
        PositionOpenParams memory
    ) external view returns (Position memory);

    function canExecute(bytes32) external view returns (bool);

    function open(PositionOpenParams memory) external returns (bytes32);

    function close(bytes32) external;

    function updateStoploss(
        bytes32 _positionId,
        uint256 _stoplossPrice
    ) external;
}

struct PoolDetail {
    address lpToken;
    string lpSymbol;
    address quoteToken;
    string quoteSymbol;
    uint256 quoteReserve;
    uint256 quoteInDebt;
    uint256 availableLiquidity;
    uint256 interest;
}

struct Pair {
    string ticker;
    address pool;
    address baseToken;
    address quoteToken;
}

struct Position {
    address pool;
    IPool.Position detail;
}

struct PositionOpenParams {
    address pool;
    address collateral;
    uint256 collateralAmount;
    address baseToken;
    uint256 baseTokenAmount;
    uint256 quoteTokenAmount;
    uint256 minBaseTokenPrice;
    uint256 stoplossPrice;
    uint256 deadline;
    address dex;
}

contract PoolReader {
    function _concatPairs(
        Pair[][] memory _arrays
    ) internal pure returns (Pair[] memory) {
        uint256 length;
        for (uint256 i = 0; i < _arrays.length; i++) {
            length += _arrays[i].length;
        }
        Pair[] memory result = new Pair[](length);

        uint256 j = 0;
        for (uint256 k = 0; k < _arrays.length; k++) {
            for (uint256 l = 0; l < _arrays[k].length; l++) {
                result[j] = _arrays[k][l];
            }
        }

        return result;
    }

    function _concatPositions(
        Position[][] memory _arrays
    ) internal pure returns (Position[] memory) {
        uint256 length;
        for (uint256 i = 0; i < _arrays.length; i++) {
            length += _arrays[i].length;
        }
        Position[] memory result = new Position[](length);

        uint256 j = 0;
        for (uint256 k = 0; k < _arrays.length; k++) {
            for (uint256 l = 0; l < _arrays[k].length; l++) {
                result[j] = _arrays[k][l];
            }
        }

        return result;
    }

    function allPools(address _factory) public view returns (address[] memory) {
        uint256 length = IFactory(_factory).poolLength();
        address[] memory pools = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            pools[i] = IFactory(_factory).pools(i);
        }
        return pools;
    }

    function poolDetail(address _pool) public view returns (PoolDetail memory) {
        address quoteToken = IPool(_pool).quoteToken();
        return
            PoolDetail({
                lpToken: _pool,
                lpSymbol: IERC20(_pool).symbol(),
                quoteToken: quoteToken,
                quoteSymbol: IERC20(quoteToken).symbol(),
                quoteReserve: IPool(_pool).quoteReserve(),
                quoteInDebt: IPool(_pool).quoteInDebt(),
                availableLiquidity: IPool(_pool).availableLiquidity(),
                interest: IPool(_pool).interest()
            });
    }

    function allPoolDetails(
        address _factory
    ) external view returns (PoolDetail[] memory) {
        address[] memory pools = allPools(_factory);
        PoolDetail[] memory poolDetails = new PoolDetail[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            poolDetails[i] = poolDetail(pools[i]);
        }
        return poolDetails;
    }

    function pairsByPool(address _pool) public view returns (Pair[] memory) {
        address quoteToken = IPool(_pool).quoteToken();
        string memory quoteTokenSymbol = IERC20(quoteToken).symbol();
        uint256 length = IPool(_pool).baseTokenLength();
        Pair[] memory pairs = new Pair[](length);
        for (uint256 i = 0; i < length; i++) {
            pairs[i].pool = _pool;
            pairs[i].quoteToken = quoteToken;
            address baseToken = IPool(_pool).baseTokens(i);
            pairs[i].baseToken = baseToken;
            string memory baseTokenSymbol = IERC20(baseToken).symbol();
            pairs[i].ticker = string(
                abi.encodePacked(baseTokenSymbol, "/", quoteTokenSymbol)
            );
        }
        return pairs;
    }

    function allPairs(address _factory) external view returns (Pair[] memory) {
        address[] memory pools = allPools(_factory);
        Pair[][] memory pairsArrays = new Pair[][](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            pairsArrays[i] = pairsByPool(pools[i]);
        }
        return _concatPairs(pairsArrays);
    }

    function previewPosition(
        PositionOpenParams memory _params
    ) external view returns (IPool.Position memory) {
        return
            IPool(_params.pool).preview(
                IPool.PositionOpenParams({
                    trader: msg.sender,
                    collateral: _params.collateral,
                    collateralAmount: _params.collateralAmount,
                    baseToken: _params.baseToken,
                    baseTokenAmount: _params.baseTokenAmount,
                    minBaseTokenPrice: _params.minBaseTokenPrice,
                    quoteTokenAmount: _params.quoteTokenAmount,
                    stoplossPrice: _params.stoplossPrice,
                    deadline: _params.deadline,
                    dex: _params.dex
                })
            );
    }

    function positionDetail(
        bytes32 _positionId,
        address _pool
    ) public view returns (IPool.Position memory) {
        uint256 index = IPool(_pool).positionIndex(_positionId);
        return IPool(_pool).position(index - 1);
    }

    function userPositionsByPool(
        address _user,
        address _pool
    ) public view returns (Position[] memory) {
        uint256 length = IPool(_pool).userPositionLength(_user);
        Position[] memory positions = new Position[](length);
        for (uint256 i = 0; i < length; i++) {
            positions[i].pool = _pool;
            bytes32 positionId = IPool(_pool).positionIdByUser(_user, i);
            positions[i].detail = positionDetail(positionId, _pool);
        }
        return positions;
    }

    function allUserPositions(
        address _user,
        address _factory
    ) external view returns (Position[] memory) {
        address[] memory pools = allPools(_factory);
        Position[][] memory positionsArrays = new Position[][](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            positionsArrays[i] = userPositionsByPool(_user, pools[i]);
        }
        return _concatPositions(positionsArrays);
    }
}