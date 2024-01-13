/**
 *Submitted for verification at Arbiscan.io on 2024-01-10
*/

pragma solidity >=0.6.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface AggregatorV2V3Interface is
    AggregatorInterface,
    AggregatorV3Interface
{}

interface IBunniOracle {
    function bunniTokenPriceUSD(
        IBunniToken bunniToken,
        uint32 uniV3OracleSecondsAgo,
        uint256 chainlinkPriceMaxAgeSecs,
        AggregatorV2V3Interface feed0,
        AggregatorV2V3Interface feed1
    ) external view returns (uint256 priceUSD);
}

interface IUniswapV3Pool {}

interface IBunniToken {
    function pool() external view returns (IUniswapV3Pool);

    function tickLower() external view returns (int24);

    function tickUpper() external view returns (int24);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

pragma solidity >=0.8.4;

contract bunniPoisonOracle {
    IBunniOracle public bunniOracle;
    IBunniToken public bunniToken;
    AggregatorV2V3Interface public oracle0;
    AggregatorV2V3Interface public oracle1;
    uint256 public chainlinkPriceMaxAgeSecs;
    uint32 public uniV3OracleSecondsAgo;

    constructor(
        address _oracle0,
        address _oracle1,
        address _bunniToken,
        address _bunniOracle,
        uint256 _chainlinkPriceMaxAgeSecs,
        uint32 _uniV3OracleSecondsAgo
    ) {
        bunniOracle = IBunniOracle(_bunniOracle);
        bunniToken = IBunniToken(_bunniToken);
        oracle0 = AggregatorV2V3Interface(_oracle0);
        oracle1 = AggregatorV2V3Interface(_oracle1);
        chainlinkPriceMaxAgeSecs = _chainlinkPriceMaxAgeSecs;
        uniV3OracleSecondsAgo = _uniV3OracleSecondsAgo;

    }

    function getAnswer(
        IBunniToken _bunniToken,
        uint32 _uniV3OracleSecondsAgo,
        uint256 _chainlinkPriceMaxAgeSecs,
        AggregatorV2V3Interface _oracle0,
        AggregatorV2V3Interface _oracle1
    ) public view returns (int256) {
        return
            int256(
                bunniOracle.bunniTokenPriceUSD(
                    _bunniToken,
                    _uniV3OracleSecondsAgo,
                    _chainlinkPriceMaxAgeSecs,
                    _oracle0,
                    _oracle1
                )
            ) / 10**10;
    }

    function latestRoundData()
        public
        view
        virtual
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            1,
            getAnswer(
                bunniToken,
                uniV3OracleSecondsAgo,
                chainlinkPriceMaxAgeSecs,
                oracle0,
                oracle1
            ),
            1,
            1,
            1
        );
    }

    function latestAnswer() public view virtual returns (int256 answer) {
        return
            getAnswer(
                bunniToken,
                uniV3OracleSecondsAgo,
                chainlinkPriceMaxAgeSecs,
                oracle0,
                oracle1
            );
    }

}