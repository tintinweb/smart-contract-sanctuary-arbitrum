// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibResourceLocator} from '../libraries/LibResourceLocator.sol';
import {IResourceLocator} from '../interfaces/IResourceLocator.sol';
import {LibContractOwner} from '../../lib/@lagunagames/lg-diamond-template/src/libraries/LibContractOwner.sol';

/// @title Resource Locator Admin facet for Crypto Unicorns
/// @author [email protected]
contract ResourceLocatorFacet is IResourceLocator {
    /// @notice Returns the Unicorn contract address
    function unicornNFTAddress() public view returns (address) {
        return LibResourceLocator.unicornNFT();
    }

    /// @notice Sets the Unicorn contract address
    /// @dev Contract owner only
    /// @param a The new Unicorn contract address
    function setUnicornNFTAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setUnicornNFT(a);
    }

    /// @notice Returns the Land contract address
    function landNFTAddress() public view returns (address) {
        return LibResourceLocator.landNFT();
    }

    /// @notice Sets the Land contract address
    /// @dev Contract owner only
    /// @param a The new Land contract address
    function setLandNFTAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setLandNFT(a);
    }

    /// @notice Returns the Shadowcorn contract address
    function shadowcornNFTAddress() public view returns (address) {
        return LibResourceLocator.shadowcornNFT();
    }

    /// @notice Sets the Shadowcorn contract address
    /// @dev Contract owner only
    /// @param a The new Shadowcorn contract address
    function setShadowcornNFTAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setShadowcornNFT(a);
    }

    /// @notice Returns the Gem contract address
    function gemNFTAddress() public view returns (address) {
        return LibResourceLocator.gemNFT();
    }

    /// @notice Sets the Gem contract address
    /// @dev Contract owner only
    /// @param a The new Gem contract address
    function setGemNFTAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setGemNFT(a);
    }

    /// @notice Returns the Ritual contract address
    function ritualNFTAddress() public view returns (address) {
        return LibResourceLocator.ritualNFT();
    }

    /// @notice Sets the Ritual contract address
    /// @dev Contract owner only
    /// @param a The new Ritual contract address
    function setRitualNFTAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setRitualNFT(a);
    }

    /// @notice Returns the RBW Token contract address
    function rbwTokenAddress() public view returns (address) {
        return LibResourceLocator.rbwToken();
    }

    /// @notice Sets the RBW Token contract address
    /// @dev Contract owner only
    /// @param a The new RBW Token contract address
    function setRBWTokenAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setRBWToken(a);
    }

    /// @notice Returns the CU Token contract address
    function cuTokenAddress() public view returns (address) {
        return LibResourceLocator.cuToken();
    }

    /// @notice Sets the CU Token contract address
    /// @dev Contract owner only
    /// @param a The new CU Token contract address
    function setCUTokenAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setCUToken(a);
    }

    /// @notice Returns the UNIM Token contract address
    function unimTokenAddress() public view returns (address) {
        return LibResourceLocator.unimToken();
    }

    /// @notice Sets the UNIM Token contract address
    /// @dev Contract owner only
    /// @param a The new UNIM Token contract address
    function setUNIMTokenAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setUNIMToken(a);
    }

    /// @notice Returns the WETH Token contract address
    function wethTokenAddress() public view returns (address) {
        return LibResourceLocator.wethToken();
    }

    /// @notice Sets the WETH Token contract address
    /// @dev Contract owner only
    /// @param a The new WETH Token contract address
    function setWETHTokenAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setWETHToken(a);
    }

    /// @notice Returns the Dark Mark Token contract address
    function darkMarkTokenAddress() public view returns (address) {
        return LibResourceLocator.darkMarkToken();
    }

    /// @notice Sets the Dark Mark Token contract address
    /// @dev Contract owner only
    /// @param a The new Dark Mark Token contract address
    function setDarkMarkTokenAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setDarkMarkToken(a);
    }

    /// @notice Returns the Unicorn Items contract address
    function unicornItemsAddress() public view returns (address) {
        return LibResourceLocator.unicornItems();
    }

    /// @notice Sets the Unicorn Items contract address
    /// @dev Contract owner only
    /// @param a The new Unicorn Items contract address
    function setUnicornItemsAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setUnicornItems(a);
    }

    /// @notice Returns the Shadowcorn Items contract address
    function shadowcornItemsAddress() public view returns (address) {
        return LibResourceLocator.shadowcornItems();
    }

    /// @notice Sets the Shadowcorn Items contract address
    /// @dev Contract owner only
    /// @param a The new Shadowcorn Items contract address
    function setShadowcornItemsAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setShadowcornItems(a);
    }

    /// @notice Returns the Access Control Badge contract address
    function accessControlBadgeAddress() public view returns (address) {
        return LibResourceLocator.accessControlBadge();
    }

    /// @notice Sets the Access Control Badge contract address
    /// @dev Contract owner only
    /// @param a The new Access Control Badge contract address
    function setAccessControlBadgeAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setAccessControlBadge(a);
    }

    /// @notice Returns the Game Bank contract address
    function gameBankAddress() public view returns (address) {
        return LibResourceLocator.gameBank();
    }

    /// @notice Sets the Game Bank contract address
    /// @dev Contract owner only
    /// @param a The new Game Bank contract address
    function setGameBankAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setGameBank(a);
    }

    /// @notice Returns the Satellite Bank contract address
    function satelliteBankAddress() public view returns (address) {
        return LibResourceLocator.satelliteBank();
    }

    /// @notice Sets the Satellite Bank contract address
    /// @dev Contract owner only
    /// @param a The new Satellite Bank contract address
    function setSatelliteBankAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setSatelliteBank(a);
    }

    /// @notice Returns the Player Profile contract address
    function playerProfileAddress() public view returns (address) {
        return LibResourceLocator.playerProfile();
    }

    /// @notice Sets the Player Profile contract address
    /// @dev Contract owner only
    /// @param a The new Player Profile contract address
    function setPlayerProfileAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setPlayerProfile(a);
    }

    /// @notice Returns the Shadow Forge contract address
    function shadowForgeAddress() public view returns (address) {
        return LibResourceLocator.shadowForge();
    }

    /// @notice Sets the Shadow Forge contract address
    /// @dev Contract owner only
    /// @param a The new Shadow Forge contract address
    function setShadowForgeAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setShadowForge(a);
    }

    /// @notice Returns the Dark Forest contract address
    function darkForestAddress() public view returns (address) {
        return LibResourceLocator.darkForest();
    }

    /// @notice Sets the Dark Forest contract address
    /// @dev Contract owner only
    /// @param a The new Dark Forest contract address
    function setDarkForestAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setDarkForest(a);
    }

    /// @notice Returns the Game Server SSS contract address
    function gameServerSSSAddress() public view returns (address) {
        return LibResourceLocator.gameServerSSS();
    }

    /// @notice Sets the Game Server SSS contract address
    /// @dev Contract owner only
    /// @param a The new Game Server SSS contract address
    function setGameServerSSSAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setGameServerSSS(a);
    }

    /// @notice Returns the Game Server Oracle contract address
    function gameServerOracleAddress() public view returns (address) {
        return LibResourceLocator.gameServerOracle();
    }

    /// @notice Sets the Game Server Oracle contract address
    /// @dev Contract owner only
    /// @param a The new Game Server Oracle contract address
    function setGameServerOracleAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setGameServerOracle(a);
    }

    /// @notice Returns the Testnet Debug Registry address
    function testnetDebugRegistryAddress() external view returns (address) {
        return LibResourceLocator.testnetDebugRegistry();
    }

    /// @notice Sets the Testnet Debug Registry address
    /// @dev Contract owner only
    /// @param a The new Testnet Debug Registry address
    function setTestnetDebugRegistryAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setTestnetDebugRegistry(a);
    }

    /// @notice Returns the VRF Oracle contract address
    function vrfOracleAddress() public view returns (address) {
        return LibResourceLocator.vrfOracle();
    }

    /// @notice Sets the VRF Oracle contract address
    /// @dev Contract owner only
    /// @param a The new VRF Oracle contract address
    function setVRFOracleAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setVRFOracle(a);
    }

    /// @notice Returns the VRF Client Wallet address
    function vrfClientWalletAddress() public view returns (address) {
        return LibResourceLocator.vrfClientWallet();
    }

    /// @notice Sets the VRF Client Wallet (payer) address
    /// @dev Contract owner only
    /// @param a The new VRF Client Wallet address
    function setVRFClientWalletAddress(address a) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.setVRFClientWallet(a);
    }

    /// @notice Copies the addresses from an existing diamond onto this one
    /// @dev Contract owner only
    /// @param diamond The existing diamond to clone from
    function importResourcesFromDiamond(address diamond) public {
        LibContractOwner.enforceIsContractOwner();
        LibResourceLocator.importResourcesFromDiamond(diamond);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from '../../lib/@lagunagames/lg-diamond-template/src/interfaces/IERC165.sol';
import {IResourceLocator} from '../interfaces/IResourceLocator.sol';

/// @title LG Resource Locator Library
/// @author [email protected]
/// @notice Library for common LG Resource Locations deployed on a chain
/// @custom:storage-location erc7201:games.laguna.LibResourceLocator
library LibResourceLocator {
    //  @dev Storage slot for LG Resource addresses
    bytes32 internal constant RESOURCE_LOCATOR_SLOT_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.LibResourceLocator')) - 1)) & ~bytes32(uint256(0xff));

    struct ResourceLocatorStorageStruct {
        address unicornNFT; //  ERC-721
        address landNFT; //  ERC-721
        address shadowcornNFT; //  ERC-721
        address gemNFT; //  ERC-721
        address ritualNFT; //  ERC-721
        address RBWToken; //  ERC-20
        address CUToken; //  ERC-20
        address UNIMToken; //  ERC-20
        address WETHToken; //  ERC-20 (third party)
        address darkMarkToken; //  pseudo-ERC-20
        address unicornItems; //  ERC-1155 Terminus
        address shadowcornItems; //  ERC-1155 Terminus
        address accessControlBadge; //  ERC-1155 Terminus
        address gameBank;
        address satelliteBank;
        address playerProfile; //  PermissionProvider
        address shadowForge;
        address darkForest;
        address gameServerSSS; //  ERC-712 Signing Wallet
        address gameServerOracle; //  CU-Watcher
        address testnetDebugRegistry; // PermissionProvider
        address vrfOracle; //  SupraOracles VRF
        address vrfClientWallet; //  SupraOracles VRF payer
    }

    /// @notice Storage slot for ResourceLocator state data
    function resourceLocatorStorage() internal pure returns (ResourceLocatorStorageStruct storage storageSlot) {
        bytes32 position = RESOURCE_LOCATOR_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    function unicornNFT() internal view returns (address) {
        return resourceLocatorStorage().unicornNFT;
    }

    function setUnicornNFT(address a) internal {
        resourceLocatorStorage().unicornNFT = a;
    }

    function landNFT() internal view returns (address) {
        return resourceLocatorStorage().landNFT;
    }

    function setLandNFT(address a) internal {
        resourceLocatorStorage().landNFT = a;
    }

    function shadowcornNFT() internal view returns (address) {
        return resourceLocatorStorage().shadowcornNFT;
    }

    function setShadowcornNFT(address a) internal {
        resourceLocatorStorage().shadowcornNFT = a;
    }

    function gemNFT() internal view returns (address) {
        return resourceLocatorStorage().gemNFT;
    }

    function setGemNFT(address a) internal {
        resourceLocatorStorage().gemNFT = a;
    }

    function ritualNFT() internal view returns (address) {
        return resourceLocatorStorage().ritualNFT;
    }

    function setRitualNFT(address a) internal {
        resourceLocatorStorage().ritualNFT = a;
    }

    function rbwToken() internal view returns (address) {
        return resourceLocatorStorage().RBWToken;
    }

    function setRBWToken(address a) internal {
        resourceLocatorStorage().RBWToken = a;
    }

    function cuToken() internal view returns (address) {
        return resourceLocatorStorage().CUToken;
    }

    function setCUToken(address a) internal {
        resourceLocatorStorage().CUToken = a;
    }

    function unimToken() internal view returns (address) {
        return resourceLocatorStorage().UNIMToken;
    }

    function setUNIMToken(address a) internal {
        resourceLocatorStorage().UNIMToken = a;
    }

    function wethToken() internal view returns (address) {
        return resourceLocatorStorage().WETHToken;
    }

    function setWETHToken(address a) internal {
        resourceLocatorStorage().WETHToken = a;
    }

    function darkMarkToken() internal view returns (address) {
        return resourceLocatorStorage().darkMarkToken;
    }

    function setDarkMarkToken(address a) internal {
        resourceLocatorStorage().darkMarkToken = a;
    }

    function unicornItems() internal view returns (address) {
        return resourceLocatorStorage().unicornItems;
    }

    function setUnicornItems(address a) internal {
        resourceLocatorStorage().unicornItems = a;
    }

    function shadowcornItems() internal view returns (address) {
        return resourceLocatorStorage().shadowcornItems;
    }

    function setShadowcornItems(address a) internal {
        resourceLocatorStorage().shadowcornItems = a;
    }

    function accessControlBadge() internal view returns (address) {
        return resourceLocatorStorage().accessControlBadge;
    }

    function setAccessControlBadge(address a) internal {
        resourceLocatorStorage().accessControlBadge = a;
    }

    function gameBank() internal view returns (address) {
        return resourceLocatorStorage().gameBank;
    }

    function setGameBank(address a) internal {
        resourceLocatorStorage().gameBank = a;
    }

    function satelliteBank() internal view returns (address) {
        return resourceLocatorStorage().satelliteBank;
    }

    function setSatelliteBank(address a) internal {
        resourceLocatorStorage().satelliteBank = a;
    }

    function playerProfile() internal view returns (address) {
        return resourceLocatorStorage().playerProfile;
    }

    function setPlayerProfile(address a) internal {
        resourceLocatorStorage().playerProfile = a;
    }

    function shadowForge() internal view returns (address) {
        return resourceLocatorStorage().shadowForge;
    }

    function setShadowForge(address a) internal {
        resourceLocatorStorage().shadowForge = a;
    }

    function darkForest() internal view returns (address) {
        return resourceLocatorStorage().darkForest;
    }

    function setDarkForest(address a) internal {
        resourceLocatorStorage().darkForest = a;
    }

    function gameServerSSS() internal view returns (address) {
        return resourceLocatorStorage().gameServerSSS;
    }

    function setGameServerSSS(address a) internal {
        resourceLocatorStorage().gameServerSSS = a;
    }

    function gameServerOracle() internal view returns (address) {
        return resourceLocatorStorage().gameServerOracle;
    }

    function setGameServerOracle(address a) internal {
        resourceLocatorStorage().gameServerOracle = a;
    }

    function testnetDebugRegistry() internal view returns (address) {
        return resourceLocatorStorage().testnetDebugRegistry;
    }

    function setTestnetDebugRegistry(address a) internal {
        resourceLocatorStorage().testnetDebugRegistry = a;
    }

    function vrfOracle() internal view returns (address) {
        return resourceLocatorStorage().vrfOracle;
    }

    function setVRFOracle(address a) internal {
        resourceLocatorStorage().vrfOracle = a;
    }

    function vrfClientWallet() internal view returns (address) {
        return resourceLocatorStorage().vrfClientWallet;
    }

    function setVRFClientWallet(address a) internal {
        resourceLocatorStorage().vrfClientWallet = a;
    }

    /// @notice Clones the addresses from an existing diamond onto this one
    function importResourcesFromDiamond(address diamond) internal {
        require(
            IERC165(diamond).supportsInterface(type(IResourceLocator).interfaceId),
            'LibResourceLocator: target does not implement IResourceLocator'
        );
        IResourceLocator target = IResourceLocator(diamond);
        if (target.unicornNFTAddress() != address(0)) setUnicornNFT(target.unicornNFTAddress());
        if (target.landNFTAddress() != address(0)) setLandNFT(target.landNFTAddress());
        if (target.shadowcornNFTAddress() != address(0)) setShadowcornNFT(target.shadowcornNFTAddress());
        if (target.gemNFTAddress() != address(0)) setGemNFT(target.gemNFTAddress());
        if (target.ritualNFTAddress() != address(0)) setRitualNFT(target.ritualNFTAddress());
        if (target.rbwTokenAddress() != address(0)) setRBWToken(target.rbwTokenAddress());
        if (target.cuTokenAddress() != address(0)) setCUToken(target.cuTokenAddress());
        if (target.unimTokenAddress() != address(0)) setUNIMToken(target.unimTokenAddress());
        if (target.wethTokenAddress() != address(0)) setWETHToken(target.wethTokenAddress());
        if (target.darkMarkTokenAddress() != address(0)) setDarkMarkToken(target.darkMarkTokenAddress());
        if (target.unicornItemsAddress() != address(0)) setUnicornItems(target.unicornItemsAddress());
        if (target.shadowcornItemsAddress() != address(0)) setShadowcornItems(target.shadowcornItemsAddress());
        if (target.accessControlBadgeAddress() != address(0)) setAccessControlBadge(target.accessControlBadgeAddress());
        if (target.gameBankAddress() != address(0)) setGameBank(target.gameBankAddress());
        if (target.satelliteBankAddress() != address(0)) setSatelliteBank(target.satelliteBankAddress());
        if (target.playerProfileAddress() != address(0)) setPlayerProfile(target.playerProfileAddress());
        if (target.shadowForgeAddress() != address(0)) setShadowForge(target.shadowForgeAddress());
        if (target.darkForestAddress() != address(0)) setDarkForest(target.darkForestAddress());
        if (target.gameServerSSSAddress() != address(0)) setGameServerSSS(target.gameServerSSSAddress());
        if (target.gameServerOracleAddress() != address(0)) setGameServerOracle(target.gameServerOracleAddress());
        if (target.testnetDebugRegistryAddress() != address(0))
            setTestnetDebugRegistry(target.testnetDebugRegistryAddress());
        if (target.vrfOracleAddress() != address(0)) setVRFOracle(target.vrfOracleAddress());
        if (target.vrfClientWalletAddress() != address(0)) setVRFClientWallet(target.vrfClientWalletAddress());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Resource Locator for Crypto Unicorns
/// @author [email protected]
interface IResourceLocator {
    /// @notice Returns the Unicorn NFT contract address
    function unicornNFTAddress() external view returns (address);

    /// @notice Returns the Land NFT contract address
    function landNFTAddress() external view returns (address);

    /// @notice Returns the Shadowcorn NFT contract address
    function shadowcornNFTAddress() external view returns (address);

    /// @notice Returns the Gem NFT contract address
    function gemNFTAddress() external view returns (address);

    /// @notice Returns the Ritual NFT contract address
    function ritualNFTAddress() external view returns (address);

    /// @notice Returns the RBW Token contract address
    function rbwTokenAddress() external view returns (address);

    /// @notice Returns the CU Token contract address
    function cuTokenAddress() external view returns (address);

    /// @notice Returns the UNIM Token contract address
    function unimTokenAddress() external view returns (address);

    /// @notice Returns the WETH Token contract address
    function wethTokenAddress() external view returns (address);

    /// @notice Returns the DarkMark Token contract address
    function darkMarkTokenAddress() external view returns (address);

    /// @notice Returns the Unicorn Items contract address
    function unicornItemsAddress() external view returns (address);

    /// @notice Returns the Shadowcorn Items contract address
    function shadowcornItemsAddress() external view returns (address);

    /// @notice Returns the Access Control Badge contract address
    function accessControlBadgeAddress() external view returns (address);

    /// @notice Returns the GameBank contract address
    function gameBankAddress() external view returns (address);

    /// @notice Returns the SatelliteBank contract address
    function satelliteBankAddress() external view returns (address);

    /// @notice Returns the PlayerProfile contract address
    function playerProfileAddress() external view returns (address);

    /// @notice Returns the Shadow Forge contract address
    function shadowForgeAddress() external view returns (address);

    /// @notice Returns the Dark Forest contract address
    function darkForestAddress() external view returns (address);

    /// @notice Returns the Game Server SSS contract address
    function gameServerSSSAddress() external view returns (address);

    /// @notice Returns the Game Server Oracle contract address
    function gameServerOracleAddress() external view returns (address);

    /// @notice Returns the VRF Oracle contract address
    function vrfOracleAddress() external view returns (address);

    /// @notice Returns the VRF Client Wallet address
    function vrfClientWalletAddress() external view returns (address);

    /// @notice Returns the Testnet Debug Registry address
    /// @dev Available on testnet deployments only
    function testnetDebugRegistryAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Library for the common LG implementation of ERC-173 Contract Ownership Standard
/// @author [email protected]
/// @custom:storage-location erc1967:eip1967.proxy.admin
library LibContractOwner {
    error CallerIsNotContractOwner();

    /// @notice This emits when ownership of a contract changes.
    /// @dev ERC-173
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the admin account has changed.
    /// @dev ERC-1967
    event AdminChanged(address previousAdmin, address newAdmin);

    //  @dev Standard storage slot for the ERC-1967 admin address
    //  @dev bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 private constant ADMIN_SLOT_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    struct LibOwnerStorage {
        address contractOwner;
    }

    /// @notice Storage slot for Contract Owner state data
    function ownerStorage() internal pure returns (LibOwnerStorage storage storageSlot) {
        bytes32 position = ADMIN_SLOT_POSITION;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            storageSlot.slot := position
        }
    }

    /// @notice Sets the contract owner
    /// @param newOwner The new owner
    /// @custom:emits OwnershipTransferred
    function setContractOwner(address newOwner) internal {
        LibOwnerStorage storage ls = ownerStorage();
        address previousOwner = ls.contractOwner;
        ls.contractOwner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
        emit AdminChanged(previousOwner, newOwner);
    }

    /// @notice Gets the contract owner wallet
    /// @return owner The contract owner
    function contractOwner() internal view returns (address owner) {
        owner = ownerStorage().contractOwner;
    }

    /// @notice Ensures that the caller is the contract owner, or throws an error.
    /// @custom:throws LibAccess: Must be contract owner
    function enforceIsContractOwner() internal view {
        if (msg.sender != ownerStorage().contractOwner) revert CallerIsNotContractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC-165 Standard Interface Detection
/// @dev https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}