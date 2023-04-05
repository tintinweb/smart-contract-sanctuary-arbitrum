// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ChildChainPairFactoryInterface {
     bool public isPaused;

    address public feesFactory;
    address public voter;

    mapping(address => mapping(address => mapping(bool => address)))
        public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    uint256 public maxFees; // 1_000_000 = 100%
    uint256 public stableFees;
    uint256 public volatileFees;
    mapping(address => bool) public poolSpecificFeesEnabled;
    mapping(address => uint256) public poolSpecificFees;

    mapping(address => bool) public isOperator;

    /**************************************** 
                      Events
     ****************************************/

    event OperatorStatus(address indexed operator, bool state);

    event PairCreated(
        address indexed token0,
        address indexed token1,
        bool stable,
        address pair,
        uint256
    );

    function initialize(address _feesFactory, address _voter)
        external {}
     
    function setOperator(address operator, bool state) external {}

    function setPause(bool _state) external {}

    function setMaxFees(uint256 _maxFees) external {}

    function setStableFees(uint256 _stableFees)
        external {}

    function setVolatileFees(uint256 _volatileFees)
        external {}

    /**
     * @notice Sets specific pool's fees
     * @dev _enabled needs to be set to true, to differentiate between
     *      pools with 0% fees and pools without specific fees
     */
    function setPoolSpecificFees(
        address _pool,
        uint256 _fees,
        bool _enabled
    ) external {}

    /**************************************** 
                   View Methods
     ****************************************/

    function allPairsLength() external view returns (uint256) {}

    function pairCodeHash() external pure returns (bytes32) {}

    /**
     * @notice Returns fee in basis points for a pool
     */
    function poolFees(address pool) external view returns (uint256) {}

    /**************************************** 
                User Interaction
     ****************************************/

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns  (address pair) {}

    function createFees() external returns (address fees) {}

    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {}

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {}

       function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function interfaceSourceAddress() external view returns (address) {}


    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
    {}

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external {}

}