/**
 *Submitted for verification at Arbiscan on 2022-12-10
*/

pragma solidity ^0.8.7;

contract FishOracle {
    address public pool;
    address public token0;
    address public token1;
    uint256 public price0Average;
    uint256 public price1Average;
    uint256 public pricesBlockTimestampLast;
    uint256[2] public priceCumulativeLast;
    bool public valid = true;

    address internal dao;

    constructor(
        address _dao,
        address _pool,
        address _Ttoken0,
        address _curve3CRVtoken1
    ) {
        dao = _dao;
        pool = _pool;

        token0 = _Ttoken0;
        token1 = _curve3CRVtoken1;

        price0Average = 1 ether;
        price1Average = 1 ether;
    }

    function update() external {}

    function updateP(
        uint256 p0,
        uint256 p1
    ) external onlyDao {
        price0Average = p0;
        price1Average = p1;
    }

    function updateAll(
        uint256 pBTL,
        uint256 pCL0,
        uint256 pCL1,
        bool v
    ) external onlyDao {
        pricesBlockTimestampLast = pBTL;
        priceCumulativeLast[0] = pCL0;
        priceCumulativeLast[1] = pCL1;
        valid = v;
    }

    function averageDollarPrice()
        public
        view
        returns (uint256, bool)
    {
        return (price0Average, valid);
    }

    function consult(address token) external view returns (uint256 amountOut) {
        if (token == token0) {
            amountOut = price0Average;
        } else {
            require(token == token1, "FishOracle: INVALID_TOKEN");
            amountOut = price1Average;
        }
    }

    modifier onlyDao() {
        require(msg.sender == dao, "Not dao");
        _;
    }
}