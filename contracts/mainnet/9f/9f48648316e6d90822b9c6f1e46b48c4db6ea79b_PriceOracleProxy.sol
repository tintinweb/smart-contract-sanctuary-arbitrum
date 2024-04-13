interface IAssetVault {
    function decimals() external view returns (uint256);
    function pps() external view returns (uint256);
}

interface IAggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint8);
}

interface ICurvePriceOracle {
    function price() external view returns (uint256);
    function price_w() external view returns (uint256);
}

contract PriceOracle is ICurvePriceOracle {
    error InvalidPrice();
    error SequencerDown();
    error GracePeriodNotOver();

    IAssetVault public immutable assetVault;
    IAggregatorV3Interface public immutable priceFeed;
    IAggregatorV3Interface public constant sequencerUptimeFeed =
        IAggregatorV3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    uint256 public constant DOWNTIME_WAIT = 3600;

    uint256 immutable decimals;

    constructor(address _assetVault, address _priceFeed) {
        assetVault = IAssetVault(_assetVault);
        decimals = assetVault.decimals();
        priceFeed = IAggregatorV3Interface(_priceFeed);
    }

    function price() public view returns (uint256) {
        return _price();
    }

    function price_w() public view returns (uint256) {
        return _price();
    }

    function _price() internal view returns (uint256) {
        // check if sequencer down, in case it went down, allow an hour grace period
        (, int256 isDown, uint256 startedAt,,) = sequencerUptimeFeed.latestRoundData();
        if (isDown == int256(1)) revert SequencerDown();
        if (block.timestamp < startedAt + DOWNTIME_WAIT) revert GracePeriodNotOver();

        (, int256 price,,,) = IAggregatorV3Interface(priceFeed).latestRoundData();
        if (price < 0) revert InvalidPrice();
        uint256 underlyingPrice = uint256(price);
        uint256 priceDecimal = IAggregatorV3Interface(priceFeed).decimals();
        uint256 pps = assetVault.pps();
        return (pps * 1e18 / (10 ** decimals)) * underlyingPrice / (10 ** priceDecimal);
    }
}

contract PriceOracleProxy is ICurvePriceOracle {
    error OnlyOwner();
    error ZeroAddress();

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event ImplementationChanged(address indexed previousImpl, address indexed newImpl);

    PriceOracle impl;
    address owner;

    constructor(address _impl, address _owner) {
        impl = PriceOracle(_impl);
        owner = _owner;

        emit OwnerChanged(address(0), _owner);
        emit ImplementationChanged(address(0), _impl);
    }

    function upgradeImpl(address _newImpl) external onlyOwner {
        if (_newImpl == address(0)) revert ZeroAddress();
        address previousImpl = address(impl);
        impl = PriceOracle(_newImpl);
        emit ImplementationChanged(previousImpl, _newImpl);
    }

    function setOwner(address _newOwner) external onlyOwner {
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(previousOwner, _newOwner);
    }

    function price() external view returns (uint256) {
        return impl.price();
    }

    function price_w() external view returns (uint256) {
        return impl.price_w();
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
}