// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;


import "../../interfaces/IRangoMiddlewareWhitelists.sol";

// this contract will be used as a storage for whitelists shared between all middlewares deployed on a chain
contract RangoMiddlewaresWhitelistsStorage is IRangoMiddlewareWhitelists {
    /// @dev keccak256("exchange.rango.middleware.whitelists")
    bytes32 internal constant WHITELISTS_MIDDLEWARES_CONTRACT_NAMESPACE = hex"a6cb7cdbf6c80c36973b6759ac7e3de6e6100713791e48570eff93e6c5467c4c";

    struct WhitelistsMiddlewaresStorage {
        address owner;
        address rangoDiamond;
        address WETH;
        mapping(address => bool) whitelistContracts;
        mapping (address => bool) whitelistMessagingContracts;
    }

    /// @notice Emits when wrapped token address is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event WethAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emits when rango diamond address on the corresponding chain is updated
    /// @param _oldAddress The previous address
    /// @param _newAddress The new address
    event RangoDiamondAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emits when a contract address is inserted in whitelists mapping
    /// @param _contractAddress address of contract to be whitelisted
    event ContractWhitelisted(address _contractAddress);
    /// @notice Emits when a contract address is removed from whitelists mapping
    /// @param _contractAddress address of contract to be blacklisted
    event ContractBlacklisted(address _contractAddress);
    /// @notice Emits when a DApp is inserted in whitelists mapping
    /// @param _DApp address of DApp to be whitelisted
    event MessagingDAppWhitelisted(address _DApp);
    /// @notice Emits when a DApp is removed from whitelists mapping
    /// @param _DApp address of DApp to be blacklisted
    event MessagingDAppBlacklisted(address _DApp);
    /// @notice Emits when the owner is updated
    /// @param previousOwner The previous owner
    /// @param newOwner The new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(){updateOwnerInternal(tx.origin);}

    /// @notice used to limit access only to owner
    modifier onlyOwner() {
        require(msg.sender == getWhitelistsStorage().owner, "should be called only by owner");
        _;
    }

    function initMiddlewaresWhitelistsStorage(
        address _owner,
        address _rangoDiamond,
        address _weth,
        address [] memory _whitelistContracts,
        address [] memory _whitelistDApps
    ) external onlyOwner {
        require(_owner != address(0), "Invalid owner address");
        updateOwnerInternal(_owner);
        updateRangoDiamondInternal(_rangoDiamond);
        updateWethInternal(_weth);
        addWhitelists(_whitelistContracts);
        addMessagingDApps(_whitelistDApps);
    }

    /// @notice updates the address of contract owner
    /// @param _owner new address for owner
    function updateOwner(address _owner) external onlyOwner {
        updateOwnerInternal(_owner);
    }

    /// @notice updates the address of wrapped token address
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function updateWeth(address _weth) external onlyOwner {
        updateWethInternal(_weth);
    }

    /// @notice updates the address of rango diamond contract on the current chain
    /// @param _rangoDiamond address of rango diamond
    function updateRangoDiamond(address _rangoDiamond) external onlyOwner {
        updateRangoDiamondInternal(_rangoDiamond);
    }

    /// Whitelist ///

    /// @notice Adds array of DEX addresses to whitelist
    /// @param contractAddresses Array of DEX addresses
    function addWhitelists(address[] memory contractAddresses) public onlyOwner {
        for (uint i = 0; i < contractAddresses.length; i++) {
            addWhitelist(contractAddresses[i]);
        }
    }

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    function addWhitelist(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), "Invalid address to be whitelisted!");
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();
        s.whitelistContracts[contractAddress] = true;

        emit ContractWhitelisted(contractAddress);
    }

    /// @notice Adds array of Messaging DApps to whitelist
    /// @param DApps array of DApps addresses 
    function addMessagingDApps(address[] memory DApps) public onlyOwner {
        for (uint i = 0; i < DApps.length; i++) {
            addMessagingDApp(DApps[i]);
        }
    }

    // @notice Adds a contract to the whitelisted messaging dApps that can be called
    /// @param _dapp The address of dApp
    function addMessagingDApp(address _dapp) public onlyOwner {
        require(_dapp != address(0), "Invalid address for a DApp!");
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();
        s.whitelistMessagingContracts[_dapp] = true;

        emit MessagingDAppWhitelisted(_dapp);
    }

    /// @notice Removes a contract from dApps that can be called
    /// @param _dapp The address of dApp
    function removeMessagingDApp(address _dapp) external onlyOwner {
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();

        delete s.whitelistMessagingContracts[_dapp];

        emit MessagingDAppBlacklisted(_dapp);
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    function removeWhitelist(address contractAddress) external onlyOwner {
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();

        delete s.whitelistContracts[contractAddress];

        emit ContractBlacklisted(contractAddress);
    }

    /// @notice returns true if the input contract address is whitelisted
    /// @param _contractAddress address of contract to be checked
    /// @return boolean whitelisted or not
    function isContractWhitelisted(address _contractAddress) external view returns (bool) {
        WhitelistsMiddlewaresStorage storage whitelistStorage = getWhitelistsStorage();
        return whitelistStorage.whitelistContracts[_contractAddress];
    }

    /// @notice returns true if the input DApp address is whitelisted
    /// @param _messagingContract address of contract to be checked
    /// @return boolean whitelisted or not
    function isMessagingContractWhitelisted(address _messagingContract) external view returns (bool) {
        WhitelistsMiddlewaresStorage storage whitelistStorage = getWhitelistsStorage();
        return whitelistStorage.whitelistMessagingContracts[_messagingContract];
    }

    /// @notice returns address of wrapped token on the current chain
    /// @return WETH address
    function getWeth() external view returns (address) {
        WhitelistsMiddlewaresStorage storage whitelistStorage = getWhitelistsStorage();
        address weth = whitelistStorage.WETH;
        require(weth != address(0));
        return weth;
    }

    /// @notice returns owner of the contract
    /// @return owner address
    function getOwner() external view returns (address) {
        WhitelistsMiddlewaresStorage storage whitelistStorage = getWhitelistsStorage();
        return whitelistStorage.owner;
    }

    /// @notice returns address of rango diamond on the current chain
    /// @return rangoDiamond address
    function getRangoDiamond() external view returns (address) {
        WhitelistsMiddlewaresStorage storage whitelistStorage = getWhitelistsStorage();
        return whitelistStorage.rangoDiamond;
    }

    /// Internal and Private functions
    function updateOwnerInternal(address _newAddress) private {
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();
        address oldAddress = s.owner;
        s.owner = _newAddress;
        emit OwnershipTransferred(oldAddress, _newAddress);
    }

    function updateRangoDiamondInternal(address _newAddress) private {
        require(_newAddress != address(0), "Invalid address for rango diamond!");
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();
        address oldAddress = s.rangoDiamond;
        s.rangoDiamond = _newAddress;
        emit RangoDiamondAddressUpdated(oldAddress, _newAddress);
    }

    function updateWethInternal(address _newAddress) private {
        require(_newAddress != address(0), "Invalid WETH!");
        WhitelistsMiddlewaresStorage storage s = getWhitelistsStorage();
        address oldAddress = s.WETH;
        s.WETH = _newAddress;
        emit WethAddressUpdated(oldAddress, _newAddress);
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getWhitelistsStorage() internal pure returns (WhitelistsMiddlewaresStorage storage s) {
        bytes32 namespace = WHITELISTS_MIDDLEWARES_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

interface IRangoMiddlewareWhitelists {

    function addWhitelist(address contractAddress) external;
    function removeWhitelist(address contractAddress) external;

    function isContractWhitelisted(address _contractAddress) external view returns (bool);
    function isMessagingContractWhitelisted(address _messagingContract) external view returns (bool);

    function updateWeth(address _weth) external;
    function getWeth() external view returns (address);
    function getRangoDiamond() external view returns (address);
}