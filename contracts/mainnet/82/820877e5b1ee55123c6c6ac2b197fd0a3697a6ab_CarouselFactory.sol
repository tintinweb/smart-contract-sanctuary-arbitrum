// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultFactoryV2.sol";

import {ICarousel} from "../interfaces/ICarousel.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CarouselCreator} from "../libraries/CarouselCreator.sol";

/// @author Y2K Finance Team

contract CarouselFactory is VaultFactoryV2 {
    using SafeERC20 for IERC20;
    IERC20 public emissionsToken;

    /** @notice constructor
    @param _weth address of the weth contract
    @param _treasury address of the treasury contract
    @param _emissoinsToken address of the emissions token
     */
    constructor(
        address _weth,
        address _treasury,
        address _timelock,
        address _emissoinsToken
    ) VaultFactoryV2(_weth, _treasury, _timelock) {
        if (_emissoinsToken == address(0)) revert AddressZero();
        emissionsToken = IERC20(_emissoinsToken);
    }

    /**
    @notice Function to create two new vaults, premium and collateral, with the respective params, and storing the oracle for the token provided
    @param  _marketCalldata CarouselMarketConfigurationCalldata struct with the market params
    @return premium address of the premium vault
    @return collateral address of the collateral vault
    @return marketId uint256 of the marketId
     */
    function createNewCarouselMarket(
        CarouselMarketConfigurationCalldata memory _marketCalldata
    )
        external
        onlyOwner
        returns (
            address premium,
            address collateral,
            uint256 marketId
        )
    {
        if (!controllers[_marketCalldata.controller]) revert ControllerNotSet();
        if (_marketCalldata.token == address(0)) revert AddressZero();
        if (_marketCalldata.oracle == address(0)) revert AddressZero();
        if (_marketCalldata.underlyingAsset == address(0)) revert AddressZero();

        marketId = getMarketId(
            _marketCalldata.token,
            _marketCalldata.strike,
            _marketCalldata.underlyingAsset
        );

        if (marketIdToVaults[marketId][0] != address(0))
            revert MarketAlreadyExists();

        marketIdInfo[marketId] = MarketInfo(
            _marketCalldata.token,
            _marketCalldata.strike,
            _marketCalldata.underlyingAsset
        );

        // set oracle for the market
        marketToOracle[marketId] = _marketCalldata.oracle;

        //y2kUSDC_99*PREMIUM
        premium = CarouselCreator.createCarousel(
            CarouselCreator.CarouselMarketConfiguration(
                _marketCalldata.underlyingAsset == WETH,
                _marketCalldata.underlyingAsset,
                string(abi.encodePacked(_marketCalldata.name, PREMIUM)),
                string(PSYMBOL),
                _marketCalldata.tokenURI,
                _marketCalldata.token,
                _marketCalldata.strike,
                _marketCalldata.controller,
                treasury,
                address(emissionsToken),
                _marketCalldata.relayerFee,
                _marketCalldata.depositFee,
                _marketCalldata.minQueueDeposit
            )
        );

        // y2kUSDC_99*COLLATERAL
        collateral = CarouselCreator.createCarousel(
            CarouselCreator.CarouselMarketConfiguration(
                _marketCalldata.underlyingAsset == WETH,
                _marketCalldata.underlyingAsset,
                string(abi.encodePacked(_marketCalldata.name, COLLAT)),
                string(CSYMBOL),
                _marketCalldata.tokenURI,
                _marketCalldata.token,
                _marketCalldata.strike,
                _marketCalldata.controller,
                treasury,
                address(emissionsToken),
                _marketCalldata.relayerFee,
                _marketCalldata.depositFee,
                _marketCalldata.minQueueDeposit
            )
        );

        //set counterparty vault
        ICarousel(premium).setCounterPartyVault(collateral);
        ICarousel(collateral).setCounterPartyVault(premium);

        marketIdToVaults[marketId] = [premium, collateral];

        emit MarketCreated(
            marketId,
            premium,
            collateral,
            _marketCalldata.underlyingAsset,
            _marketCalldata.token,
            _marketCalldata.name,
            _marketCalldata.strike,
            _marketCalldata.controller
        );

        return (premium, collateral, marketId);
    }

    function createNewMarket(MarketConfigurationCalldata memory)
        external
        override
        returns (
            address,
            address,
            uint256
        )
    {
        revert();
    }

    /** @notice Function to create a new epoch with emissions
    @param _marketId uint256 of the marketId
    @param _epochBegin uint40 of the epoch begin
    @param _epochEnd uint40 of the epoch end
    @param _withdrawalFee uint16 of the withdrawal fee
    @param _premiumEmissions uint256 of the emissions for the premium vault
    @param _collatEmissions uint256 of the emissions for the collateral vault
    @return epochId uint256 of the epochId
    @return vaults address[2] of the vaults
     */
    function createEpochWithEmissions(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee,
        uint256 _premiumEmissions,
        uint256 _collatEmissions
    ) public returns (uint256 epochId, address[2] memory vaults) {
        // no need for onlyOwner modifier as createEpoch already has modifier
        (epochId, vaults) = _createEpoch(
            _marketId,
            _epochBegin,
            _epochEnd,
            _withdrawalFee
        );

        emissionsToken.safeTransferFrom(treasury, vaults[0], _premiumEmissions);
        ICarousel(vaults[0]).setEmissions(epochId, _premiumEmissions);

        emissionsToken.safeTransferFrom(treasury, vaults[1], _collatEmissions);
        ICarousel(vaults[1]).setEmissions(epochId, _collatEmissions);

        emit EpochCreatedWithEmissions(
            epochId,
            _marketId,
            _epochBegin,
            _epochEnd,
            _withdrawalFee,
            _premiumEmissions,
            _collatEmissions
        );
    }

    // to prevent the creation of epochs without emissions
    // this function is not used
    function createEpoch(
        uint256, /*_marketId*/
        uint40, /*_epochBegin*/
        uint40, /*_epochEnd*/
        uint16 /*_withdrawalFee*/
    ) public override returns (uint256, address[2] memory) {
        revert();
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /** @notice Function to change the relayer fee
    @param _relayerFee uint256 of the relayer fee
    @param _marketIndex uint256 of the market index
     */
    function changeRelayerFee(uint256 _relayerFee, uint256 _marketIndex)
        public
        onlyTimeLocker
    {
        if (_relayerFee < 10000) revert InvalidRelayerFee();

        address[2] memory vaults = marketIdToVaults[_marketIndex];
        if (vaults[0] == address(0)) revert MarketDoesNotExist(_marketIndex);

        ICarousel premium = ICarousel(vaults[0]);
        ICarousel collat = ICarousel(vaults[1]);

        if (premium.getDepositQueueLength() > 0) revert QueueNotEmpty();
        if (collat.getDepositQueueLength() > 0) revert QueueNotEmpty();

        premium.changeRelayerFee(_relayerFee);
        collat.changeRelayerFee(_relayerFee);

        emit ChangedRelayerFee(_relayerFee, _marketIndex);
    }

    function changeDepositFee(
        uint256 _depositFee,
        uint256 _marketIndex,
        uint256 vaultIndex
    ) public onlyTimeLocker {
        if (vaultIndex > 1) revert InvalidVaultIndex();
        // _depositFee is in basis points max 0.5%
        if (_depositFee > 250) revert InvalidDepositFee();
        // TODO might need to be able to change individual vaults
        address[2] memory vaults = marketIdToVaults[_marketIndex];
        if (vaults[vaultIndex] == address(0))
            revert MarketDoesNotExist(_marketIndex);
        ICarousel(vaults[vaultIndex]).changeDepositFee(_depositFee);

        emit ChangedDepositFee(
            _depositFee,
            _marketIndex,
            vaultIndex,
            vaults[vaultIndex]
        );
    }

    // admin function to cleanup rollover queue by passing in array of addresses and vault address
    function cleanupRolloverQueue(address[] memory _addresses, address _vault)
        public
        onlyTimeLocker
    {
        ICarousel(_vault).cleanupRolloverQueue(_addresses);
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct CarouselMarketConfigurationCalldata {
        address token;
        uint256 strike;
        address oracle;
        address underlyingAsset;
        string name;
        string tokenURI;
        address controller;
        uint256 relayerFee;
        uint256 depositFee;
        uint256 minQueueDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidRelayerFee();
    error InvalidVaultIndex();
    error InvalidDepositFee();
    error QueueNotEmpty();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChangedDepositFee(
        uint256 depositFee,
        uint256 marketIndex,
        uint256 vaultIndex,
        address vault
    );

    event ChangedRelayerFee(uint256 relayerFee, uint256 marketIndex);

    event EpochCreatedWithEmissions(
        uint256 epochId,
        uint256 marketId,
        uint40 epochBegin,
        uint40 epochEnd,
        uint16 withdrawalFee,
        uint256 premiumEmissions,
        uint256 collateralEmissions
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultV2} from "./interfaces/IVaultV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VaultV2Creator} from "./libraries/VaultV2Creator.sol";

/// @author Y2K Finance Team

contract VaultFactoryV2 is Ownable {
    address public immutable WETH;
    bytes internal constant COLLAT = "COLLATERAL";
    bytes internal constant PREMIUM = "PREMIUM";
    bytes internal constant CSYMBOL = "cY2K";
    bytes internal constant PSYMBOL = "pY2K";
    /*//////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////*/
    address public treasury;
    bool internal adminSetController;
    address public timelocker;

    mapping(uint256 => address[2]) public marketIdToVaults; //[0] premium and [1] collateral vault
    mapping(uint256 => uint256[]) public marketIdToEpochs; //all epochs in the market
    mapping(uint256 => MarketInfo) public marketIdInfo; // marketId configuration
    mapping(uint256 => uint16) public epochFee; // epochId to fee
    mapping(uint256 => address) public marketToOracle; //token address to respective oracle smart contract address
    mapping(address => bool) public controllers;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /** @notice Contract constructor
     * @param _weth WETH address
     * @param _treasury Treasury address
     * @param _timelocker Timelocker address
     */
    constructor(
        address _weth,
        address _treasury,
        address _timelocker
    ) {
        if (_weth == address(0)) revert AddressZero();
        WETH = _weth;
        timelocker = _timelocker;
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Function to create two new vaults, premium and collateral, with the respective params, and storing the oracle for the token provided
    @param  _marketCalldata MarketConfigurationCalldata struct with the market params
    @return premium address of the premium vault
    @return collateral address of the collateral vault
    @return marketId uint256 of the marketId
     */
    function createNewMarket(MarketConfigurationCalldata memory _marketCalldata)
        external
        virtual
        onlyOwner
        returns (
            address premium,
            address collateral,
            uint256 marketId
        )
    {
        return _createNewMarket(_marketCalldata);
    }

    function _createNewMarket(
        MarketConfigurationCalldata memory _marketCalldata
    )
        internal
        returns (
            address premium,
            address collateral,
            uint256 marketId
        )
    {
        if (!controllers[_marketCalldata.controller]) revert ControllerNotSet();
        if (_marketCalldata.token == address(0)) revert AddressZero();
        if (_marketCalldata.oracle == address(0)) revert AddressZero();
        if (_marketCalldata.underlyingAsset == address(0)) revert AddressZero();

        marketId = getMarketId(
            _marketCalldata.token,
            _marketCalldata.strike,
            _marketCalldata.underlyingAsset
        );
        marketIdInfo[marketId] = MarketInfo(
            _marketCalldata.token,
            _marketCalldata.strike,
            _marketCalldata.underlyingAsset
        );

        if (marketIdToVaults[marketId][0] != address(0))
            revert MarketAlreadyExists();

        // set oracle for the market
        marketToOracle[marketId] = _marketCalldata.oracle;

        //y2kUSDC_99*PREMIUM
        premium = VaultV2Creator.createVaultV2(
            VaultV2Creator.MarketConfiguration(
                _marketCalldata.underlyingAsset == WETH,
                _marketCalldata.underlyingAsset,
                string(abi.encodePacked(_marketCalldata.name, PREMIUM)),
                string(PSYMBOL),
                _marketCalldata.tokenURI,
                _marketCalldata.token,
                _marketCalldata.strike,
                _marketCalldata.controller,
                treasury
            )
        );

        // y2kUSDC_99*COLLATERAL
        collateral = VaultV2Creator.createVaultV2(
            VaultV2Creator.MarketConfiguration(
                _marketCalldata.underlyingAsset == WETH,
                _marketCalldata.underlyingAsset,
                string(abi.encodePacked(_marketCalldata.name, COLLAT)),
                string(CSYMBOL),
                _marketCalldata.tokenURI,
                _marketCalldata.token,
                _marketCalldata.strike,
                _marketCalldata.controller,
                treasury
            )
        );

        //set counterparty vault
        IVaultV2(premium).setCounterPartyVault(collateral);
        IVaultV2(collateral).setCounterPartyVault(premium);

        marketIdToVaults[marketId] = [premium, collateral];

        emit MarketCreated(
            marketId,
            premium,
            collateral,
            _marketCalldata.underlyingAsset,
            _marketCalldata.token,
            _marketCalldata.name,
            _marketCalldata.strike,
            _marketCalldata.controller
        );

        return (premium, collateral, marketId);
    }

    /**    
    @notice Function set epoch for market,
    @param  _marketId uint256 of the market index to create more assets in
    @param  _epochBegin uint40 in UNIX timestamp, representing the begin date of the epoch. Example: Epoch begins in 31/May/2022 at 00h 00min 00sec: 1654038000
    @param  _epochEnd uint40 in UNIX timestamp, representing the end date of the epoch and also the ID for the minting functions. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1656630000
    @param _withdrawalFee uint16 of the fee value, multiply your % value by 10, Example: if you want fee of 0.5% , insert 5
     */
    function createEpoch(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee
    )
        public
        virtual
        onlyOwner
        returns (uint256 epochId, address[2] memory vaults)
    {
        return _createEpoch(_marketId, _epochBegin, _epochEnd, _withdrawalFee);
    }

    function _createEpoch(
        uint256 _marketId,
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint16 _withdrawalFee
    ) internal returns (uint256 epochId, address[2] memory vaults) {
        vaults = marketIdToVaults[_marketId];

        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        if (_withdrawalFee == 0) revert FeeCannotBe0();

        if (!controllers[IVaultV2(vaults[0]).controller()])
            revert ControllerNotSet();
        if (!controllers[IVaultV2(vaults[1]).controller()])
            revert ControllerNotSet();

        epochId = getEpochId(_marketId, _epochBegin, _epochEnd);

        _setEpoch(
            EpochConfiguration(
                _epochBegin,
                _epochEnd,
                _withdrawalFee,
                _marketId,
                epochId,
                IVaultV2(vaults[0]),
                IVaultV2(vaults[1])
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setEpoch(EpochConfiguration memory _epochConfig) internal {
        _epochConfig.premium.setEpoch(
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            _epochConfig.epochId
        );
        _epochConfig.collateral.setEpoch(
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            _epochConfig.epochId
        );

        epochFee[_epochConfig.epochId] = _epochConfig.withdrawalFee;
        marketIdToEpochs[_epochConfig.marketId].push(_epochConfig.epochId);

        emit EpochCreated(
            _epochConfig.epochId,
            _epochConfig.marketId,
            _epochConfig.epochBegin,
            _epochConfig.epochEnd,
            address(_epochConfig.premium),
            address(_epochConfig.collateral),
            _epochConfig.premium.token(),
            _epochConfig.premium.strike(),
            _epochConfig.withdrawalFee
        );
    }

    /**
    @notice Function to whitelist controller smart contract, only owner or timelocker can add more controllers. 
    @dev owner can set controller once, all future controllers must be set by timelocker.
    @param  _controller Address of the controller smart contract
     */
    function whitelistController(address _controller) public {
        if (_controller == address(0)) revert AddressZero();
        if (msg.sender == owner() && !adminSetController) {
            controllers[_controller] = true;
            adminSetController = true;
            emit ControllerWhitelisted(_controller);
        } else if (msg.sender == timelocker) {
            controllers[_controller] = !controllers[_controller];
            if (!adminSetController) adminSetController = true;
            emit ControllerWhitelisted(_controller);
        } else {
            revert NotAuthorized();
        }
    }

    /**
    @notice Admin function, whitelists an address on vault for sendTokens function
    @param  _marketId Target market index
    @param _wAddress Treasury address
     */
    function whitelistAddressOnMarket(uint256 _marketId, address _wAddress)
        public
        onlyTimeLocker
    {
        if (_wAddress == address(0)) revert AddressZero();

        address[2] memory vaults = marketIdToVaults[_marketId];

        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        IVaultV2(vaults[0]).whiteListAddress(_wAddress);
        IVaultV2(vaults[1]).whiteListAddress(_wAddress);

        emit AddressWhitelisted(_wAddress, _marketId);
    }

    /**
    @notice Admin function, sets treasury address
    @param _treasury Treasury address
     */
    function setTreasury(address _treasury) public onlyTimeLocker {
        if (_treasury == address(0)) revert AddressZero();
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /**
    @notice Timelocker function, changes controller address on vaults
    @param _marketId Target marketId
    @param  _controller Address of the controller smart contract
     */
    function changeController(uint256 _marketId, address _controller)
        public
        onlyTimeLocker
        controllerIsWhitelisted(_controller)
    {
        if (_controller == address(0)) revert AddressZero();

        address[2] memory vaults = marketIdToVaults[_marketId];

        if (vaults[0] == address(0) || vaults[1] == address(0)) {
            revert MarketDoesNotExist(_marketId);
        }

        IVaultV2(vaults[0]).changeController(_controller);
        IVaultV2(vaults[1]).changeController(_controller);

        emit ControllerChanged(_marketId, _controller, vaults[0], vaults[1]);
    }

    /**
    @notice Timelocker function, changes oracle address for a given token
    @param _marketId Target token address
    @param  _oracle Oracle address
     */
    function changeOracle(uint256 _marketId, address _oracle)
        public
        onlyTimeLocker
    {
        if (_oracle == address(0)) revert AddressZero();
        if (_marketId == 0) revert MarketDoesNotExist(_marketId);
        if (marketToOracle[_marketId] == address(0))
            revert MarketDoesNotExist(_marketId);

        marketToOracle[_marketId] = _oracle;
        emit OracleChanged(_marketId, _oracle);
    }

    /**
    @notice Timelocker function, changes owner address
    @param _owner Address of the new _owner
     */
    function transferOwnership(address _owner) public override onlyTimeLocker {
        if (_owner == address(0)) revert AddressZero();
        _transferOwnership(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function the retrieve the addresses of the premium and collateral vaults, in an array, in the respective order
    @param index uint256 of the market index which to the vaults are associated to
    @return vaults Address array of two vaults addresses, [0] being the premium vault, [1] being the collateral vault
     */
    function getVaults(uint256 index)
        public
        view
        returns (address[2] memory vaults)
    {
        return marketIdToVaults[index];
    }

    /**
    @notice Function to retrieve the epochId for a given marketId
    @param marketId marketId
    @return epochIds uint256 array of epochIds
     */
    function getEpochsByMarketId(uint256 marketId)
        public
        view
        returns (uint256[] memory)
    {
        return marketIdToEpochs[marketId];
    }

    /**
    @notice Function to retrieve the fee for a given epoch
    @param epochId uint256 of the epoch
    @return fee uint16 of the fee
     */
    function getEpochFee(uint256 epochId) public view returns (uint16 fee) {
        return epochFee[epochId];
    }

    /**
    @notice Function to compute the marketId from a token and a strike price
    @param _token Address of the token
    @param _strikePrice uint256 of the strike price
    @param _underlying Address of the underlying
    @return marketId uint256 of the marketId
     */
    function getMarketId(
        address _token,
        uint256 _strikePrice,
        address _underlying
    ) public pure returns (uint256 marketId) {
        return
            uint256(
                keccak256(abi.encodePacked(_token, _strikePrice, _underlying))
            );
    }

    // get marketInfo
    function getMarketInfo(uint256 _marketId)
        public
        view
        returns (
            address token,
            uint256 strike,
            address underlyingAsset
        )
    {
        token = marketIdInfo[_marketId].token;
        strike = marketIdInfo[_marketId].strike;
        underlyingAsset = marketIdInfo[_marketId].underlyingAsset;
    }

    /**
    @notice Function to compute the epochId from a marketId, epochBegin and epochEnd
    @param marketId uint256 of the marketId
    @param epochBegin uint40 of the epoch begin
    @param epochEnd uint40 of the epoch end
    @return epochId uint256 of the epochId
     */
    function getEpochId(
        uint256 marketId,
        uint40 epochBegin,
        uint40 epochEnd
    ) public pure returns (uint256 epochId) {
        return
            uint256(
                keccak256(abi.encodePacked(marketId, epochBegin, epochEnd))
            );
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct MarketConfigurationCalldata {
        address token;
        uint256 strike;
        address oracle;
        address underlyingAsset;
        string name;
        string tokenURI;
        address controller;
    }

    struct EpochConfiguration {
        uint40 epochBegin;
        uint40 epochEnd;
        uint16 withdrawalFee;
        uint256 marketId;
        uint256 epochId;
        IVaultV2 premium;
        IVaultV2 collateral;
    }

    struct MarketInfo {
        address token;
        uint256 strike;
        address underlyingAsset;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Modifier to check if the caller is the timelocker
     */
    modifier onlyTimeLocker() {
        if (msg.sender != timelocker) revert NotTimeLocker();
        _;
    }

    /** @notice Modifier to check if the controller is whitelisted on the factory
     */
    modifier controllerIsWhitelisted(address _controller) {
        if (!controllers[_controller]) revert ControllerNotSet();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketDoesNotExist(uint256 marketId);
    error MarketAlreadyExists();
    error AddressZero();
    error ControllerNotSet();
    error NotTimeLocker();
    error NotAuthorized();
    error FeeCannotBe0();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Market is created when event is emitted
     * @param marketId market id
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param underlyingAsset underlying asset address
     * @param token Token address to monitor strike price
     * @param name Market name
     * @param strike Strike price
     * @param controller Controller address
     */
    event MarketCreated(
        uint256 indexed marketId,
        address premium,
        address collateral,
        address underlyingAsset,
        address token,
        string name,
        uint256 strike,
        address controller
    );

    /** @notice event is emitted when epoch is created
     * @param epochId epoch id derrived out of market id, start and end epoch
     * @param marketId Current market index
     * @param startEpoch Epoch start time
     * @param endEpoch Epoch end time
     * @param premium premium vault address
     * @param collateral collateral vault address
     * @param token Token address
     * @param strike Strike price
     * @param withdrawalFee Withdrawal fee
     */
    event EpochCreated(
        uint256 indexed epochId,
        uint256 indexed marketId,
        uint40 startEpoch,
        uint40 endEpoch,
        address premium,
        address collateral,
        address token,
        uint256 strike,
        uint16 withdrawalFee
    );

    /** @notice Controller is changed when event is emitted
     * @param marketId Target market index
     * @param controller Target controller address
     * @param premium Target premium vault address
     * @param collateral Target collateral vault address
     */
    event ControllerChanged(
        uint256 indexed marketId,
        address indexed controller,
        address premium,
        address collateral
    );

    /** @notice Oracle is changed when event is emitted
     * @param _marketId Target token address
     * @param _oracle Target oracle address
     */
    event OracleChanged(uint256 indexed _marketId, address _oracle);

    /** @notice Address whitelisted is changed when event is emitted
     * @param _wAddress whitelisted address
     * @param _marketId Target market index
     */
    event AddressWhitelisted(address _wAddress, uint256 indexed _marketId);

    /** @notice Treasury is changed when event is emitted
     * @param _treasury Treasury address
     */
    event TreasurySet(address _treasury);

    /** @notice New Controller is whitelisted when event is emitted
     * @param _controller Controller address
     */
    event ControllerWhitelisted(address _controller);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICarousel {
    // function name() external view  returns (string memory);
    // function symbol() external view  returns (string memory);
    // function asset() external view  returns (address);

    function token() external view returns (address);

    function strike() external view returns (uint256);

    function controller() external view returns (address);

    function counterPartyVault() external view returns (address);

    function getEpochConfig(uint256) external view returns (uint40, uint40);

    function totalAssets(uint256) external view returns (uint256);

    function epochExists(uint256 _id) external view returns (bool);

    function epochResolved(uint256 _id) external view returns (bool);

    function finalTVL(uint256 _id) external view returns (uint256);

    function claimTVL(uint256 _id) external view returns (uint256);

    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external;

    function deposit(uint256 id, uint256 amount, address receiver) external;

    function resolveEpoch(uint256 _id) external;

    function setClaimTVL(uint256 _id, uint256 _amount) external;

    function changeController(address _controller) external;

    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external;

    function whiteListAddress(address _treasury) external;

    function setCounterPartyVault(address _counterPartyVault) external;

    function setEpochNull(uint256 _id) external;

    function whitelistedAddresses(address _address)
        external
        view
        returns (bool);

    function enListInRollover(
        uint256 _assets,
        uint256 _epochId,
        address _receiver
    ) external;

    function deListInRollover(address _receiver) external;

    function mintDepositInQueue(uint256 _epochId, uint256 _operations) external;

    function mintRollovers(uint256 _epochId, uint256 _operations) external;

    function setEmissions(uint256 _epochId, uint256 _emissionsRate) external;

    function previewEmissionsWithdraw(uint256 _id, uint256 _assets) external;

    function changeRelayerFee(uint256 _relayerFee) external;

    function changeDepositFee(uint256 _depositFee) external;

    function changeTreasury(address) external;

    function balanceOfEmissoins(address _user, uint256 _epochId)
        external
        view
        returns (uint256);

    function emissionsToken() external view returns (address);

    function relayerFee() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function emissions(uint256 _epochId) external view returns (uint256);

    function cleanupRolloverQueue(address[] memory) external;

    function getDepositQueueLength() external view returns (uint256);

    function getRolloverQueueLength() external view returns (uint256);

   function getRolloverTVL() external view returns (uint256);

   function getDepositQueueTVL() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.17;

import "../Carousel/Carousel.sol";

library CarouselCreator {
    struct CarouselMarketConfiguration {
        bool isWETH;
        address assetAddress;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address treasury;
        address emissionsToken;
        uint256 relayerFee;
        uint256 depositFee;
        uint256 minQueueDeposit;
    }

    function createCarousel(CarouselMarketConfiguration memory _marketConfig)
        public
        returns (address)
    {
        return
            address(
                new Carousel(
                    Carousel.ConstructorArgs(
                        _marketConfig.isWETH,
                        _marketConfig.assetAddress,
                        _marketConfig.name,
                        _marketConfig.symbol,
                        _marketConfig.tokenURI,
                        _marketConfig.token,
                        _marketConfig.strike,
                        _marketConfig.controller,
                        _marketConfig.emissionsToken,
                        _marketConfig.relayerFee,
                        _marketConfig.depositFee,
                        _marketConfig.minQueueDeposit
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVaultV2 {
    // function name() external view  returns (string memory);
    // function symbol() external view  returns (string memory);
    // function asset() external view  returns (address);

    function token() external view returns (address);

    function strike() external view returns (uint256);

    function controller() external view returns (address);

    function counterPartyVault() external view returns (address);

    function getEpochConfig(uint256)
        external
        view
        returns (
            uint40,
            uint40,
            uint40
        );

    function totalAssets(uint256) external view returns (uint256);

    function epochExists(uint256 _id) external view returns (bool);

    function epochResolved(uint256 _id) external view returns (bool);

    function finalTVL(uint256 _id) external view returns (uint256);

    function claimTVL(uint256 _id) external view returns (uint256);

    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external;

    function resolveEpoch(uint256 _id) external;

    function setClaimTVL(uint256 _id, uint256 _amount) external;

    function changeController(address _controller) external;

    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external;

    function whiteListAddress(address _treasury) external;

    function setCounterPartyVault(address _counterPartyVault) external;

    function setEpochNull(uint256 _id) external;

    function whitelistedAddresses(address _address)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.17;

import "../VaultV2.sol";

library VaultV2Creator {
    struct MarketConfiguration {
        bool isWETH;
        address underlyingAsset;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address treasury;
    }

    function createVaultV2(MarketConfiguration memory _marketConfig)
        public
        returns (address)
    {
        return
            address(
                new VaultV2(
                    _marketConfig.isWETH,
                    _marketConfig.underlyingAsset,
                    _marketConfig.name,
                    _marketConfig.symbol,
                    _marketConfig.tokenURI,
                    _marketConfig.token,
                    _marketConfig.strike,
                    _marketConfig.controller
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../VaultV2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract Carousel is VaultV2 {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    // Earthquake parameters
    uint256 public relayerFee;
    uint256 public depositFee;
    uint256 public minQueueDeposit;
    IERC20 public immutable emissionsToken;

    mapping(address => uint256) public ownerToRollOverQueueIndex;
    QueueItem[] public rolloverQueue;
    QueueItem[] public depositQueue;
    mapping(uint256 => uint256) public rolloverAccounting;
    mapping(uint256 => uint256) public emissions;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _data  Carousel.ConstructorArgs struct containing the data to be used in the constructor;
     */
    constructor(ConstructorArgs memory _data)
        VaultV2(
            _data.isWETH,
            _data.assetAddress,
            _data.name,
            _data.symbol,
            _data.tokenURI,
            _data.token,
            _data.strike,
            _data.controller
        )
    {
        if (_data.relayerFee < 10000) revert RelayerFeeToLow();
        if (_data.depositFee > 250) revert BPSToHigh();
        if (_data.emissionsToken == address(0)) revert AddressZero();
        emissionsToken = IERC20(_data.emissionsToken);
        relayerFee = _data.relayerFee;
        depositFee = _data.depositFee;
        minQueueDeposit = _data.minQueueDeposit;

        // set epoch 0 to be allways available to deposit into Queue
        epochExists[0] = true;
        epochConfig[0] = EpochConfig({
            epochBegin: 10**10 * 40 - 7 days,
            epochEnd: 10**10 * 40,
            epochCreation: uint40(block.timestamp)
        });
        epochs.push(0);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit function
        @dev if receiver intends to deposit into queue and is contract, it must implement 1155 receiver interface otherwise funds will be stuck
        @param  _id epoch id, if 0 deposit will be queued;
        @param _assets   uint256 of how many assets you want to deposit;
        @param _receiver  address of the receiver of the shares provided by this function, that represent the ownership of the deposited asset;
     */
    function deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        public
        override(VaultV2)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        minRequiredDeposit(_assets, _id)
        nonReentrant
    {
        // make sure that epoch exists
        // epoch has not started (valid deposit period)
        // amount is enough to pay for relayer fees in case of queue deposit
        // function is not reentrant
        if (_receiver == address(0)) revert AddressZero();

        _asset().safeTransferFrom(msg.sender, address(this), _assets);
        // handles deposit logic for all cases (direct deposit, late deposit (if activated), queue deposit)
        _deposit(_id, _assets, _receiver);
    }

    function depositETH(uint256 _id, address _receiver)
        external
        payable
        override(VaultV2)
        minRequiredDeposit(msg.value, _id)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (!isWETH) revert CanNotDepositETH();
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();

        uint256 assets = msg.value;

        _deposit(_id, assets, _receiver);
    }

    /**
    @notice Withdraw entitled assets and burn shares of epoch
    @param  _id uint256 identifier of the epoch;
    @param _shares uint256 amount of shares to withdraw, this value will be used to calculate how many assets you are entitle to according the vaults claimTVL;
    @param _receiver Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param _owner Address of the _shares owner;
    @return assets How many assets the owner is entitled to, according to the epoch outcome;
     */
    function withdraw(
        uint256 _id,
        uint256 _shares,
        address _receiver,
        address _owner
    )
        external
        virtual
        override(VaultV2)
        epochIdExists(_id)
        epochHasEnded(_id)
        notRollingOver(_owner, _id, _shares)
        nonReentrant
        returns (uint256 assets)
    {
        // make sure that epoch exists
        // epoch is resolved
        // owners funds are not locked in rollover
        // function is not reentrant
        if (_receiver == address(0)) revert AddressZero();

        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        _burn(_owner, _id, _shares);
        uint256 entitledEmissions = previewEmissionsWithdraw(_id, _shares);
        if (epochNull[_id] == false) {
            assets = previewWithdraw(_id, _shares);
        } else {
            assets = _shares;
        }
        if (assets > 0) {
            SemiFungibleVault.asset.safeTransfer(_receiver, assets);
        }
        if (entitledEmissions > 0) {
            emissionsToken.safeTransfer(_receiver, entitledEmissions);
        }

        emit WithdrawWithEmissions(
            msg.sender,
            _receiver,
            _owner,
            _id,
            _shares,
            assets,
            entitledEmissions
        );

        return assets;
    }

    /*///////////////////////////////////////////////////////////////
                        TRANSFER LOGIC
        add notRollingOver modifier to all transfer functions      
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override notRollingOver(from, id, amount) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address, /*from*/
        address, /*to*/
        uint256[] memory, /*ids*/
        uint256[] memory, /*amounts*/
        bytes memory /*data*/
    ) public pure override {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                        Carousel Rollover Logic
    //////////////////////////////////////////////////////////////*/

    /** @notice enlists in rollover queue
        @dev user needs to have >= _assets in epoch (_epochId)
        @param  _epochId epoch id
        @param _shares   uint256 amount of shares to rollover;
        @param _receiver  address of the receiver of the emissions;
     */
    function enlistInRollover(
        uint256 _epochId,
        uint256 _shares,
        address _receiver
    ) public epochIdExists(_epochId) {
        // check if sender is approved by owner
        if (
            msg.sender != _receiver &&
            isApprovedForAll(_receiver, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _receiver);
        // check if user has enough balance
        if (balanceOf(_receiver, _epochId) < _shares)
            revert InsufficientBalance();
        // to prevent spamming rollover queue and to ensure relayerFee can be payed,
        // shares rolled over must be worth at least minQueueDeposit
        if (!epochResolved[_epochId] && (_shares < minQueueDeposit))
            revert MinDeposit();
        else if (
            epochResolved[_epochId] &&
            (previewWithdraw(_epochId, _shares) < minQueueDeposit)
        ) revert MinDeposit();

        // check if user has already queued up a rollover
        if (ownerToRollOverQueueIndex[_receiver] != 0) {
            uint256 index = getRolloverIndex(_receiver);
            // if so, update the queue
            rolloverQueue[index].shares = _shares;
            rolloverQueue[index].epochId = _epochId;
        } else {
            // if not, add to queue
            rolloverQueue.push(
                QueueItem({
                    shares: _shares,
                    receiver: _receiver,
                    epochId: _epochId
                })
            );
            // index will allways be higher than 0
            ownerToRollOverQueueIndex[_receiver] = rolloverQueue.length;
        }

        emit RolloverQueued(_receiver, _shares, _epochId);
    }

    /** @notice delists from rollover queue
        @param _owner address that is delisting from rollover queue
     */
    function delistInRollover(address _owner) public {
        // @note
        // its not possible for users to delete the QueueItem from the array because
        // during rollover, earlier users in rollover queue, can grief attack later users by deleting their queue item
        // instead we just set the assets to 0 and the epochId to 0 as a flag to indicate that the user is no longer in the queue

        // check if user is enlisted in rollover queue
        if (!isEnlistedInRolloverQueue(_owner)) revert NoRolloverQueued();
        // check if sender is approved by owner
        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        // set assets to 0 but keep the queue item
        uint256 index = getRolloverIndex(_owner);
        rolloverQueue[index].shares = 0;
        rolloverQueue[index].epochId = 0;
    }

    /** @notice mints deposit in rollover queue
        @param _epochId epoch id
        @param _operations  uint256 of how many operations to execute;
     */
    function mintDepositInQueue(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // make sure there is already a new epoch set
        // epoch has not started
        QueueItem[] memory queue = depositQueue;
        uint256 length = depositQueue.length;

        // dont allow minting if epochId is 0
        if (_epochId == 0) revert InvalidEpochId();

        if (length == 0) revert OverflowQueue();
        // relayers can always input a very big number to mint all deposit queues, without the need to read depostQueue length first
        if (_operations > length) _operations = length;

        // queue is executed from the tail to the head
        // get last index of queue
        uint256 i = length - 1;
        uint256 relayerFeeShortfall;
        while ((length - _operations) <= i) {
            // this loop impelements FILO (first in last out) stack to reduce gas cost and improve code readability
            // changing it to FIFO (first in first out) would require more code changes and would be more expensive
            // @note non neglectable min-deposit creates barriers for attackers to DDOS the queue

            uint256 assetsToDeposit = queue[i].shares;

            if (depositFee > 0) {
                (
                    uint256 feeAmount,
                    uint256 assetsAfterFee
                ) = getEpochDepositFee(_epochId, assetsToDeposit);
                assetsToDeposit = assetsAfterFee;
                _asset().safeTransfer(treasury(), feeAmount);
            }

            // if minDeposit has chagned during QueueItem is in the queue and relayerFee is now higher than deposit amount
            // mint 0 and pay relayerFeeShortfall to relayer
            if (assetsToDeposit > relayerFee) {
                assetsToDeposit -= relayerFee;
            } else {
                relayerFeeShortfall += (relayerFee - assetsToDeposit);
                assetsToDeposit = 0;
            }

            _mintShares(queue[i].receiver, _epochId, assetsToDeposit);
            emit Deposit(
                msg.sender,
                queue[i].receiver,
                _epochId,
                assetsToDeposit
            );
            depositQueue.pop();
            if (i == 0) break;
            unchecked {
                i--;
            }
        }

        emit RelayerMinted(_epochId, _operations);

        asset.safeTransfer(
            msg.sender,
            (_operations * relayerFee) - relayerFeeShortfall
        );
    }

    /** @notice mints for rollovers
        @param _epochId epoch id
        @param _operations  uint256 of how many operations to execute;
     */
    function mintRollovers(uint256 _epochId, uint256 _operations)
        external
        epochIdExists(_epochId)
        epochHasNotStarted(_epochId)
        nonReentrant
    {
        // epoch has not started
        // dont allow rollover if epochId is 0
        if (_epochId == 0) revert InvalidEpochId();

        uint256 length = rolloverQueue.length;
        uint256 index = rolloverAccounting[_epochId];

        // revert if queue is empty or operations are more than queue length
        if (length == 0) revert OverflowQueue();

        if (_operations > length || (index + _operations) > length)
            _operations = length - index;

        // prev epoch is resolved
        if (!epochResolved[epochs[epochs.length - 2]])
            revert EpochNotResolved();

        // make sure epoch is next epoch
        if (epochs[epochs.length - 1] != _epochId) revert InvalidEpochId();

        QueueItem[] memory queue = rolloverQueue;

        // account for how many operations have been done
        uint256 prevIndex = index;
        uint256 executions = 0;

        while ((index - prevIndex) < (_operations)) {
            // only roll over if last epoch is resolved and user rollover position is valid
            if (
                epochResolved[queue[index].epochId] && queue[index].shares > 0
            ) {
                uint256 entitledAmount = previewWithdraw(
                    queue[index].epochId,
                    queue[index].shares
                );

                // mint only if user won epoch he is rolling over
                if (entitledAmount > queue[index].shares) {
                    // skip the rollover for the user if the assets cannot cover the relayer fee instead of revert.
                    if (entitledAmount <= relayerFee) {
                        index++;
                        continue;
                    }

                    // to calculate originalDepositValue get the diff between shares and value of shares
                    // convert this value amount value back to shares
                    // subtract from assets
                    uint256 originalDepositValue = queue[index].shares -
                        previewAmountInShares(
                            queue[index].epochId,
                            (entitledAmount - queue[index].shares) // subtract profit from share value
                        );
                    // @note we know shares were locked up to this point
                    _burn(
                        queue[index].receiver,
                        queue[index].epochId,
                        originalDepositValue
                    );
                    // @note emission token is a known token which has no before transfer hooks which makes transfer safer
                    emissionsToken.safeTransfer(
                        queue[index].receiver,
                        previewEmissionsWithdraw(
                            queue[index].epochId,
                            originalDepositValue
                        )
                    );

                    emit WithdrawWithEmissions(
                        msg.sender,
                        queue[index].receiver,
                        queue[index].receiver,
                        _epochId,
                        originalDepositValue,
                        entitledAmount,
                        previewEmissionsWithdraw(
                            queue[index].epochId,
                            originalDepositValue
                        )
                    );
                    uint256 amountToMint = queue[index].shares - relayerFee;
                    _mintShares(queue[index].receiver, _epochId, amountToMint);
                    emit Deposit(
                        msg.sender,
                        queue[index].receiver,
                        _epochId,
                        amountToMint
                    );
                    rolloverQueue[index].shares = amountToMint;
                    rolloverQueue[index].epochId = _epochId;
                    // only pay relayer for successful mints
                    executions++;
                }
            }
            index++;
        }

        if (executions > 0) rolloverAccounting[_epochId] = index;

        if (executions * relayerFee > 0)
            asset.safeTransfer(msg.sender, executions * relayerFee);

        emit RelayerMinted(_epochId, executions);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MUTATIVE LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice deposits assets into epoch
        @param _id epoch id
        @param _assets amount of assets to deposit
        @param _receiver address of receiver
     */
    function _deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    ) internal {
        // mint logic, either in queue or direct deposit
        if (_id != 0) {
            uint256 assetsToDeposit = _assets;

            if (depositFee > 0) {
                (
                    uint256 feeAmount,
                    uint256 assetsAfterFee
                ) = getEpochDepositFee(_id, _assets);
                assetsToDeposit = assetsAfterFee;
                _asset().safeTransfer(treasury(), feeAmount);
            }

            _mintShares(_receiver, _id, assetsToDeposit);

            emit Deposit(msg.sender, _receiver, _id, _assets);
        } else {
            depositQueue.push(
                QueueItem({shares: _assets, receiver: _receiver, epochId: _id})
            );

            emit DepositInQueue(msg.sender, _receiver, _id, _assets);
        }
    }

    /** @notice mints shares of vault for user
        @param to address of receiver
        @param id epoch id
        @param amount amount of shares to mint
     */
    function _mintShares(
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        _mint(to, id, amount, EMPTY);
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice This function is called by the controller if the epoch has started, but the counterparty vault has no value. In this case the users can withdraw their deposit. Additionally, emissions are transferred to the treasury. 
    @param  _id uint256 identifier of the epoch
     */
    function setEpochNull(uint256 _id)
        public
        override
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {
        epochNull[_id] = true;
        if (emissions[_id] > 0) {
            emissionsToken.safeTransfer(treasury(), emissions[_id]);
            emissions[_id] = 0;
        }
    }

    /** @notice sets emissions
     * @param _epochId epoch id
     * @param _emissionAmount emissions rate
     */
    function setEmissions(uint256 _epochId, uint256 _emissionAmount)
        external
        onlyFactory
        epochIdExists(_epochId)
    {
        emissions[_epochId] = _emissionAmount;
    }

    /** @notice changes relayer fee
     * @param _relayerFee relayer fee
     */
    function changeRelayerFee(uint256 _relayerFee) external onlyFactory {
        relayerFee = _relayerFee;
    }

    /** @notice changes deposit fee
     * @param _depositFee deposit fee
     */
    function changeDepositFee(uint256 _depositFee) external onlyFactory {
        depositFee = _depositFee;
    }

    /** @notice cleans up rollover queue
     * @dev this function can only be called if there is no active deposit window
     * @param _addressesToDelist addresses to delist
     */
    function cleanUpRolloverQueue(address[] memory _addressesToDelist)
        external
        onlyFactory
        epochHasStarted(epochs[epochs.length - 1])
    {
        // check that there is no active deposit window;
        for (uint256 i = 0; i < _addressesToDelist.length; i++) {
            address owner = _addressesToDelist[i];
            uint256 index = ownerToRollOverQueueIndex[owner];
            if (index == 0) continue;
            uint256 queueIndex = index - 1;
            if (rolloverQueue[queueIndex].shares == 0) {
                // overwrite the item to be removed with the last item in the queue
                rolloverQueue[queueIndex] = rolloverQueue[
                    rolloverQueue.length - 1
                ];
                // remove the last item in the queue
                rolloverQueue.pop();
                // update the index of prev last user ( mapping index is allways array index + 1)
                ownerToRollOverQueueIndex[rolloverQueue[queueIndex].receiver] =
                    queueIndex +
                    1;
                // remove receiver from index mapping
                delete ownerToRollOverQueueIndex[owner];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getter Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice calculates fee percent based on time
     * @param minX min x value
     * @param maxX max x value
     */
    function calculateFeePercent(int256 minX, int256 maxX)
        public
        view
        returns (uint256 _y)
    {
        /**
         * Two Point Form
         * https://www.cuemath.com/geometry/two-point-form/
         * https://ethereum.stackexchange.com/a/143172
         */
        // minY will always be 0 thats why is (maxY - minY) shorten to maxY
        int256 maxY = int256(depositFee) * int256(FixedPointMathLib.WAD);
        _y = uint256( // cast to uint256
            ((((maxY) / (maxX - minX)) * (int256(block.timestamp) - maxX)) +
                maxY) / (int256(FixedPointMathLib.WAD)) // two point math // scale down
        );
    }

    /** @notice returns the rollover index
     * @dev will revert if user is not in rollover queue
     * @param _owner address of the owner
     * @return rollover index
     */
    function getRolloverIndex(address _owner) public view returns (uint256) {
        return ownerToRollOverQueueIndex[_owner] - 1;
    }

    /** @notice retruns deposit fee at this time
     * @param _id epoch id
     * @param _assets amount of assets
     * @return feeAmount fee amount
     * @return assetsAfterFee assets after fee
     */
    function getEpochDepositFee(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 feeAmount, uint256 assetsAfterFee)
    {
        (uint256 maxX, , uint256 minX) = getEpochConfig(_id);
        // deposit fee is calcualted linearly between time of epoch creation and epoch starting (deposit window)
        // this is because late depositors have an informational advantage
        uint256 fee = calculateFeePercent(int256(minX), int256(maxX));
        // min minRequiredDeposit modifier ensures that _assets has high enough value to not devide by 0
        // 0.5% = multiply by 10000 then divide by 50
        feeAmount = _assets.mulDivDown(fee, 10000);
        assetsAfterFee = _assets - feeAmount;
    }

    /** @notice returns the emissions to withdraw
     * @param _id epoch id
     * @param _assets amount of assets to withdraw
     * @return entitledAmount amount of emissions to withdraw
     */
    function previewEmissionsWithdraw(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 entitledAmount)
    {
        entitledAmount = _assets.mulDivDown(emissions[_id], finalTVL[_id]);
    }

    /** @notice returns the emissions to withdraw
     * @param _id epoch id
     * @param _assets amount of shares
     * @return entitledShareAmount amount of emissions to withdraw
     */
    function previewAmountInShares(uint256 _id, uint256 _assets)
        public
        view
        returns (uint256 entitledShareAmount)
    {
        if (claimTVL[_id] != 0) {
            entitledShareAmount = _assets.mulDivDown(
                finalTVL[_id],
                claimTVL[_id]
            );
        } else {
            entitledShareAmount = 0;
        }
    }

    /** @notice returns the deposit queue length
     * @return queue length for the deposit
     */
    function getDepositQueueLength() public view returns (uint256) {
        return depositQueue.length;
    }

    /** @notice returns the queue length for the rollover
     * @return queue length for the rollover
     */
    function getRolloverQueueLength() public view returns (uint256) {
        return rolloverQueue.length;
    }

    /** @notice returns the total value locked in the rollover queue
     * @return tvl total value locked in the rollover queue
     */
    function getRolloverTVLByEpochId(uint256 _epochId)
        public
        view
        returns (uint256 tvl)
    {
        for (uint256 i = 0; i < rolloverQueue.length; i++) {
            uint256 assets = 
            epochResolved[rolloverQueue[i].epochId] ?
            previewWithdraw(
                rolloverQueue[i].epochId,
                rolloverQueue[i].shares
            ) : rolloverQueue[i].shares;

            if (
                rolloverQueue[i].epochId == _epochId &&
                (assets >= rolloverQueue[i].shares) // check if position is in profit and getting rollover
            ) {
                tvl += assets;
            }
        }
    }

    function getRolloverTVL() public view returns (uint256 tvl) {
        for (uint256 i = 0; i < rolloverQueue.length; i++) {

             uint256 assets = 
            epochResolved[rolloverQueue[i].epochId] ?
            previewWithdraw(
                rolloverQueue[i].epochId,
                rolloverQueue[i].shares
            ) : rolloverQueue[i].shares;

            if (
                assets >= rolloverQueue[i].shares // check if position is in profit and getting rollover
            ) {
                tvl += assets;
            }
        }
    }

    function getRolloverQueueItem(uint256 _index)
        public
        view
        returns (
            address receiver,
            uint256 shares,
            uint256 epochId
        )
    {
        receiver = rolloverQueue[_index].receiver;
        shares = rolloverQueue[_index].shares;
        epochId = rolloverQueue[_index].epochId;
    }

    /** @notice returns users rollover balance and epoch which is rolling over
     * @param _owner address of the user
     * @return shares balance of the user in rollover position
     * @return epochId epoch id
     */
    function getRolloverPosition(address _owner)
        public
        view
        returns (uint256 shares, uint256 epochId)
    {
        if (!isEnlistedInRolloverQueue(_owner)) {
            return (0, 0);
        }
        uint256 index = getRolloverIndex(_owner);
        shares = rolloverQueue[index].shares;
        epochId = rolloverQueue[index].epochId;
    }

    /** @notice returns is user is enlisted in the rollover queue
     * @param _owner address of the user
     * @return bool is user enlisted in the rollover queue
     */
    function isEnlistedInRolloverQueue(address _owner)
        public
        view
        returns (bool)
    {
        if (ownerToRollOverQueueIndex[_owner] == 0) {
            return false;
        }
        return rolloverQueue[getRolloverIndex(_owner)].shares != 0;
    }

    /** @notice returns the total value locked in the deposit queue
     * @return tvl total value locked in the deposit queue
     */
    function getDepositQueueTVL() public view returns (uint256 tvl) {
        for (uint256 i = 0; i < depositQueue.length; i++) {
            tvl += depositQueue[i].shares;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct QueueItem {
        uint256 shares;
        address receiver;
        uint256 epochId;
    }

    struct ConstructorArgs {
        bool isWETH;
        address assetAddress;
        string name;
        string symbol;
        string tokenURI;
        address token;
        uint256 strike;
        address controller;
        address emissionsToken;
        uint256 relayerFee;
        uint256 depositFee;
        uint256 minQueueDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice checks if deposit is at least min required
     * @param _assets amount of assets to deposit
     * @param _epochId epoch id
     */
    modifier minRequiredDeposit(uint256 _assets, uint256 _epochId) {
        if (_epochId == 0 && _assets < minQueueDeposit) revert MinDeposit();
        _;
    }

    /** @notice checks if not rolling over
     * @param _receiver address of the receiver
     * @param _epochId epoch id
     * @param _shares amount of assets to deposit
     */
    modifier notRollingOver(
        address _receiver,
        uint256 _epochId,
        uint256 _shares
    ) {
        if (isEnlistedInRolloverQueue(_receiver)) {
            QueueItem memory item = rolloverQueue[getRolloverIndex(_receiver)];
            if (
                item.epochId == _epochId &&
                (balanceOf(_receiver, _epochId) - item.shares) < _shares
            ) revert AlreadyRollingOver();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MinDeposit();
    error OverflowQueue();
    error AlreadyRollingOver();
    error InvalidEpochId();
    error InsufficientBalance();
    error NoRolloverQueued();
    error RelayerFeeToLow();
    error BPSToHigh();
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event WithdrawWithEmissions(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares,
        uint256 emissions
    );

    /** @notice emitted when a deposit is queued
     * @param sender the address of the sender
     * @param receiver the address of the receiver
     * @param epochId the epoch id
     * @param shares the amount of assets
     */
    event DepositInQueue(
        address indexed sender,
        address indexed receiver,
        uint256 epochId,
        uint256 shares
    );

    /** @notice emitted when shares are minted by relayer
     * @param epochId the epoch id
     * @param operations how many positions were minted
     */
    event RelayerMinted(uint256 epochId, uint256 operations);

    /** @notice emitted when a rollover is queued
     * @param sender the address of the sender
     * @param shares the amount of assets
     * @param epochId the epoch id
     */
    event RolloverQueued(
        address indexed sender,
        uint256 shares,
        uint256 epochId
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SemiFungibleVault.sol";
import {IVaultV2} from "./interfaces/IVaultV2.sol";
import {IVaultFactoryV2} from "./interfaces/IVaultFactoryV2.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

/// @author Y2K Finance Team

contract VaultV2 is IVaultV2, SemiFungibleVault, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/

    // Earthquake parameters
    address public immutable token;
    uint256 public immutable strike;
    // Earthquake bussiness logic
    bool public immutable isWETH;
    address public counterPartyVault;
    address public factory;
    address public controller;
    uint256[] public epochs;

    mapping(uint256 => uint256) public finalTVL;
    mapping(uint256 => uint256) public claimTVL;
    mapping(uint256 => uint256) public epochAccounting;
    mapping(uint256 => EpochConfig) public epochConfig;
    mapping(uint256 => bool) public epochResolved;
    mapping(uint256 => bool) public epochExists;
    mapping(uint256 => bool) public epochNull;
    mapping(address => bool) public whitelistedAddresses;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice constructor
        @param _assetAddress  address of the asset that will be used as collateral;
        @param _name  string representing the name of the vault;
        @param _symbol  string representing the symbol of the vault;
        @param _tokenURI  string representing the tokenURI of the vault;
        @param _token  address of the token that will be used as collateral;
        @param _strike  uint256 representing the strike price of the vault;
        @param _controller  address of the controller of the vault;
     */
    constructor(
        bool _isWETH,
        address _assetAddress,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _token,
        uint256 _strike,
        address _controller
    ) SemiFungibleVault(IERC20(_assetAddress), _name, _symbol, _tokenURI) {
        if (_controller == address(0)) revert AddressZero();
        if (_token == address(0)) revert AddressZero();
        if (_assetAddress == address(0)) revert AddressZero();
        token = _token;
        strike = _strike;
        factory = msg.sender;
        controller = _controller;
        isWETH = _isWETH;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @param  _id uint256 epoch identifier;
        @param  _assets uint256 amount of assets the user wants to deposit denominated in underlying asset decimals;
        @param _receiver address of the receiver of the shares minted;
     */
    function deposit(
        uint256 _id,
        uint256 _assets,
        address _receiver
    )
        public
        virtual
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (_receiver == address(0)) revert AddressZero();
        SemiFungibleVault.asset.safeTransferFrom(
            msg.sender,
            address(this),
            _assets
        );

        _mint(_receiver, _id, _assets, EMPTY);

        emit Deposit(msg.sender, _receiver, _id, _assets);
    }

    /**
        @notice Deposit ETH function
        @param  _id  uint256 representing the id of the epoch;
       @param _receiver address of the receiver of the shares minted;
     */
    function depositETH(uint256 _id, address _receiver)
        external
        payable
        virtual
        epochIdExists(_id)
        epochHasNotStarted(_id)
        nonReentrant
    {
        if (!isWETH) revert CanNotDepositETH();
        require(msg.value > 0, "ZeroValue");
        if (_receiver == address(0)) revert AddressZero();

        IWETH(address(asset)).deposit{value: msg.value}();
        _mint(_receiver, _id, msg.value, EMPTY);

        emit Deposit(msg.sender, _receiver, _id, msg.value);
    }

    /**
    @notice Withdraw entitled assets and burn shares of epoch
    @param  _id uint256 identifier of the epoch;
    @param _shares uint256 amount of shares to withdraw, this value will be used to calculate how many assets you are entitle to according the vaults claimTVL;
    @param _receiver Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset;
    @param _owner Address of the _shares owner;
    @return assets How many assets the owner is entitled to, according to the epoch outcome;
     */
    function withdraw(
        uint256 _id,
        uint256 _shares,
        address _receiver,
        address _owner
    )
        external
        virtual
        override(SemiFungibleVault)
        epochIdExists(_id)
        epochHasEnded(_id)
        nonReentrant
        returns (uint256 assets)
    {
        if (_receiver == address(0)) revert AddressZero();

        if (
            msg.sender != _owner &&
            isApprovedForAll(_owner, msg.sender) == false
        ) revert OwnerDidNotAuthorize(msg.sender, _owner);

        _burn(_owner, _id, _shares);

        if (epochNull[_id] == false) {
            assets = previewWithdraw(_id, _shares);
        } else {
            assets = _shares;
        }
        if (assets > 0) {
            SemiFungibleVault.asset.safeTransfer(_receiver, assets);
        }

        emit Withdraw(msg.sender, _receiver, _owner, _id, _shares, assets);

        return assets;
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @notice returns total assets for the id of given epoch
        @param  _id uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000;
     */
    function totalAssets(uint256 _id)
        public
        view
        override(SemiFungibleVault, IVaultV2)
        returns (uint256)
    {
        // epochIdExists(_id)
        return totalSupply(_id);
    }

    /*///////////////////////////////////////////////////////////////
                           FACTORY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Function to set the epoch, only the factory can call this function
    @param  _epochBegin uint40 in UNIX timestamp, representing the begin date of the epoch
    @param  _epochEnd uint40 in UNIX timestamp, representing the end date of the epoch
    @param  _epochId uint256 id representing the epoch
     */
    function setEpoch(
        uint40 _epochBegin,
        uint40 _epochEnd,
        uint256 _epochId
    ) external onlyFactory {
        if (_epochId == 0 || _epochBegin == 0 || _epochEnd == 0)
            revert InvalidEpoch();
        if (epochExists[_epochId] == true) revert EpochAlreadyExists();

        if (_epochBegin >= _epochEnd) revert EpochEndMustBeAfterBegin();

        epochExists[_epochId] = true;

        epochConfig[_epochId] = EpochConfig({
            epochBegin: _epochBegin,
            epochEnd: _epochEnd,
            epochCreation: uint40(block.timestamp)
        });
        epochs.push(_epochId);
    }

    /**
    @notice Factory function, changes controller address
    @param _controller New controller address
     */
    function changeController(address _controller) public onlyFactory {
        if (_controller == address(0)) revert AddressZero();
        controller = _controller;
    }

    /**
    @notice Factory function, whitelist address
    @param _wAddress whitelist destination address 
    */
    function whiteListAddress(address _wAddress) public onlyFactory {
        if (_wAddress == address(0)) revert AddressZero();
        whitelistedAddresses[_wAddress] = !whitelistedAddresses[_wAddress];
    }

    /**
    @notice Factory function, changes _counterPartyVault address
    @param _counterPartyVault New _counterPartyVault address
     */
    function setCounterPartyVault(address _counterPartyVault)
        external
        onlyFactory
    {
        if (_counterPartyVault == address(0)) revert AddressZero();
        counterPartyVault = _counterPartyVault;
    }

    /*///////////////////////////////////////////////////////////////
                         CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Controller can call this function to resolve the epoch, this function will set the epoch as ended and store the deposited TVL of the epoch
    @param  _id identifier of the epoch
     */
    function resolveEpoch(uint256 _id)
        external
        onlyController
        epochIdExists(_id)
        epochHasStarted(_id)
    {
        if (epochResolved[_id]) revert EpochAlreadyEnded();
        epochResolved[_id] = true;
        finalTVL[_id] = totalAssets(_id);
    }

    /**
    solhint-disable-next-line max-line-length
    @notice Controller can call after the epoch has ended, this function allows the transfer of tokens to the counterparty vault or treasury. Controller is trusted to do correct accounting. 
    @param  _id uint256 identifier of the epoch
    @param _amount amount that is send to destination
    @param _receiver address of counterparty vault or treasury
    */
    function sendTokens(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external onlyController epochIdExists(_id) epochHasEnded(_id) {
        if (_amount > finalTVL[_id]) revert AmountExceedsTVL();
        if (epochAccounting[_id] + _amount > finalTVL[_id])
            revert AmountExceedsTVL();
        if (
            !whitelistedAddresses[_receiver] &&
            _receiver != counterPartyVault &&
            _receiver != treasury()
        ) revert DestinationNotAuthorized(_receiver);
        epochAccounting[_id] += _amount;
        SemiFungibleVault.asset.safeTransfer(_receiver, _amount);
    }

    /**
    @notice Controller can call after the epoch has ended, this function stores the value that the holders of the epoch are entiteld to. The value is determined on the controller side
    @param  _id uint256 identifier of the epoch
    @param _claimTVL uint256 representing the TVL the vault has, storing this value in a mapping
     */
    function setClaimTVL(uint256 _id, uint256 _claimTVL)
        external
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {
        claimTVL[_id] = _claimTVL;
    }

    /**
    @notice This function is called by the controller if the epoch has started, but the counterparty vault has no value. In this case the users can withdraw their deposit.
    @param  _id uint256 identifier of the epoch
     */
    function setEpochNull(uint256 _id)
        public
        virtual
        onlyController
        epochIdExists(_id)
        epochHasEnded(_id)
    {
        epochNull[_id] = true;
    }

    /*///////////////////////////////////////////////////////////////
                         LOOKUP FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  _id uint256 epoch identifier
        @param _shares amount of user shares to withdraw
     */
    function previewWithdraw(uint256 _id, uint256 _shares)
        public
        view
        override(SemiFungibleVault)
        returns (uint256 entitledAssets)
    {
        // entitledAmount amount is derived from the claimTVL and the finalTVL
        // if user deposited 1000 assets and the claimTVL is 50% lower than finalTVL, the user is entitled to 500 assets
        // if user deposited 1000 assets and the claimTVL is 50% higher than finalTVL, the user is entitled to 1500 assets
        entitledAssets = _shares.mulDivDown(claimTVL[_id], finalTVL[_id]);
    }

    /** @notice Lookup total epochs length
     */
    function getEpochsLength() public view returns (uint256) {
        return epochs.length;
    }

    /** @notice Lookup all set epochs
     */
    function getAllEpochs() public view returns (uint256[] memory) {
        return epochs;
    }

    /** @notice Lookup epoch begin and end
        @param _id id hashed from marketIndex, epoch begin and end and casted to uint256;
     */
    function getEpochConfig(uint256 _id)
        public
        view
        returns (
            uint40 epochBegin,
            uint40 epochEnd,
            uint40 epochCreation
        )
    {
        epochBegin = epochConfig[_id].epochBegin;
        epochEnd = epochConfig[_id].epochEnd;
        epochCreation = epochConfig[_id].epochCreation;
    }

    function treasury() public view returns (address) {
        return IVaultFactoryV2(factory).treasury();
    }

    function _asset() internal view returns (IERC20) {
        return asset;
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct EpochConfig {
        uint40 epochBegin;
        uint40 epochEnd;
        uint40 epochCreation;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only factory addresses can call functions that use this modifier
     */
    modifier onlyFactory() {
        if (msg.sender != factory) revert AddressNotFactory(msg.sender);
        _;
    }

    /** @notice Only controller addresses can call functions that use this modifier
     */
    modifier onlyController() {
        if (msg.sender != controller) revert AddressNotController(msg.sender);
        _;
    }

    /** @notice You can only call functions that use this modifier before the epoch has started
     */
    modifier epochHasNotStarted(uint256 _id) {
        if (block.timestamp > epochConfig[_id].epochBegin)
            revert EpochAlreadyStarted();
        _;
    }

    /** @notice You can only call functions that use this modifier after the epoch has started
     */
    modifier epochHasStarted(uint256 _id) {
        if (block.timestamp < epochConfig[_id].epochBegin)
            revert EpochNotStarted();
        _;
    }

    /** @notice Check if epoch exists
     */
    modifier epochIdExists(uint256 id) {
        if (!epochExists[id]) revert EpochDoesNotExist();
        _;
    }

    /** @notice You can only call functions that use this modifier after the epoch has ended
     */
    modifier epochHasEnded(uint256 id) {
        if (!epochResolved[id]) revert EpochNotResolved();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AddressZero();
    error AddressNotFactory(address _contract);
    error AddressNotController(address _contract);
    error EpochDoesNotExist();
    error EpochAlreadyStarted();
    error EpochNotResolved();
    error EpochAlreadyEnded();
    error EpochNotStarted();
    error ZeroValue();
    error OwnerDidNotAuthorize(address _sender, address _owner);
    error EpochEndMustBeAfterBegin();
    error EpochAlreadyExists();
    error DestinationNotAuthorized(address _counterparty);
    error AmountExceedsTVL();
    error AlreadyInitialized();
    error InvalidEpoch();
    error CanNotDepositETH();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155Supply} from "./CustomERC1155/ERC1155Supply.sol";
import {ERC1155} from "./CustomERC1155/ERC1155.sol";
import {ISemiFungibleVault} from "./interfaces/ISemiFungibleVault.sol";

/// @author MiguelBits
/// @author SlumDog

abstract contract SemiFungibleVault is ISemiFungibleVault, ERC1155Supply {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES AND STORAGE
    //////////////////////////////////////////////////////////////*/
    IERC20 public immutable asset;
    string public name;
    string public symbol;
    bytes internal constant EMPTY = "";

    /** @notice Contract constructor
     * @param _asset ERC20 token
     * @param _name Token name
     * @param _symbol Token symbol
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        asset = _asset;
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /** @notice Triggers deposit into vault and mints shares for receiver
     * @param id Vault id
     * @param assets Amount of tokens to deposit
     * @param receiver Receiver of shares
     */
    function deposit(
        uint256 id,
        uint256 assets,
        address receiver
    ) public virtual {
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, id, assets, EMPTY);

        emit Deposit(msg.sender, receiver, id, assets);
    }

    /** @notice Triggers withdraw from vault and burns receivers' shares
     * @param id Vault id
     * @param assets Amount of tokens to withdraw
     * @param receiver Receiver of assets
     * @param owner Owner of shares
     * @return shares Amount of shares burned
     */
    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares) {
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Only owner can withdraw, or owner has approved receiver for all"
        );

        shares = previewWithdraw(id, assets);

        _burn(owner, id, shares);

        emit Withdraw(msg.sender, receiver, owner, id, assets, shares);
        asset.safeTransfer(receiver, assets);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**@notice Returns total assets for token
     * @param  _id uint256 token id of token
     */
    function totalAssets(uint256 _id) public view virtual returns (uint256) {
        return totalSupply(_id);
    }

    /**
        @notice Shows assets conversion output from withdrawing assets
        @param  id uint256 token id of token
        @param assets Total number of assets
     */
    function previewWithdraw(uint256 id, uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {}
}

pragma solidity 0.8.17;

interface IVaultFactoryV2 {
    function createNewMarket(
        uint256 fee,
        address token,
        address depeg,
        uint256 beginEpoch,
        uint256 endEpoch,
        address oracle,
        string memory name
    ) external returns (address);

    function treasury() external view returns (address);

    function getVaults(uint256) external view returns (address[2] memory);

    function getEpochFee(uint256) external view returns (uint16);

    function marketToOracle(uint256 _marketId) external view returns (address);

    function transferOwnership(address newOwner) external;

    function marketIdToVaults(uint256 _marketId) external view returns (address[2] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "./ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        // remove _doSafeTransferAcceptanceCheck to prevent reverting in queue
        // if receiver is a contract and does not implement the ERC1155Holder interface funds will be stuck
        // _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISemiFungibleVault {
    function asset() external view returns (IERC20);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function deposit(
        uint256,
        uint256,
        address
    ) external;

    function withdraw(
        uint256,
        uint256,
        address,
        address
    ) external returns (uint256);

    function totalAssets(uint256) external returns (uint256);

    function previewWithdraw(uint256, uint256) external returns (uint256);

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /** @notice Deposit into vault when event is emitted
     * @param caller Address of deposit caller
     * @param owner receiver who will own of the tokens representing this deposit
     * @param id Vault id
     * @param assets Amount of owner assets to deposit into vault
     */
    event Deposit(
        address caller,
        address indexed owner,
        uint256 indexed id,
        uint256 assets
    );

    /** @notice Withdraw from vault when event is emitted
     * @param caller Address of withdraw caller
     * @param receiver Address of receiver of assets
     * @param owner Owner of shares
     * @param id Vault id
     * @param assets Amount of owner assets to withdraw from vault
     * @param shares Amount of owner shares to burn
     */
    event Withdraw(
        address caller,
        address receiver,
        address indexed owner,
        uint256 indexed id,
        uint256 assets,
        uint256 shares
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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