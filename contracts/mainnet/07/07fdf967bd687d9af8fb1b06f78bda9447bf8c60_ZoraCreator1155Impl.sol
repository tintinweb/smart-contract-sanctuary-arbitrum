// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC1155MetadataURIUpgradeable.sol";
import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";
import {IProtocolRewards} from "@zoralabs/protocol-rewards/src/interfaces/IProtocolRewards.sol";
import {RewardSplits, RewardSplitsLib} from "@zoralabs/protocol-rewards/src/abstract/RewardSplits.sol";
import {ERC1155RewardsStorageV1} from "@zoralabs/protocol-rewards/src/abstract/ERC1155/ERC1155RewardsStorageV1.sol";
import {ReentrancyGuardUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {MathUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";

import {IZoraCreator1155} from "../interfaces/IZoraCreator1155.sol";
import {IZoraCreator1155Initializer} from "../interfaces/IZoraCreator1155Initializer.sol";
import {IERC7572} from "../interfaces/IERC7572.sol";
import {ContractVersionBase} from "../version/ContractVersionBase.sol";
import {CreatorPermissionControl} from "../permissions/CreatorPermissionControl.sol";
import {CreatorRendererControl} from "../renderer/CreatorRendererControl.sol";
import {CreatorRoyaltiesControl} from "../royalties/CreatorRoyaltiesControl.sol";
import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";
import {IUpgradeGate} from "../interfaces/IUpgradeGate.sol";
import {IZoraCreator1155} from "../interfaces/IZoraCreator1155.sol";
import {LegacyNamingControl} from "../legacy-naming/LegacyNamingControl.sol";
import {PublicMulticall} from "../utils/PublicMulticall.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";
import {TransferHelperUtils} from "../utils/TransferHelperUtils.sol";
import {ZoraCreator1155StorageV1} from "./ZoraCreator1155StorageV1.sol";
import {IZoraCreator1155Errors} from "../interfaces/IZoraCreator1155Errors.sol";
import {ERC1155DelegationStorageV1} from "../delegation/ERC1155DelegationStorageV1.sol";
import {IZoraCreator1155DelegatedCreation, ISupportsAABasedDelegatedTokenCreation, IHasSupportedPremintSignatureVersions} from "../interfaces/IZoraCreator1155DelegatedCreation.sol";
import {IMintWithRewardsRecipients} from "../interfaces/IMintWithRewardsRecipients.sol";
import {ZoraCreator1155Attribution, DecodedCreatorAttribution, PremintTokenSetup, PremintConfigV2, DelegatedTokenCreation, DelegatedTokenSetup} from "../delegation/ZoraCreator1155Attribution.sol";
import {ContractCreationConfig, PremintConfig} from "@zoralabs/shared-contracts/entities/Premint.sol";
import {IZoraMintsMinterManager} from "@zoralabs/mints-contracts/src/interfaces/IZoraMintsMinterManager.sol";
import {IZoraMints1155} from "@zoralabs/mints-contracts/src/interfaces/IZoraMints1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IMintWithMints} from "@zoralabs/mints-contracts/src/IMintWithMints.sol";
import {Redemption} from "@zoralabs/mints-contracts/src/ZoraMintsTypes.sol";

/// Imagine. Mint. Enjoy.
/// @title ZoraCreator1155Impl
/// @notice The core implementation contract for a creator's 1155 token
/// @author @iainnash / @tbtstl
contract ZoraCreator1155Impl is
    IZoraCreator1155,
    IZoraCreator1155Initializer,
    ContractVersionBase,
    ReentrancyGuardUpgradeable,
    PublicMulticall,
    ERC1155Upgradeable,
    UUPSUpgradeable,
    CreatorRendererControl,
    LegacyNamingControl,
    ZoraCreator1155StorageV1,
    CreatorPermissionControl,
    CreatorRoyaltiesControl,
    RewardSplits,
    ERC1155RewardsStorageV1,
    IERC7572,
    ERC1155DelegationStorageV1
{
    /// @notice This user role allows for any action to be performed
    uint256 public constant PERMISSION_BIT_ADMIN = 2 ** 1;
    /// @notice This user role allows for only mint actions to be performed
    uint256 public constant PERMISSION_BIT_MINTER = 2 ** 2;

    /// @notice This user role allows for only managing sales configurations
    uint256 public constant PERMISSION_BIT_SALES = 2 ** 3;
    /// @notice This user role allows for only managing metadata configuration
    uint256 public constant PERMISSION_BIT_METADATA = 2 ** 4;
    /// @notice This user role allows for only withdrawing funds and setting funds withdraw address
    uint256 public constant PERMISSION_BIT_FUNDS_MANAGER = 2 ** 5;
    /// @notice Factory contract
    IUpgradeGate internal immutable upgradeGate;
    /// @notice The mint token contract
    IZoraMintsMinterManager internal immutable mintsManager;

    bytes4 constant ON_ERC1155_RECEIVED_HASH = IERC1155Receiver.onERC1155Received.selector;
    bytes4 constant ON_ERC1155_BATCH_RECEIVED_HASH = IERC1155Receiver.onERC1155BatchReceived.selector;

    constructor(
        address _mintFeeRecipient,
        address _upgradeGate,
        address _protocolRewards,
        address _mints
    ) RewardSplits(_protocolRewards, _mintFeeRecipient) initializer {
        upgradeGate = IUpgradeGate(_upgradeGate);
        mintsManager = IZoraMintsMinterManager(_mints);
    }

    /// @notice Initializes the contract
    /// @param contractName the legacy on-chain contract name
    /// @param newContractURI The contract URI
    /// @param defaultRoyaltyConfiguration The default royalty configuration
    /// @param defaultAdmin The default admin to manage the token
    /// @param setupActions The setup actions to run, if any
    function initialize(
        string memory contractName,
        string memory newContractURI,
        RoyaltyConfiguration memory defaultRoyaltyConfiguration,
        address payable defaultAdmin,
        bytes[] calldata setupActions
    ) external nonReentrant initializer {
        // We are not initalizing the OZ 1155 implementation
        // to save contract storage space and runtime
        // since the only thing affected here is the uri.
        // __ERC1155_init("");

        // Setup uups
        __UUPSUpgradeable_init();

        // Setup re-entracy guard
        __ReentrancyGuard_init();

        // Setup contract-default token ID
        _setupDefaultToken(defaultAdmin, newContractURI, defaultRoyaltyConfiguration);

        // Set owner to default admin
        _setOwner(defaultAdmin);

        _setFundsRecipient(defaultAdmin);

        _setName(contractName);

        // Run Setup actions
        if (setupActions.length > 0) {
            // Temporarily make sender admin
            _addPermission(CONTRACT_BASE_ID, msg.sender, PERMISSION_BIT_ADMIN);

            // Make calls
            multicall(setupActions);

            // Remove admin
            _removePermission(CONTRACT_BASE_ID, msg.sender, PERMISSION_BIT_ADMIN);
        }
    }

    /// @notice sets up the global configuration for the 1155 contract
    /// @param newContractURI The contract URI
    /// @param defaultRoyaltyConfiguration The default royalty configuration
    function _setupDefaultToken(address defaultAdmin, string memory newContractURI, RoyaltyConfiguration memory defaultRoyaltyConfiguration) internal {
        // Add admin permission to default admin to manage contract
        _addPermission(CONTRACT_BASE_ID, defaultAdmin, PERMISSION_BIT_ADMIN);

        // Mint token ID 0 / don't allow any user mints
        _setupNewToken(newContractURI, 0);

        // Update default royalties
        _updateRoyalties(CONTRACT_BASE_ID, defaultRoyaltyConfiguration);
    }

    /// @notice Updates the royalty configuration for a token
    /// @param tokenId The token ID to update
    /// @param newConfiguration The new royalty configuration
    function updateRoyaltiesForToken(
        uint256 tokenId,
        RoyaltyConfiguration memory newConfiguration
    ) external onlyAdminOrRole(tokenId, PERMISSION_BIT_FUNDS_MANAGER) {
        _updateRoyalties(tokenId, newConfiguration);
    }

    /// @notice remove this function from openzeppelin impl
    /// @dev This makes this internal function a no-op
    function _setURI(string memory newuri) internal virtual override {}

    /// @notice This gets the next token in line to be minted when minting linearly (default behavior) and updates the counter
    function _getAndUpdateNextTokenId() internal returns (uint256) {
        unchecked {
            return nextTokenId++;
        }
    }

    /// @notice Ensure that the next token ID is correct
    /// @dev This reverts if the invariant doesn't match. This is used for multil token id assumptions
    /// @param lastTokenId The last token ID
    function assumeLastTokenIdMatches(uint256 lastTokenId) external view {
        unchecked {
            if (nextTokenId - 1 != lastTokenId) {
                revert TokenIdMismatch(lastTokenId, nextTokenId - 1);
            }
        }
    }

    /// @notice Checks if a user either has a role for a token or if they are the admin
    /// @dev This is an internal function that is called by the external getter and internal functions
    /// @param user The user to check
    /// @param tokenId The token ID to check
    /// @param role The role to check
    /// @return true or false if the permission exists for the user given the token id
    function _isAdminOrRole(address user, uint256 tokenId, uint256 role) internal view returns (bool) {
        return _hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN | role);
    }

    /// @notice Checks if a user either has a role for a token or if they are the admin
    /// @param user The user to check
    /// @param tokenId The token ID to check
    /// @param role The role to check
    /// @return true or false if the permission exists for the user given the token id
    function isAdminOrRole(address user, uint256 tokenId, uint256 role) external view returns (bool) {
        return _isAdminOrRole(user, tokenId, role);
    }

    /// @notice Checks if the user is an admin for the given tokenId
    /// @dev This function reverts if the permission does not exist for the given user and tokenId
    /// @param user user to check
    /// @param tokenId tokenId to check
    /// @param role role to check for admin
    function _requireAdminOrRole(address user, uint256 tokenId, uint256 role) internal view {
        if (!(_hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN | role) || _hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN | role))) {
            revert UserMissingRoleForToken(user, tokenId, role);
        }
    }

    /// @notice Checks if the user is an admin
    /// @dev This reverts if the user is not an admin for the given token id or contract
    /// @param user user to check
    /// @param tokenId tokenId to check
    function _requireAdmin(address user, uint256 tokenId) internal view {
        if (!(_hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN) || _hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN))) {
            revert UserMissingRoleForToken(user, tokenId, PERMISSION_BIT_ADMIN);
        }
    }

    modifier onlyMints() {
        if (msg.sender != address(mintsManager.zoraMints1155())) {
            revert OnlyTransfersFromZoraMints();
        }

        _;
    }

    /// @notice Modifier checking if the user is an admin or has a role
    /// @dev This reverts if the msg.sender is not an admin for the given token id or contract
    /// @param tokenId tokenId to check
    /// @param role role to check
    modifier onlyAdminOrRole(uint256 tokenId, uint256 role) {
        _requireAdminOrRole(msg.sender, tokenId, role);
        _;
    }

    /// @notice Modifier checking if the user is an admin
    /// @dev This reverts if the msg.sender is not an admin for the given token id or contract
    /// @param tokenId tokenId to check
    modifier onlyAdmin(uint256 tokenId) {
        _requireAdmin(msg.sender, tokenId);
        _;
    }

    /// @notice Modifier checking if the requested quantity of tokens can be minted for the tokenId
    /// @dev This reverts if the number that can be minted is exceeded
    /// @param tokenId token id to check available allowed quantity
    /// @param quantity requested to be minted
    modifier canMintQuantity(uint256 tokenId, uint256 quantity) {
        _requireCanMintQuantity(tokenId, quantity);
        _;
    }

    /// @notice Only from approved address for burn
    /// @param from address that the tokens will be burned from, validate that this is msg.sender or that msg.sender is approved
    modifier onlyFromApprovedForBurn(address from) {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert Burn_NotOwnerOrApproved(msg.sender, from);
        }

        _;
    }

    /// @notice Checks if a user can mint a quantity of a token
    /// @dev Reverts if the mint exceeds the allowed quantity (or if the token does not exist)
    /// @param tokenId The token ID to check
    /// @param quantity The quantity of tokens to mint to check
    function _requireCanMintQuantity(uint256 tokenId, uint256 quantity) internal view {
        TokenData storage tokenInformation = tokens[tokenId];
        if (tokenInformation.totalMinted + quantity > tokenInformation.maxSupply) {
            revert CannotMintMoreTokens(tokenId, quantity, tokenInformation.totalMinted, tokenInformation.maxSupply);
        }
    }

    /// @notice Set up a new token
    /// @param newURI The URI for the token
    /// @param maxSupply The maximum supply of the token
    function setupNewToken(
        string calldata newURI,
        uint256 maxSupply
    ) public onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_MINTER) nonReentrant returns (uint256) {
        uint256 tokenId = _setupNewTokenAndPermission(newURI, maxSupply, msg.sender, PERMISSION_BIT_ADMIN);

        return tokenId;
    }

    /// @notice Set up a new token with a create referral
    /// @param newURI The URI for the token
    /// @param maxSupply The maximum supply of the token
    /// @param createReferral The address of the create referral
    function setupNewTokenWithCreateReferral(
        string calldata newURI,
        uint256 maxSupply,
        address createReferral
    ) public onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_MINTER) nonReentrant returns (uint256) {
        uint256 tokenId = _setupNewTokenAndPermission(newURI, maxSupply, msg.sender, PERMISSION_BIT_ADMIN);

        _setCreateReferral(tokenId, createReferral);

        return tokenId;
    }

    function _setupNewTokenAndPermission(string memory newURI, uint256 maxSupply, address user, uint256 permission) internal returns (uint256) {
        uint256 tokenId = _setupNewToken(newURI, maxSupply);

        _addPermission(tokenId, user, permission);

        if (bytes(newURI).length > 0) {
            emit URI(newURI, tokenId);
        }

        emit SetupNewToken(tokenId, user, newURI, maxSupply);

        return tokenId;
    }

    /// @notice Update the token URI for a token
    /// @param tokenId The token ID to update the URI for
    /// @param _newURI The new URI
    function updateTokenURI(uint256 tokenId, string memory _newURI) external onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        if (tokenId == CONTRACT_BASE_ID) {
            revert();
        }
        emit URI(_newURI, tokenId);
        tokens[tokenId].uri = _newURI;
    }

    /// @notice Update the global contract metadata
    /// @param _newURI The new contract URI
    /// @param _newName The new contract name
    function updateContractMetadata(string memory _newURI, string memory _newName) external onlyAdminOrRole(0, PERMISSION_BIT_METADATA) {
        tokens[CONTRACT_BASE_ID].uri = _newURI;
        _setName(_newName);
        emit ContractMetadataUpdated(msg.sender, _newURI, _newName);
        emit ContractURIUpdated();
    }

    function _setupNewToken(string memory newURI, uint256 maxSupply) internal returns (uint256 tokenId) {
        tokenId = _getAndUpdateNextTokenId();
        TokenData memory tokenData = TokenData({uri: newURI, maxSupply: maxSupply, totalMinted: 0});
        tokens[tokenId] = tokenData;
        emit UpdatedToken(msg.sender, tokenId, tokenData);
    }

    /// @notice Add a role to a user for a token
    /// @param tokenId The token ID to add the role to
    /// @param user The user to add the role to
    /// @param permissionBits The permission bit to add
    function addPermission(uint256 tokenId, address user, uint256 permissionBits) external onlyAdmin(tokenId) {
        _addPermission(tokenId, user, permissionBits);
    }

    /// @notice Remove a role from a user for a token
    /// @param tokenId The token ID to remove the role from
    /// @param user The user to remove the role from
    /// @param permissionBits The permission bit to remove
    function removePermission(uint256 tokenId, address user, uint256 permissionBits) external onlyAdmin(tokenId) {
        _removePermission(tokenId, user, permissionBits);

        // Clear owner field
        if (tokenId == CONTRACT_BASE_ID && user == config.owner && !_hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN)) {
            _setOwner(address(0));
        }
    }

    /// @notice Set the owner of the contract
    /// @param newOwner The new owner of the contract
    function setOwner(address newOwner) external onlyAdmin(CONTRACT_BASE_ID) {
        if (!_hasAnyPermission(CONTRACT_BASE_ID, newOwner, PERMISSION_BIT_ADMIN)) {
            revert NewOwnerNeedsToBeAdmin();
        }

        // Update owner field
        _setOwner(newOwner);
    }

    /// @notice Getter for the owner singleton of the contract for outside interfaces
    /// @return the owner of the contract singleton for compat.
    function owner() external view returns (address) {
        return config.owner;
    }

    /// @notice Mint a token to a user as the admin or minter
    /// @param recipient The recipient of the token
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param data The data to pass to the onERC1155Received function
    function adminMint(
        address recipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory data
    ) external nonReentrant onlyAdminOrRole(tokenId, PERMISSION_BIT_MINTER) {
        // Mint the specified tokens
        _mint(recipient, tokenId, quantity, data);
    }

    /// @custom:deprecated mintWithRewards has been deprecated use mint instead
    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and a mint referral
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param minterArguments The arguments to pass to the minter
    /// @param mintReferral The referrer of the mint
    function mintWithRewards(
        IMinter1155 minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments,
        address mintReferral
    ) external payable nonReentrant {
        address[] memory rewardsRecipients = new address[](1);
        rewardsRecipients[0] = mintReferral;
        return _mint(minter, tokenId, quantity, rewardsRecipients, minterArguments);
    }

    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and rewards arguments
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param rewardsRecipients The addresses of rewards arguments - rewardsRecipients[0] = mintReferral, rewardsRecipients[1] = platformReferral
    /// @param minterArguments The arguments to pass to the minter
    function mint(
        IMinter1155 minter,
        uint256 tokenId,
        uint256 quantity,
        address[] calldata rewardsRecipients,
        bytes calldata minterArguments
    ) external payable nonReentrant {
        _mint(minter, tokenId, quantity, rewardsRecipients, minterArguments);
    }

    function _mintAndHandleRewards(
        IMinter1155 minter,
        address[] memory rewardsRecipients,
        uint256 valueSent,
        uint256 totalReward,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments
    ) private {
        uint256 ethValueSent = _handleRewardsAndGetValueRemaining(valueSent, totalReward, tokenId, rewardsRecipients);

        _executeCommands(minter.requestMint(msg.sender, tokenId, quantity, ethValueSent, minterArguments).commands, ethValueSent, tokenId);
        emit Purchased(msg.sender, address(minter), tokenId, quantity, valueSent);
    }

    function _handleRewardsAndGetValueRemaining(
        uint256 totalSentValue,
        uint256 totalReward,
        uint256 tokenId,
        address[] memory rewardsRecipients
    ) internal returns (uint256 valueRemaining) {
        // 1. Get rewards recipients

        // create referral is pulled from storage, if it's not set, defaults to zora reward recipient
        address createReferral = createReferrals[tokenId];
        if (createReferral == address(0)) {
            createReferral = zoraRewardRecipient;
        }

        // mint referral is passed in arguments to minting functions; if it's not set, defaults to zora reward recipient
        address mintReferral = rewardsRecipients.length > 0 ? rewardsRecipients[0] : zoraRewardRecipient;
        if (mintReferral == address(0)) {
            mintReferral = zoraRewardRecipient;
        }

        // creator reward recipient is pulled from storage, if it's not set, defaults to zora reward recipient
        address creatorRewardRecipient = getCreatorRewardRecipient(tokenId);
        if (creatorRewardRecipient == address(0)) {
            creatorRewardRecipient = zoraRewardRecipient;
        }

        // first minter is pulled from storage, if it's not set, defaults to creator reward recipient (which is zora if there is no creator reward recipient set)
        address firstMinter = firstMinters[tokenId];
        if (firstMinter == address(0)) {
            firstMinter = creatorRewardRecipient;
        }

        // 2. Get rewards amounts - which varies if its a paid or free mint

        RewardsSettings memory settings;
        if (totalSentValue < totalReward) {
            revert INVALID_ETH_AMOUNT();
            // if value sent is the same as the reward amount, we assume its a free mint
        } else if (totalSentValue == totalReward) {
            settings = RewardSplitsLib.getRewards(false, totalReward);
            // otherwise, we assume its a paid mint
        } else {
            settings = RewardSplitsLib.getRewards(true, totalReward);

            unchecked {
                valueRemaining = totalSentValue - totalReward;
            }
        }

        // 3. Deposit rewards rewards

        protocolRewards.depositRewards{value: totalReward}(
            // if there was no creator reward amount, 0 out that address
            settings.creatorReward == 0 ? address(0) : creatorRewardRecipient,
            settings.creatorReward,
            createReferral,
            settings.createReferralReward,
            mintReferral,
            settings.mintReferralReward,
            firstMinter,
            settings.firstMinterReward,
            zoraRewardRecipient,
            settings.zoraReward
        );
    }

    function _mint(IMinter1155 minter, uint256 tokenId, uint256 quantity, address[] memory rewardsRecipients, bytes calldata minterArguments) private {
        // Require admin from the minter to mint
        _requireAdminOrRole(address(minter), tokenId, PERMISSION_BIT_MINTER);

        uint256 totalReward = mintsManager.getEthPrice() * quantity;

        _mintAndHandleRewards(minter, rewardsRecipients, msg.value, totalReward, tokenId, quantity, minterArguments);
    }

    function _getTotalMintsQuantity(uint256[] calldata mintTokenIds, uint256[] calldata quantities) private pure returns (uint256 totalQuantity) {
        if (mintTokenIds.length != quantities.length) {
            revert Mint_InvalidMintArrayLength();
        }

        for (uint256 i = 0; i < mintTokenIds.length; i++) {
            totalQuantity += quantities[i];
        }
    }

    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and rewards arguments,
    /// while MINTs are redeemed to pay for the mint fee, instead of paying with ETH directly.
    /// The MINTs must have been approved to be transferred to this contract from the msg.sender before calling this function.
    /// Value sent is used for paid mints, if this is a paid mint
    /// @param mintTokenIds The MINT token IDs that are to be redeemed
    /// @param quantities The quantities of each MINT token id to redeem
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param rewardsRecipients The addresses of rewards arguments - rewardsRecipients[0] = mintReferral, rewardsRecipients[1] = platformReferral
    /// @param minterArguments The arguments to pass to the minter
    /// @param quantityMinted The total quantity of tokens minted
    function mintWithMints(
        uint256[] calldata mintTokenIds,
        uint256[] calldata quantities,
        IMinter1155 minter,
        uint256 tokenId,
        address[] memory rewardsRecipients,
        bytes calldata minterArguments
    ) external payable returns (uint256 quantityMinted) {
        // Require admin from the minter to mint
        _requireAdminOrRole(address(minter), tokenId, PERMISSION_BIT_MINTER);

        quantityMinted = _getTotalMintsQuantity(mintTokenIds, quantities);
        IZoraMints1155 mints = mintsManager.zoraMints1155();
        mints.safeBatchTransferFrom(msg.sender, address(this), mintTokenIds, quantities, "");
        Redemption[] memory redemptions = mints.redeemBatch(mintTokenIds, quantities, address(this));

        uint256 totalEthReward = _getEthRedemptionTotal(redemptions);

        _mintAndHandleRewards(minter, rewardsRecipients, msg.value + totalEthReward, totalEthReward, tokenId, quantityMinted, minterArguments);
    }

    function _getEthRedemptionTotal(Redemption[] memory redemptions) private pure returns (uint256 totalEth) {
        for (uint256 i = 0; i < redemptions.length; i++) {
            if (redemptions[i].tokenAddress != address(0)) {
                revert NonEthRedemption();
            }

            totalEth += redemptions[i].valueRedeemed;
        }
    }

    function mintFee() external view returns (uint256) {
        return mintsManager.getEthPrice();
    }

    /// @notice Get the creator reward recipient address for a specific token.
    /// @param tokenId The token id to get the creator reward recipient for
    /// @dev Returns the royalty recipient address for the token if set; otherwise uses the fundsRecipient.
    /// If both are not set, this contract will be set as the recipient, and an account with
    /// `PERMISSION_BIT_FUNDS_MANAGER` will be able to withdraw via the `withdrawFor` function.
    function getCreatorRewardRecipient(uint256 tokenId) public view returns (address) {
        address royaltyRecipient = getRoyalties(tokenId).royaltyRecipient;

        if (royaltyRecipient != address(0)) {
            return royaltyRecipient;
        }

        if (config.fundsRecipient != address(0)) {
            return config.fundsRecipient;
        }

        return address(this);
    }

    /// @notice Set a metadata renderer for a token
    /// @param tokenId The token ID to set the renderer for
    /// @param renderer The renderer to set
    function setTokenMetadataRenderer(uint256 tokenId, IRenderer1155 renderer) external nonReentrant onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        _setRenderer(tokenId, renderer);

        if (tokenId == 0) {
            emit ContractRendererUpdated(renderer);
        } else {
            // We don't know the uri from the renderer but can emit a notification to the indexer here
            emit URI("", tokenId);
        }
    }

    /// Execute Minter Commands ///

    /// @notice Internal functions to execute commands returned by the minter
    /// @param commands list of command structs
    /// @param ethValueSent the ethereum value sent in the mint transaction into the contract
    /// @param tokenId the token id the user requested to mint (0 if the token id is set by the minter itself across the whole contract)
    function _executeCommands(ICreatorCommands.Command[] memory commands, uint256 ethValueSent, uint256 tokenId) internal {
        for (uint256 i = 0; i < commands.length; ++i) {
            ICreatorCommands.CreatorActions method = commands[i].method;
            if (method == ICreatorCommands.CreatorActions.SEND_ETH) {
                (address recipient, uint256 amount) = abi.decode(commands[i].args, (address, uint256));
                if (ethValueSent > amount) {
                    revert Mint_InsolventSaleTransfer();
                }
                if (!TransferHelperUtils.safeSendETH(recipient, amount, TransferHelperUtils.FUNDS_SEND_NORMAL_GAS_LIMIT)) {
                    revert Mint_ValueTransferFail();
                }
            } else if (method == ICreatorCommands.CreatorActions.MINT) {
                (address recipient, uint256 mintTokenId, uint256 quantity) = abi.decode(commands[i].args, (address, uint256, uint256));
                if (tokenId != 0 && mintTokenId != tokenId) {
                    revert Mint_TokenIDMintNotAllowed();
                }
                _mint(recipient, tokenId, quantity, "");
            } else {
                // no-op
            }
        }
    }

    /// @notice Token info getter
    /// @param tokenId token id to get info for
    /// @return TokenData struct returned
    function getTokenInfo(uint256 tokenId) external view returns (TokenData memory) {
        return tokens[tokenId];
    }

    /// @notice Proxy setter for sale contracts (only callable by SALES permission or admin)
    /// @param tokenId The token ID to call the sale contract with
    /// @param salesConfig The sales config contract to call
    /// @param data The data to pass to the sales config contract
    function callSale(uint256 tokenId, IMinter1155 salesConfig, bytes calldata data) external onlyAdminOrRole(tokenId, PERMISSION_BIT_SALES) {
        _requireAdminOrRole(address(salesConfig), tokenId, PERMISSION_BIT_MINTER);
        if (!salesConfig.supportsInterface(type(IMinter1155).interfaceId)) {
            revert Sale_CannotCallNonSalesContract(address(salesConfig));
        }

        // Get the token id encoded in the calldata for the sales config
        // Assume that it is the first 32 bytes following the function selector
        uint256 encodedTokenId = uint256(bytes32(data[4:36]));

        // Ensure the encoded token id matches the passed token id
        if (encodedTokenId != tokenId) {
            revert IZoraCreator1155Errors.Call_TokenIdMismatch();
        }

        (bool success, bytes memory why) = address(salesConfig).call(data);
        if (!success) {
            revert CallFailed(why);
        }
    }

    /// @notice Proxy setter for renderer contracts (only callable by METADATA permission or admin)
    /// @param tokenId The token ID to call the renderer contract with
    /// @param data The data to pass to the renderer contract
    function callRenderer(uint256 tokenId, bytes memory data) external onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        // We assume any renderers set are checked for EIP165 signature during write stage.
        (bool success, bytes memory why) = address(getCustomRenderer(tokenId)).call(data);
        if (!success) {
            revert CallFailed(why);
        }
    }

    /// @notice Returns true if the contract implements the interface defined by interfaceId
    /// @param interfaceId The interface to check for
    /// @return if the interfaceId is marked as supported
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(CreatorRoyaltiesControl, ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IZoraCreator1155).interfaceId ||
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IHasSupportedPremintSignatureVersions).interfaceId ||
            interfaceId == type(ISupportsAABasedDelegatedTokenCreation).interfaceId ||
            interfaceId == type(IMintWithRewardsRecipients).interfaceId ||
            interfaceId == type(IMintWithMints).interfaceId;
    }

    /// Generic 1155 function overrides ///

    /// @notice Mint function that 1) checks quantity 2) keeps track of allowed tokens
    /// @param to to mint to
    /// @param id token id to mint
    /// @param amount of tokens to mint
    /// @param data as specified by 1155 standard
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        _requireCanMintQuantity(id, amount);

        tokens[id].totalMinted += amount;

        super._mint(to, id, amount, data);
    }

    /// @notice Burns a batch of tokens
    /// @dev Only the current owner is allowed to burn
    /// @param from the user to burn from
    /// @param tokenIds The token ID to burn
    /// @param amounts The amount of tokens to burn
    function burnBatch(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert Burn_NotOwnerOrApproved(msg.sender, from);
        }

        _burnBatch(from, tokenIds, amounts);
    }

    function setTransferHook(ITransferHookReceiver transferHook) external onlyAdmin(CONTRACT_BASE_ID) {
        if (address(transferHook) != address(0)) {
            if (!transferHook.supportsInterface(type(ITransferHookReceiver).interfaceId)) {
                revert Config_TransferHookNotSupported(address(transferHook));
            }
        }

        config.transferHook = transferHook;
        emit ConfigUpdated(msg.sender, ConfigUpdate.TRANSFER_HOOK, config);
    }

    /// @notice Hook before token transfer that checks for a transfer hook integration
    /// @param operator operator moving the tokens
    /// @param from from address
    /// @param to to address
    /// @param id token id to move
    /// @param amount amount of token
    /// @param data data of token
    function _beforeTokenTransfer(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._beforeTokenTransfer(operator, from, to, id, amount, data);
        if (address(config.transferHook) != address(0)) {
            config.transferHook.onTokenTransfer(address(this), operator, from, to, id, amount, data);
        }
    }

    /// @notice Hook before token transfer that checks for a transfer hook integration
    /// @param operator operator moving the tokens
    /// @param from from address
    /// @param to to address
    /// @param ids token ids to move
    /// @param amounts amounts of tokens
    /// @param data data of tokens
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);
        if (address(config.transferHook) != address(0)) {
            config.transferHook.onTokenTransferBatch({target: address(this), operator: operator, from: from, to: to, ids: ids, amounts: amounts, data: data});
        }
    }

    /// @notice Returns the URI for the contract
    function contractURI() external view override(IERC7572, IZoraCreator1155) returns (string memory) {
        IRenderer1155 customRenderer = getCustomRenderer(CONTRACT_BASE_ID);
        if (address(customRenderer) != address(0)) {
            return customRenderer.contractURI();
        }
        return uri(0);
    }

    /// @notice Returns the URI for a token
    /// @param tokenId The token ID to return the URI for
    function uri(uint256 tokenId) public view override(ERC1155Upgradeable, IERC1155MetadataURIUpgradeable) returns (string memory) {
        if (bytes(tokens[tokenId].uri).length > 0) {
            return tokens[tokenId].uri;
        }
        return _render(tokenId);
    }

    /// @notice Internal setter for contract admin with no access checks
    /// @param newOwner new owner address
    function _setOwner(address newOwner) internal {
        address lastOwner = config.owner;
        config.owner = newOwner;

        emit OwnershipTransferred(lastOwner, newOwner);
        emit ConfigUpdated(msg.sender, ConfigUpdate.OWNER, config);
    }

    /// @notice Set funds recipient address
    /// @param fundsRecipient new funds recipient address
    function setFundsRecipient(address payable fundsRecipient) external onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_FUNDS_MANAGER) {
        _setFundsRecipient(fundsRecipient);
    }

    /// @notice Internal no-checks set funds recipient address
    /// @param fundsRecipient new funds recipient address
    function _setFundsRecipient(address payable fundsRecipient) internal {
        config.fundsRecipient = fundsRecipient;
        emit ConfigUpdated(msg.sender, ConfigUpdate.FUNDS_RECIPIENT, config);
    }

    /// @notice Allows the create referral to update the address that can claim their rewards
    function updateCreateReferral(uint256 tokenId, address recipient) external {
        if (msg.sender != createReferrals[tokenId]) revert ONLY_CREATE_REFERRAL();

        _setCreateReferral(tokenId, recipient);
    }

    function _setCreateReferral(uint256 tokenId, address recipient) internal {
        createReferrals[tokenId] = recipient;
    }

    /// @notice Withdraws all ETH from the contract to the funds recipient address
    function withdraw() public onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_FUNDS_MANAGER) {
        uint256 contractValue = address(this).balance;
        if (!TransferHelperUtils.safeSendETH(config.fundsRecipient, contractValue, TransferHelperUtils.FUNDS_SEND_NORMAL_GAS_LIMIT)) {
            revert ETHWithdrawFailed(config.fundsRecipient, contractValue);
        }
    }

    receive() external payable {}

    ///                                                          ///
    ///                         MANAGER UPGRADE                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal view override onlyAdmin(CONTRACT_BASE_ID) {
        if (!upgradeGate.isRegisteredUpgradePath(_getImplementation(), _newImpl)) {
            revert();
        }
    }

    /// @notice Returns the current implementation address
    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function supportedPremintSignatureVersions() external pure returns (string[] memory) {
        return DelegatedTokenCreation.supportedPremintSignatureVersions();
    }

    /// Sets up a new token using a token configuration and a signature created for the token creation parameters.
    /// The signature must be created by an account with the PERMISSION_BIT_MINTER role on the contract.
    /// @param premintConfig abi encoded configuration of token to be created
    /// @param premintVersion version of the premint configuration
    /// @param signature EIP-712 Signature created on the premintConfig by an account with the PERMISSION_BIT_MINTER role on the contract.
    /// @param firstMinter original sender of the transaction, used to set the firstMinter
    /// @param premintSignerContract if an EIP-1271 based premint, the contract that signed the premint
    function delegateSetupNewToken(
        bytes memory premintConfig,
        bytes32 premintVersion,
        bytes calldata signature,
        address firstMinter,
        address premintSignerContract
    ) external nonReentrant returns (uint256 newTokenId) {
        if (firstMinter == address(0)) {
            revert FirstMinterAddressZero();
        }
        (DelegatedTokenSetup memory params, DecodedCreatorAttribution memory attribution, bytes[] memory tokenSetupActions) = DelegatedTokenCreation
            .decodeAndRecoverDelegatedTokenSetup(premintConfig, premintVersion, signature, address(this), nextTokenId, premintSignerContract);

        // if a token has already been created for a premint config with this uid:
        if (delegatedTokenId[params.uid] != 0) {
            // return its token id
            return delegatedTokenId[params.uid];
        }

        // this is what attributes this token to have been created by the original creator
        emit CreatorAttribution(attribution.structHash, attribution.domainName, attribution.version, attribution.creator, attribution.signature);

        return _delegateSetupNewToken(params, attribution.creator, tokenSetupActions, firstMinter);
    }

    function _delegateSetupNewToken(
        DelegatedTokenSetup memory params,
        address creator,
        bytes[] memory tokenSetupActions,
        address sender
    ) internal returns (uint256 newTokenId) {
        // require that the signer can create new tokens (is a valid creator)
        _requireAdminOrRole(creator, CONTRACT_BASE_ID, PERMISSION_BIT_MINTER);

        // create the new token; msg sender will have PERMISSION_BIT_ADMIN on the new token
        newTokenId = _setupNewTokenAndPermission(params.tokenURI, params.maxSupply, msg.sender, PERMISSION_BIT_ADMIN);

        _setCreateReferral(newTokenId, params.createReferral);

        delegatedTokenId[params.uid] = newTokenId;

        firstMinters[newTokenId] = sender;

        // then invoke them, calling account should be original msg.sender, which has admin on the new token
        _multicallInternal(tokenSetupActions);

        // remove the token creator as admin of the newly created token:
        _removePermission(newTokenId, msg.sender, PERMISSION_BIT_ADMIN);

        // grant the token creator as admin of the newly created token
        _addPermission(newTokenId, creator, PERMISSION_BIT_ADMIN);
    }

    // /// Allows receiving ERC1155 tokens
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external view onlyMints returns (bytes4) {
        return ON_ERC1155_RECEIVED_HASH;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external view onlyMints returns (bytes4) {
        return ON_ERC1155_BATCH_RECEIVED_HASH;
    }
}

// SPDX-License-Identifier: MIT
// Modifications from OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol):
// - Revert strings replaced with custom errors
// - Decoupled hooks 
//   - `_beforeTokenTransfer` --> `_beforeTokenTransfer` & `_beforeBatchTokenTransfer`
//   - `_afterTokenTransfer` --> `_afterTokenTransfer` & `_afterBatchTokenTransfer`
// - Minor gas optimizations (eg. array length caching, unchecked loop iteration)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

error ERC1155_ADDRESS_ZERO_IS_NOT_A_VALID_OWNER();
error ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
error ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
error ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
error ERC1155_TRANSFER_TO_ZERO_ADDRESS();
error ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
error ERC1155_MINT_TO_ZERO_ADDRESS();
error ERC1155_BURN_FROM_ZERO_ADDRESS();
error ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
error ERC1155_SETTING_APPROVAL_FOR_SELF();
error ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
error ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == address(0)) {
            revert ERC1155_ADDRESS_ZERO_IS_NOT_A_VALID_OWNER();
        }
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory batchBalances) {
        uint256 numAccounts = accounts.length;

        if (numAccounts != ids.length) {
            revert ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
        }

        batchBalances = new uint256[](numAccounts);

        unchecked {
            for (uint256 i; i < numAccounts; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }
        }
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
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
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
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
        if (to == address(0)) {
            revert ERC1155_TRANSFER_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, id, amount, data);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, id, amount, data);

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
        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_ACCOUNTS_AND_IDS_LENGTH_MISMATCH();
        }
        if (to == address(0)) {
            revert ERC1155_TRANSFER_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 id;
        uint256 amount;
        uint256 fromBalance;

        for (uint256 i; i < numIds; ) {
            id = ids[i];
            amount = amounts[i];
            fromBalance = _balances[id][from];

            if (fromBalance < amount) {
                revert ERC1155_INSUFFICIENT_BALANCE_FOR_TRANSFER();
            }

            _balances[id][to] += amount;

            unchecked {
                _balances[id][from] = fromBalance - amount;

                ++i;
            }


        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterBatchTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
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
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if (to == address(0)) {
            revert ERC1155_MINT_TO_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, id, amount, data);

        _balances[id][to] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, id, amount, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
        if (to == address(0)) {
            revert ERC1155_MINT_TO_ZERO_ADDRESS();
        }

        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i; i < numIds; ) {
            _balances[ids[i]][to] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
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
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if (from == address(0)) {
            revert ERC1155_BURN_FROM_ZERO_ADDRESS();
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), id, amount, "");

        uint256 fromBalance = _balances[id][from];

        if (fromBalance < amount) {
            revert ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), id, amount, "");
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
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        if (from == address(0)) {
            revert ERC1155_BURN_FROM_ZERO_ADDRESS();
        }

        uint256 numIds = ids.length;

        if (numIds != amounts.length) {
            revert ERC1155_IDS_AND_AMOUNTS_LENGTH_MISMATCH();
        }

        address operator = _msgSender();

        _beforeBatchTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 id;
        uint256 amount;
        uint256 fromBalance;
        for (uint256 i; i < numIds; ) {
            id = ids[i];
            amount = amounts[i];

            fromBalance = _balances[id][from];

            if (fromBalance < amount) {
                revert ERC1155_BURN_AMOUNT_EXCEEDS_BALANCE();
            }

            unchecked {
                _balances[id][from] = fromBalance - amount;

                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterBatchTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (owner == operator) {
            revert ERC1155_SETTING_APPROVAL_FOR_SELF();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before a single token transfer.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual { }


    /**
     * @dev Hook that is called before a batch token transfer.
     */
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after a single token transfer.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after a batch token transfer.
     */
    function _afterBatchTokenTransfer(
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert ERC1155_ERC1155RECEIVER_REJECTED_TOKENS();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_TRANSFER_TO_NON_ERC1155RECEIVER_IMPLEMENTER();
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

error FUNCTION_MUST_BE_CALLED_THROUGH_DELEGATECALL();
error FUNCTION_MUST_BE_CALLED_THROUGH_ACTIVE_PROXY();
error UUPS_UPGRADEABLE_MUST_NOT_BE_CALLED_THROUGH_DELEGATECALL();

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        if (address(this) == __self) {
            revert FUNCTION_MUST_BE_CALLED_THROUGH_DELEGATECALL();
        }
        if (_getImplementation() != __self) {
            revert FUNCTION_MUST_BE_CALLED_THROUGH_ACTIVE_PROXY();
        }
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) {
            revert UUPS_UPGRADEABLE_MUST_NOT_BE_CALLED_THROUGH_DELEGATECALL();
        }
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IProtocolRewards
/// @notice The interface for deposits & withdrawals for Protocol Rewards
interface IProtocolRewards {
    /// @notice Rewards Deposit Event
    /// @param creator Creator for NFT rewards
    /// @param createReferral Creator referral
    /// @param mintReferral Mint referral user
    /// @param firstMinter First minter reward recipient
    /// @param zora ZORA recipient
    /// @param from The caller of the deposit
    /// @param creatorReward Creator reward amount
    /// @param createReferralReward Creator referral reward
    /// @param mintReferralReward Mint referral amount
    /// @param firstMinterReward First minter reward amount
    /// @param zoraReward ZORA amount
    event RewardsDeposit(
        address indexed creator,
        address indexed createReferral,
        address indexed mintReferral,
        address firstMinter,
        address zora,
        address from,
        uint256 creatorReward,
        uint256 createReferralReward,
        uint256 mintReferralReward,
        uint256 firstMinterReward,
        uint256 zoraReward
    );

    /// @notice Deposit Event
    /// @param from From user
    /// @param to To user (within contract)
    /// @param reason Optional bytes4 reason for indexing
    /// @param amount Amount of deposit
    /// @param comment Optional user comment
    event Deposit(address indexed from, address indexed to, bytes4 indexed reason, uint256 amount, string comment);

    /// @notice Withdraw Event
    /// @param from From user
    /// @param to To user (within contract)
    /// @param amount Amount of deposit
    event Withdraw(address indexed from, address indexed to, uint256 amount);

    /// @notice Cannot send to address zero
    error ADDRESS_ZERO();

    /// @notice Function argument array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @notice Invalid deposit
    error INVALID_DEPOSIT();

    /// @notice Invalid signature for deposit
    error INVALID_SIGNATURE();

    /// @notice Invalid withdraw
    error INVALID_WITHDRAW();

    /// @notice Signature for withdraw is too old and has expired
    error SIGNATURE_DEADLINE_EXPIRED();

    /// @notice Low-level ETH transfer has failed
    error TRANSFER_FAILED();

    /// @notice Generic function to deposit ETH for a recipient, with an optional comment
    /// @param to Address to deposit to
    /// @param to Reason system reason for deposit (used for indexing)
    /// @param comment Optional comment as reason for deposit
    function deposit(address to, bytes4 why, string calldata comment) external payable;

    /// @notice Generic function to deposit ETH for multiple recipients, with an optional comment
    /// @param recipients recipients to send the amount to, array aligns with amounts
    /// @param amounts amounts to send to each recipient, array aligns with recipients
    /// @param reasons optional bytes4 hash for indexing
    /// @param comment Optional comment to include with mint
    function depositBatch(address[] calldata recipients, uint256[] calldata amounts, bytes4[] calldata reasons, string calldata comment) external payable;

    /// @notice Used by Zora ERC-721 & ERC-1155 contracts to deposit protocol rewards
    /// @param creator Creator for NFT rewards
    /// @param creatorReward Creator reward amount
    /// @param createReferral Creator referral
    /// @param createReferralReward Creator referral reward
    /// @param mintReferral Mint referral user
    /// @param mintReferralReward Mint referral amount
    /// @param firstMinter First minter reward
    /// @param firstMinterReward First minter reward amount
    /// @param zora ZORA recipient
    /// @param zoraReward ZORA amount
    function depositRewards(
        address creator,
        uint256 creatorReward,
        address createReferral,
        uint256 createReferralReward,
        address mintReferral,
        uint256 mintReferralReward,
        address firstMinter,
        uint256 firstMinterReward,
        address zora,
        uint256 zoraReward
    ) external payable;

    /// @notice Withdraw protocol rewards
    /// @param to Withdraws from msg.sender to this address
    /// @param amount amount to withdraw
    function withdraw(address to, uint256 amount) external;

    /// @notice Execute a withdraw of protocol rewards via signature
    /// @param from Withdraw from this address
    /// @param to Withdraw to this address
    /// @param amount Amount to withdraw
    /// @param deadline Deadline for the signature to be valid
    /// @param v V component of signature
    /// @param r R component of signature
    /// @param s S component of signature
    function withdrawWithSig(address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IProtocolRewards} from "../interfaces/IProtocolRewards.sol";
import {IRewardSplits} from "../interfaces/IRewardSplits.sol";

library RewardSplitsLib {
    uint256 internal constant BPS_TO_PERCENT = 10_0000000;
    uint256 internal constant TOTAL_REWARD_PER_MINT_PCT = 10_0000000;

    uint256 internal constant CREATOR_REWARD_PCT = 42_857100; // 42.8571%, roughly 0.000333 ETH at a 0.000777 value
    uint256 internal constant FIRST_MINTER_REWARD_PCT = 14_228500; // 14.2285%, roughly 0.000111 ETH at a 0.000777 value

    uint256 internal constant CREATE_REFERRAL_FREE_MINT_REWARD_PCT = 14_228500; // 14.2285%, roughly 0.000111 ETH at a 0.000777 value
    uint256 internal constant MINT_REFERRAL_FREE_MINT_REWARD_PCT = 14_228500; // 14.2285%, roughly 0.000111 ETH at a 0.000777 value
    uint256 internal constant ZORA_FREE_MINT_REWARD_PCT = 14_228500; // 14.2285%, roughly 0.000111 ETH at a 0.000777 value

    uint256 internal constant CREATE_REFERRAL_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value
    uint256 internal constant MINT_REFERRAL_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value
    uint256 internal constant ZORA_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value

    function computeRewardsPct(uint256 totalReward, uint256 rewardPct) internal pure returns (uint256) {
        return (totalReward * rewardPct) / BPS_TO_PERCENT;
    }

    function getRewardsSettingsPct(bool paidMint) private pure returns (IRewardSplits.RewardsSettings memory rewardSettings) {
        rewardSettings.creatorReward = paidMint ? 0 : CREATOR_REWARD_PCT;
        rewardSettings.createReferralReward = paidMint ? CREATE_REFERRAL_PAID_MINT_REWARD_PCT : CREATE_REFERRAL_FREE_MINT_REWARD_PCT;
        rewardSettings.mintReferralReward = paidMint ? MINT_REFERRAL_PAID_MINT_REWARD_PCT : MINT_REFERRAL_FREE_MINT_REWARD_PCT;
        rewardSettings.firstMinterReward = FIRST_MINTER_REWARD_PCT;
        // do we need this? since its recalculated below?
        // rewardSettings.zoraReward = totalReward - (rewardSettings.creatorReward + rewardSettings.createReferralReward + rewardSettings.mintReferralReward + rewardSettings.firstMinterReward);
    }

    function getRewards(bool paidMint, uint256 totalReward) internal pure returns (IRewardSplits.RewardsSettings memory rewardSettings) {
        rewardSettings = getRewardsSettingsPct(paidMint);
        rewardSettings.creatorReward = computeRewardsPct(totalReward, rewardSettings.creatorReward);
        rewardSettings.createReferralReward = computeRewardsPct(totalReward, rewardSettings.createReferralReward);
        rewardSettings.mintReferralReward = computeRewardsPct(totalReward, rewardSettings.mintReferralReward);
        rewardSettings.firstMinterReward = computeRewardsPct(totalReward, rewardSettings.firstMinterReward);
        rewardSettings.zoraReward =
            totalReward -
            (rewardSettings.creatorReward + rewardSettings.createReferralReward + rewardSettings.mintReferralReward + rewardSettings.firstMinterReward);
    }
}

/// @notice Common logic for between Zora ERC-721 & ERC-1155 contracts for protocol reward splits & deposits
abstract contract RewardSplits is IRewardSplits {
    address internal immutable zoraRewardRecipient;
    IProtocolRewards internal immutable protocolRewards;

    constructor(address _protocolRewards, address _zoraRewardRecipient) payable {
        if (_protocolRewards == address(0) || _zoraRewardRecipient == address(0)) {
            revert INVALID_ADDRESS_ZERO();
        }

        protocolRewards = IProtocolRewards(_protocolRewards);
        zoraRewardRecipient = _zoraRewardRecipient;
    }

    function computeTotalReward(uint256 mintPrice, uint256 quantity) public pure returns (uint256) {
        return mintPrice * quantity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ERC1155RewardsStorageV1 {
    mapping(uint256 => address) public createReferrals;

    mapping(uint256 => address) public firstMinters;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC1155MetadataURIUpgradeable.sol";
import {IZoraCreator1155TypesV1} from "../nft/IZoraCreator1155TypesV1.sol";
import {IZoraCreator1155Errors} from "./IZoraCreator1155Errors.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {IVersionedContract} from "@zoralabs/shared-contracts/interfaces/IVersionedContract.sol";
import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";
import {IZoraCreator1155DelegatedCreation} from "./IZoraCreator1155DelegatedCreation.sol";
import {IMintWithRewardsRecipients} from "./IMintWithRewardsRecipients.sol";
import {IMintWithMints} from "@zoralabs/mints-contracts/src/IMintWithMints.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,

 */

/// @notice Main interface for the ZoraCreator1155 contract
/// @author @iainnash / @tbtstl
interface IZoraCreator1155 is
    IZoraCreator1155TypesV1,
    IZoraCreator1155Errors,
    IVersionedContract,
    IOwnable,
    IERC1155MetadataURIUpgradeable,
    IZoraCreator1155DelegatedCreation,
    IMintWithRewardsRecipients,
    IMintWithMints
{
    function PERMISSION_BIT_ADMIN() external returns (uint256);

    /// @notice This user role allows for only mint actions to be performed
    function PERMISSION_BIT_MINTER() external returns (uint256);

    /// @notice This user role allows for only managing sales configurations
    function PERMISSION_BIT_SALES() external returns (uint256);

    /// @notice This user role allows for only managing metadata configuration
    function PERMISSION_BIT_METADATA() external returns (uint256);

    /// @notice This user role allows for only withdrawing funds and setting funds withdraw address
    function PERMISSION_BIT_FUNDS_MANAGER() external returns (uint256);

    /// @notice Used to label the configuration update type
    enum ConfigUpdate {
        OWNER,
        FUNDS_RECIPIENT,
        TRANSFER_HOOK
    }
    event ConfigUpdated(address indexed updater, ConfigUpdate indexed updateType, ContractConfig newConfig);

    event UpdatedToken(address indexed from, uint256 indexed tokenId, TokenData tokenData);
    event SetupNewToken(uint256 indexed tokenId, address indexed sender, string newURI, uint256 maxSupply);

    function setOwner(address newOwner) external;

    function owner() external view returns (address);

    event ContractRendererUpdated(IRenderer1155 renderer);
    event ContractMetadataUpdated(address indexed updater, string uri, string name);
    event Purchased(address indexed sender, address indexed minter, uint256 indexed tokenId, uint256 quantity, uint256 value);

    /// @dev Deprecated: call mint
    function mintWithRewards(IMinter1155 minter, uint256 tokenId, uint256 quantity, bytes calldata minterArguments, address mintReferral) external payable;

    function adminMint(address recipient, uint256 tokenId, uint256 quantity, bytes memory data) external;

    function burnBatch(address user, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /// @notice Contract call to setupNewToken
    /// @param tokenURI URI for the token
    /// @param maxSupply maxSupply for the token, set to 0 for open edition
    function setupNewToken(string memory tokenURI, uint256 maxSupply) external returns (uint256 tokenId);

    function setupNewTokenWithCreateReferral(string calldata newURI, uint256 maxSupply, address createReferral) external returns (uint256);

    function getCreatorRewardRecipient(uint256 tokenId) external view returns (address);

    function updateTokenURI(uint256 tokenId, string memory _newURI) external;

    function updateContractMetadata(string memory _newURI, string memory _newName) external;

    // Public interface for `setTokenMetadataRenderer(uint256, address) has been deprecated.

    function contractURI() external view returns (string memory);

    function assumeLastTokenIdMatches(uint256 tokenId) external;

    function updateRoyaltiesForToken(uint256 tokenId, ICreatorRoyaltiesControl.RoyaltyConfiguration memory royaltyConfiguration) external;

    /// @notice Set funds recipient address
    /// @param fundsRecipient new funds recipient address
    function setFundsRecipient(address payable fundsRecipient) external;

    /// @notice Allows the create referral to update the address that can claim their rewards
    function updateCreateReferral(uint256 tokenId, address recipient) external;

    function addPermission(uint256 tokenId, address user, uint256 permissionBits) external;

    function removePermission(uint256 tokenId, address user, uint256 permissionBits) external;

    function isAdminOrRole(address user, uint256 tokenId, uint256 role) external view returns (bool);

    function getTokenInfo(uint256 tokenId) external view returns (TokenData memory);

    function callRenderer(uint256 tokenId, bytes memory data) external;

    function callSale(uint256 tokenId, IMinter1155 salesConfig, bytes memory data) external;

    function mintFee() external view returns (uint256);

    /// @notice Withdraws all ETH from the contract to the funds recipient address
    function withdraw() external;

    /// @notice Returns the current implementation address
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";

interface IZoraCreator1155Initializer {
    function initialize(
        string memory contractName,
        string memory newContractURI,
        ICreatorRoyaltiesControl.RoyaltyConfiguration memory defaultRoyaltyConfiguration,
        address payable defaultAdmin,
        bytes[] calldata setupActions
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC7572 {
    function contractURI() external view returns (string memory);

    event ContractURIUpdated();
}

// This file is automatically generated by code; do not manually update
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVersionedContract} from "@zoralabs/shared-contracts/interfaces/IVersionedContract.sol";

/// @title ContractVersionBase
/// @notice Base contract for versioning contracts
contract ContractVersionBase is IVersionedContract {
    /// @notice The version of the contract
    function contractVersion() external pure override returns (string memory) {
        return "2.9.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorPermissionStorageV1} from "./CreatorPermissionStorageV1.sol";
import {ICreatorPermissionControl} from "../interfaces/ICreatorPermissionControl.sol";

/// Imagine. Mint. Enjoy.
/// @author @iainnash / @tbtstl
contract CreatorPermissionControl is CreatorPermissionStorageV1, ICreatorPermissionControl {
    /// @notice Check if the user has any of the given permissions
    /// @dev if multiple permissions are passed in this checks for any one of those permissions
    /// @return true or false if any of the passed in permissions apply
    function _hasAnyPermission(uint256 tokenId, address user, uint256 permissionBits) internal view returns (bool) {
        // Does a bitwise and and checks if any of those permissions match
        return permissions[tokenId][user] & permissionBits > 0;
    }

    /// @notice addPermission – internal function to add a set of permission bits to a user
    /// @param tokenId token id to add the permission to (0 indicates contract-wide add)
    /// @param user user to update permissions for
    /// @param permissionBits bits to add permissions to
    function _addPermission(uint256 tokenId, address user, uint256 permissionBits) internal {
        uint256 tokenPermissions = permissions[tokenId][user];
        tokenPermissions |= permissionBits;
        permissions[tokenId][user] = tokenPermissions;
        emit UpdatedPermissions(tokenId, user, tokenPermissions);
    }

    /// @notice _clearPermission clear permissions for user
    /// @param tokenId token id to clear permission from (0 indicates contract-wide action)
    function _clearPermissions(uint256 tokenId, address user) internal {
        permissions[tokenId][user] = 0;
        emit UpdatedPermissions(tokenId, user, 0);
    }

    /// @notice _removePermission removes permissions for user
    /// @param tokenId token id to clear permission from (0 indicates contract-wide action)
    /// @param user user to manage permissions for
    /// @param permissionBits set of permission bits to remove
    function _removePermission(uint256 tokenId, address user, uint256 permissionBits) internal {
        uint256 tokenPermissions = permissions[tokenId][user];
        tokenPermissions &= ~permissionBits;
        permissions[tokenId][user] = tokenPermissions;
        emit UpdatedPermissions(tokenId, user, tokenPermissions);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorRendererStorageV1} from "./CreatorRendererStorageV1.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";

/// @title CreatorRendererControl
/// @notice Contract for managing the renderer of an 1155 contract
abstract contract CreatorRendererControl is CreatorRendererStorageV1, SharedBaseConstants {
    function _setRenderer(uint256 tokenId, IRenderer1155 renderer) internal {
        customRenderers[tokenId] = renderer;
        if (address(renderer) != address(0)) {
            if (!renderer.supportsInterface(type(IRenderer1155).interfaceId)) {
                revert RendererNotValid(address(renderer));
            }
        }

        emit RendererUpdated({tokenId: tokenId, renderer: address(renderer), user: msg.sender});
    }

    /// @notice Return the renderer for a given token
    /// @dev Returns address 0 for no results
    /// @param tokenId The token to get the renderer for
    function getCustomRenderer(uint256 tokenId) public view returns (IRenderer1155 customRenderer) {
        customRenderer = customRenderers[tokenId];
        if (address(customRenderer) == address(0)) {
            customRenderer = customRenderers[CONTRACT_BASE_ID];
        }
    }

    /// @notice Function called to render when an empty tokenURI exists on the contract
    function _render(uint256 tokenId) internal view returns (string memory) {
        return getCustomRenderer(tokenId).uri(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorRoyaltiesStorageV1} from "./CreatorRoyaltiesStorageV1.sol";
import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";
import {ICreatorRoyaltyErrors} from "../interfaces/ICreatorRoyaltiesControl.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// Imagine. Mint. Enjoy.
/// @title CreatorRoyaltiesControl
/// @author ZORA @iainnash / @tbtstl
/// @notice Contract for managing the royalties of an 1155 contract
abstract contract CreatorRoyaltiesControl is CreatorRoyaltiesStorageV1, SharedBaseConstants {
    uint256 immutable ROYALTY_BPS_TO_PERCENT = 10_000;

    /// @notice The royalty information for a given token.
    /// @param tokenId The token ID to get the royalty information for.
    function getRoyalties(uint256 tokenId) public view returns (RoyaltyConfiguration memory) {
        if (royalties[tokenId].royaltyRecipient != address(0)) {
            return royalties[tokenId];
        }
        // Otherwise, return default.
        return royalties[CONTRACT_BASE_ID];
    }

    /// @notice Returns the royalty information for a given token.
    /// @param tokenId The token ID to get the royalty information for.
    /// @param salePrice The sale price of the NFT asset specified by tokenId
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyConfiguration memory config = getRoyalties(tokenId);
        royaltyAmount = (config.royaltyBPS * salePrice) / ROYALTY_BPS_TO_PERCENT;
        receiver = config.royaltyRecipient;
    }

    function _updateRoyalties(uint256 tokenId, RoyaltyConfiguration memory configuration) internal {
        // If a nonzero royalty mint schedule is set:
        if (configuration.royaltyMintSchedule != 0) {
            // Set the value to zero
            configuration.royaltyMintSchedule = 0;
        }
        // Don't allow setting royalties to burn address
        if (configuration.royaltyRecipient == address(0) && configuration.royaltyBPS > 0) {
            revert ICreatorRoyaltyErrors.InvalidMintSchedule();
        }
        royalties[tokenId] = configuration;

        emit UpdatedRoyalties(tokenId, msg.sender, configuration);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICreatorCommands} from "@zoralabs/shared-contracts/interfaces/ICreatorCommands.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMinter1155} from "@zoralabs/shared-contracts/interfaces/IMinter1155.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";

/// @dev IERC165 type required
interface IRenderer1155 is IERC165Upgradeable {
    /// @notice Called for assigned tokenId, or when token id is globally set to a renderer
    /// @dev contract target is assumed to be msg.sender
    /// @param tokenId token id to get uri for
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Only called for tokenId == 0
    /// @dev contract target is assumed to be msg.sender
    function contractURI() external view returns (string memory);

    /// @notice Sets up renderer from contract
    /// @param initData data to setup renderer with
    /// @dev contract target is assumed to be msg.sender
    function setup(bytes memory initData) external;

    // IERC165 type required – set in base helper
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";

interface ITransferHookReceiver is IERC165Upgradeable {
    /// @notice Token transfer batch callback
    /// @param target target contract for transfer
    /// @param operator operator address for transfer
    /// @param from user address for amount transferred
    /// @param to user address for amount transferred
    /// @param ids list of token ids transferred
    /// @param amounts list of values transferred
    /// @param data data as perscribed by 1155 standard
    function onTokenTransferBatch(
        address target,
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /// @notice Token transfer batch callback
    /// @param target target contract for transfer
    /// @param operator operator address for transfer
    /// @param from user address for amount transferred
    /// @param to user address for amount transferred
    /// @param id token id transferred
    /// @param amount value transferred
    /// @param data data as perscribed by 1155 standard
    function onTokenTransfer(address target, address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    // IERC165 type required
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Factory Upgrade Gate Admin Factory Implementation – Allows specific contract upgrades as a safety measure
interface IUpgradeGate {
    /// @notice Event emitted when upgrade gate is emitted
    event UpgradeGateSetup();

    /// @notice If an implementation is registered by the Builder DAO as an optional upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function isRegisteredUpgradePath(address baseImpl, address upgradeImpl) external view returns (bool);

    /// @notice Called by the Builder DAO to offer implementation upgrades for created DAOs
    /// @param baseImpls The base implementation addresses
    /// @param upgradeImpl The upgrade implementation address
    function registerUpgradePath(address[] memory baseImpls, address upgradeImpl) external;

    /// @notice Called by the Builder DAO to remove an upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function removeUpgradePath(address baseImpl, address upgradeImpl) external;

    event UpgradeRegistered(address indexed baseImpl, address indexed upgradeImpl);
    event UpgradeRemoved(address indexed baseImpl, address indexed upgradeImpl);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILegacyNaming} from "@zoralabs/shared-contracts/interfaces/ILegacyNaming.sol";
import {LegacyNamingStorageV1} from "./LegacyNamingStorageV1.sol";

/// @title LegacyNamingControl
/// @notice Contract for managing the name and symbol of an 1155 contract in the legacy naming scheme
contract LegacyNamingControl is LegacyNamingStorageV1, ILegacyNaming {
    /// @notice The name of the contract
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice The token symbol of the contract
    function symbol() external pure returns (string memory) {}

    function _setName(string memory _newName) internal {
        _name = _newName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title PublicMulticall
/// @notice Contract for executing a batch of function calls on this contract
abstract contract PublicMulticall {
    /**
     * @notice Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }

    /**
     * @notice Receives and executes a batch of function calls on this contract.
     */
    function _multicallInternal(bytes[] memory data) internal virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SharedBaseConstants {
    uint256 public constant CONTRACT_BASE_ID = 0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title TransferHelperUtils
/// @notice Helper functions for sending ETH
library TransferHelperUtils {
    /// @dev Gas limit to send funds
    uint256 internal constant FUNDS_SEND_LOW_GAS_LIMIT = 110_000;

    // @dev Gas limit to send funds – usable for splits, can use with withdraws
    uint256 internal constant FUNDS_SEND_NORMAL_GAS_LIMIT = 310_000;

    /// @notice Sends ETH to a recipient, making conservative estimates to not run out of gas
    /// @param recipient The address to send ETH to
    /// @param value The amount of ETH to send
    function safeSendETH(address recipient, uint256 value, uint256 gasLimit) internal returns (bool success) {
        (success, ) = recipient.call{value: value, gas: gasLimit}("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IZoraCreator1155TypesV1} from "./IZoraCreator1155TypesV1.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-1155-contracts

 */

/// Imagine. Mint. Enjoy.
/// @notice Storage for 1155 contract
/// @author @iainnash / @tbtstl
contract ZoraCreator1155StorageV1 is IZoraCreator1155TypesV1 {
    /// @notice token data stored for each token
    mapping(uint256 => TokenData) internal tokens;

    /// @notice metadata renderer contract for each token
    mapping(uint256 => address) public metadataRendererContract;

    /// @notice next token id available when using a linear mint style (default for launch)
    uint256 public nextTokenId;

    /// @notice Global contract configuration
    ContractConfig public config;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IZoraCreator1155Errors} from "@zoralabs/shared-contracts/interfaces/errors/IZoraCreator1155Errors.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ERC1155DelegationStorageV1 {
    mapping(uint32 => uint256) public delegatedTokenId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHasCreatorAttribution {
    event CreatorAttribution(bytes32 structHash, string domainName, string version, address creator, bytes signature);
}

interface IHasSupportedPremintSignatureVersions {
    function supportedPremintSignatureVersions() external pure returns (string[] memory);
}

// this is the current version of the Zora Token contract creation
interface ISupportsAABasedDelegatedTokenCreation {
    function delegateSetupNewToken(
        bytes memory premintConfigEncoded,
        bytes32 premintVersion,
        bytes calldata signature,
        address sender,
        address premintSignerContract
    ) external returns (uint256 newTokenId);
}

interface IZoraCreator1155DelegatedCreation is IHasCreatorAttribution, IHasSupportedPremintSignatureVersions, ISupportsAABasedDelegatedTokenCreation {}

// this was the legacy interface which has both functions bundled in it - ideally these would be defined in their
// own interfaces that can be checked if the interface method is supported.  going forward (above) they are separate
interface IZoraCreator1155DelegatedCreationLegacy {
    event CreatorAttribution(bytes32 structHash, string domainName, string version, address creator, bytes signature);

    function supportedPremintSignatureVersions() external pure returns (string[] memory);

    function delegateSetupNewToken(
        bytes memory premintConfigEncoded,
        bytes32 premintVersion,
        bytes calldata signature,
        address sender
    ) external returns (uint256 newTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMinter1155} from "./IMinter1155.sol";

interface IMintWithRewardsRecipients {
    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and rewards arguments
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param rewardsRecipients The addresses of rewards arguments - mintReferral and platformReferral
    /// @param minterArguments The arguments to pass to the minter
    function mint(IMinter1155 minter, uint256 tokenId, uint256 quantity, address[] memory rewardsRecipients, bytes calldata minterArguments) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IZoraCreator1155} from "../interfaces/IZoraCreator1155.sol";
import {IZoraCreator1155Errors} from "@zoralabs/shared-contracts/interfaces/errors/IZoraCreator1155Errors.sol";
import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";
import {ECDSAUpgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import {ZoraCreatorFixedPriceSaleStrategy} from "../minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import {PremintEncoding} from "@zoralabs/shared-contracts/premint/PremintEncoding.sol";
import {IERC20Minter, ERC20Minter} from "../minters/erc20/ERC20Minter.sol";
import {IERC1271} from "../interfaces/IERC1271.sol";

import {PremintConfig, ContractCreationConfig, TokenCreationConfig, PremintConfigV2, TokenCreationConfigV2, Erc20TokenCreationConfigV1, Erc20PremintConfigV1} from "@zoralabs/shared-contracts/entities/Premint.sol";

library ZoraCreator1155Attribution {
    string internal constant NAME = "Preminter";
    bytes32 internal constant HASHED_NAME = keccak256(bytes(NAME));

    /**
     * @dev Returns the domain separator for the specified chain.
     */
    function _domainSeparatorV4(uint256 chainId, address verifyingContract, bytes32 hashedName, bytes32 hashedVersion) private pure returns (bytes32) {
        return _buildDomainSeparator(hashedName, hashedVersion, verifyingContract, chainId);
    }

    function _buildDomainSeparator(bytes32 nameHash, bytes32 versionHash, address verifyingContract, uint256 chainId) private pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, nameHash, versionHash, chainId, verifyingContract));
    }

    function _hashTypedDataV4(
        bytes32 structHash,
        bytes32 hashedName,
        bytes32 hashedVersion,
        address verifyingContract,
        uint256 chainId
    ) private pure returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(chainId, verifyingContract, hashedName, hashedVersion), structHash);
    }

    /// @notice Define magic value to verify smart contract signatures (ERC1271).
    bytes4 internal constant MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    function recoverSignerHashed(
        bytes32 hashedPremintConfig,
        bytes calldata signature,
        address erc1155Contract,
        bytes32 signatureVersion,
        uint256 chainId,
        address premintSignerContract
    ) internal view returns (address signatory) {
        // first validate the signature - the creator must match the signer of the message
        bytes32 digest = premintHashedTypeDataV4(
            hashedPremintConfig,
            // here we pass the current contract and chain id, ensuring that the message
            // only works for the current chain and contract id
            erc1155Contract,
            signatureVersion,
            chainId
        );

        if (premintSignerContract != address(0)) {
            // if the smart contract wallet is set, then the signature must be validated by that address
            if (premintSignerContract.code.length == 0) {
                revert IZoraCreator1155Errors.premintSignerContractNotAContract();
            }

            try IERC1271(premintSignerContract).isValidSignature(digest, signature) returns (bytes4 magicValue) {
                if (MAGIC_VALUE == magicValue) {
                    return premintSignerContract;
                }
                revert IZoraCreator1155Errors.InvalidSigner(magicValue);
            } catch {
                revert IZoraCreator1155Errors.premintSignerContractFailedToRecoverSigner();
            }
        } else {
            ECDSAUpgradeable.RecoverError recoverError;
            // if the smart contract signer is not set, then the signature must be from the signer of the message
            (signatory, recoverError) = ECDSAUpgradeable.tryRecover(digest, signature);

            if (recoverError != ECDSAUpgradeable.RecoverError.NoError) {
                revert IZoraCreator1155Errors.InvalidSignature();
            }
        }
    }

    /// Gets hash data to sign for a premint.
    /// @param erc1155Contract Contract address that signature is to be verified against
    /// @param chainId Chain id that signature is to be verified on
    function premintHashedTypeDataV4(bytes32 structHash, address erc1155Contract, bytes32 signatureVersion, uint256 chainId) internal pure returns (bytes32) {
        // build the struct hash to be signed
        // here we pass the chain id, allowing the message to be signed for another chain
        return _hashTypedDataV4(structHash, HASHED_NAME, signatureVersion, erc1155Contract, chainId);
    }

    bytes32 constant ATTRIBUTION_DOMAIN_V1 =
        keccak256(
            "CreatorAttribution(TokenCreationConfig tokenConfig,uint32 uid,uint32 version,bool deleted)TokenCreationConfig(string tokenURI,uint256 maxSupply,uint64 maxTokensPerAddress,uint96 pricePerToken,uint64 mintStart,uint64 mintDuration,uint32 royaltyMintSchedule,uint32 royaltyBPS,address royaltyRecipient,address fixedPriceMinter)"
        );

    function hashPremint(PremintConfig memory premintConfig) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ATTRIBUTION_DOMAIN_V1, _hashToken(premintConfig.tokenConfig), premintConfig.uid, premintConfig.version, premintConfig.deleted)
            );
    }

    bytes32 constant ATTRIBUTION_DOMAIN_V2 =
        keccak256(
            "CreatorAttribution(TokenCreationConfig tokenConfig,uint32 uid,uint32 version,bool deleted)TokenCreationConfig(string tokenURI,uint256 maxSupply,uint64 maxTokensPerAddress,uint96 pricePerToken,uint64 mintStart,uint64 mintDuration,uint32 royaltyBPS,address payoutRecipient,address fixedPriceMinter,address createReferral)"
        );

    function hashPremint(PremintConfigV2 memory premintConfig) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ATTRIBUTION_DOMAIN_V2, _hashToken(premintConfig.tokenConfig), premintConfig.uid, premintConfig.version, premintConfig.deleted)
            );
    }

    bytes32 constant ATTRIBUTION_DOMAIN_ERC20_V1 =
        keccak256(
            "CreatorAttribution(TokenCreationConfig tokenConfig,uint32 uid,uint32 version,bool deleted)TokenCreationConfig(string tokenURI,uint256 maxSupply,uint32 royaltyBPS,address payoutRecipient,address createReferral,address erc20Minter,uint64 mintStart,uint64 mintDuration,uint64 maxTokensPerAddress,address currency,uint256 pricePerToken)"
        );

    function hashPremint(Erc20PremintConfigV1 memory premintConfig) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ATTRIBUTION_DOMAIN_ERC20_V1, _hashToken(premintConfig.tokenConfig), premintConfig.uid, premintConfig.version, premintConfig.deleted)
            );
    }

    bytes32 constant TOKEN_DOMAIN_V1 =
        keccak256(
            "TokenCreationConfig(string tokenURI,uint256 maxSupply,uint64 maxTokensPerAddress,uint96 pricePerToken,uint64 mintStart,uint64 mintDuration,uint32 royaltyMintSchedule,uint32 royaltyBPS,address royaltyRecipient,address fixedPriceMinter)"
        );

    function _hashToken(TokenCreationConfig memory tokenConfig) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TOKEN_DOMAIN_V1,
                    _stringHash(tokenConfig.tokenURI),
                    tokenConfig.maxSupply,
                    tokenConfig.maxTokensPerAddress,
                    tokenConfig.pricePerToken,
                    tokenConfig.mintStart,
                    tokenConfig.mintDuration,
                    tokenConfig.royaltyMintSchedule,
                    tokenConfig.royaltyBPS,
                    tokenConfig.royaltyRecipient,
                    tokenConfig.fixedPriceMinter
                )
            );
    }

    bytes32 constant TOKEN_DOMAIN_V2 =
        keccak256(
            "TokenCreationConfig(string tokenURI,uint256 maxSupply,uint64 maxTokensPerAddress,uint96 pricePerToken,uint64 mintStart,uint64 mintDuration,uint32 royaltyBPS,address payoutRecipient,address fixedPriceMinter,address createReferral)"
        );

    function _hashToken(TokenCreationConfigV2 memory tokenConfig) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TOKEN_DOMAIN_V2,
                    _stringHash(tokenConfig.tokenURI),
                    tokenConfig.maxSupply,
                    tokenConfig.maxTokensPerAddress,
                    tokenConfig.pricePerToken,
                    tokenConfig.mintStart,
                    tokenConfig.mintDuration,
                    tokenConfig.royaltyBPS,
                    tokenConfig.payoutRecipient,
                    tokenConfig.fixedPriceMinter,
                    tokenConfig.createReferral
                )
            );
    }

    bytes32 constant TOKEN_DOMAIN_ERC20_V1 =
        keccak256(
            "TokenCreationConfig(string tokenURI,uint256 maxSupply,uint32 royaltyBPS,address payoutRecipient,address createReferral,address erc20Minter,uint64 mintStart,uint64 mintDuration,uint64 maxTokensPerAddress,address currency,uint256 pricePerToken)"
        );

    function _hashToken(Erc20TokenCreationConfigV1 memory tokenConfig) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TOKEN_DOMAIN_ERC20_V1,
                    _stringHash(tokenConfig.tokenURI),
                    tokenConfig.maxSupply,
                    tokenConfig.royaltyBPS,
                    tokenConfig.payoutRecipient,
                    tokenConfig.createReferral,
                    tokenConfig.erc20Minter,
                    tokenConfig.mintStart,
                    tokenConfig.mintDuration,
                    tokenConfig.maxTokensPerAddress,
                    tokenConfig.currency,
                    tokenConfig.pricePerToken
                )
            );
    }

    bytes32 internal constant TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function _stringHash(string memory value) private pure returns (bytes32) {
        return keccak256(bytes(value));
    }

    /// @notice copied from SharedBaseConstants
    uint256 constant CONTRACT_BASE_ID = 0;
    /// @dev copied from ZoraCreator1155Impl
    uint256 constant PERMISSION_BIT_MINTER = 2 ** 2;

    function isAuthorizedToCreatePremint(
        address signer,
        address premintContractConfigContractAdmin,
        address contractAddress
    ) internal view returns (bool authorized) {
        // if contract hasn't been created, signer must be the contract admin on the premint config
        if (contractAddress.code.length == 0) {
            return signer == premintContractConfigContractAdmin;
        } else {
            // if contract has been created, signer must have mint new token permission
            authorized = IZoraCreator1155(contractAddress).isAdminOrRole(signer, CONTRACT_BASE_ID, PERMISSION_BIT_MINTER);
        }
    }
}

/// @notice Utility library to setup tokens created via premint.  Functions exposed as external to not increase contract size in calling contract.
/// @author oveddan
library PremintTokenSetup {
    uint256 constant PERMISSION_BIT_MINTER = 2 ** 2;

    /// @notice Build token setup actions for a v3 preminted token
    function makeSetupNewTokenCalls(uint256 newTokenId, Erc20TokenCreationConfigV1 memory tokenConfig) internal view returns (bytes[] memory calls) {
        return
            _buildCalls({
                newTokenId: newTokenId,
                erc20MinterAddress: tokenConfig.erc20Minter,
                currency: tokenConfig.currency,
                pricePerToken: tokenConfig.pricePerToken,
                maxTokensPerAddress: tokenConfig.maxTokensPerAddress,
                mintDuration: tokenConfig.mintDuration,
                royaltyBPS: tokenConfig.royaltyBPS,
                payoutRecipient: tokenConfig.payoutRecipient
            });
    }

    /// @notice Build token setup actions for a v2 preminted token
    function makeSetupNewTokenCalls(uint256 newTokenId, TokenCreationConfigV2 memory tokenConfig) internal view returns (bytes[] memory calls) {
        return
            _buildCalls({
                newTokenId: newTokenId,
                fixedPriceMinterAddress: tokenConfig.fixedPriceMinter,
                pricePerToken: tokenConfig.pricePerToken,
                maxTokensPerAddress: tokenConfig.maxTokensPerAddress,
                mintDuration: tokenConfig.mintDuration,
                royaltyBPS: tokenConfig.royaltyBPS,
                payoutRecipient: tokenConfig.payoutRecipient
            });
    }

    /// @notice Build token setup actions for a v1 preminted token
    function makeSetupNewTokenCalls(uint256 newTokenId, TokenCreationConfig memory tokenConfig) internal view returns (bytes[] memory calls) {
        return
            _buildCalls({
                newTokenId: newTokenId,
                fixedPriceMinterAddress: tokenConfig.fixedPriceMinter,
                pricePerToken: tokenConfig.pricePerToken,
                maxTokensPerAddress: tokenConfig.maxTokensPerAddress,
                mintDuration: tokenConfig.mintDuration,
                royaltyBPS: tokenConfig.royaltyBPS,
                payoutRecipient: tokenConfig.royaltyRecipient
            });
    }

    function _buildCalls(
        uint256 newTokenId,
        address erc20MinterAddress,
        address currency,
        uint256 pricePerToken,
        uint64 maxTokensPerAddress,
        uint64 mintDuration,
        uint32 royaltyBPS,
        address payoutRecipient
    ) private view returns (bytes[] memory calls) {
        calls = new bytes[](3);

        calls[0] = abi.encodeWithSelector(IZoraCreator1155.addPermission.selector, newTokenId, erc20MinterAddress, PERMISSION_BIT_MINTER);

        calls[1] = abi.encodeWithSelector(
            IZoraCreator1155.callSale.selector,
            newTokenId,
            IMinter1155(erc20MinterAddress),
            abi.encodeWithSelector(
                IERC20Minter.setSale.selector,
                newTokenId,
                _buildNewERC20SalesConfig(currency, pricePerToken, maxTokensPerAddress, mintDuration, payoutRecipient)
            )
        );

        calls[2] = abi.encodeWithSelector(
            IZoraCreator1155.updateRoyaltiesForToken.selector,
            newTokenId,
            ICreatorRoyaltiesControl.RoyaltyConfiguration({royaltyBPS: royaltyBPS, royaltyRecipient: payoutRecipient, royaltyMintSchedule: 0})
        );
    }

    function _buildCalls(
        uint256 newTokenId,
        address fixedPriceMinterAddress,
        uint96 pricePerToken,
        uint64 maxTokensPerAddress,
        uint64 mintDuration,
        uint32 royaltyBPS,
        address payoutRecipient
    ) private view returns (bytes[] memory calls) {
        calls = new bytes[](3);

        // build array of the calls to make
        // get setup actions and invoke them
        // set up the sales strategy
        // first, grant the fixed price sale strategy minting capabilities on the token
        // tokenContract.addPermission(newTokenId, address(fixedPriceMinter), PERMISSION_BIT_MINTER);
        calls[0] = abi.encodeWithSelector(IZoraCreator1155.addPermission.selector, newTokenId, fixedPriceMinterAddress, PERMISSION_BIT_MINTER);

        // set the sales config on that token
        calls[1] = abi.encodeWithSelector(
            IZoraCreator1155.callSale.selector,
            newTokenId,
            IMinter1155(fixedPriceMinterAddress),
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                newTokenId,
                _buildNewSalesConfig(pricePerToken, maxTokensPerAddress, mintDuration, payoutRecipient)
            )
        );

        // set the royalty config on that token:
        calls[2] = abi.encodeWithSelector(
            IZoraCreator1155.updateRoyaltiesForToken.selector,
            newTokenId,
            ICreatorRoyaltiesControl.RoyaltyConfiguration({royaltyBPS: royaltyBPS, royaltyRecipient: payoutRecipient, royaltyMintSchedule: 0})
        );
    }

    function _buildNewERC20SalesConfig(
        address currency,
        uint256 pricePerToken,
        uint64 maxTokensPerAddress,
        uint64 duration,
        address payoutRecipient
    ) private view returns (ERC20Minter.SalesConfig memory) {
        uint64 saleStart = uint64(block.timestamp);
        uint64 saleEnd = duration == 0 ? type(uint64).max : saleStart + duration;

        return
            IERC20Minter.SalesConfig({
                saleStart: saleStart,
                saleEnd: saleEnd,
                maxTokensPerAddress: maxTokensPerAddress,
                pricePerToken: pricePerToken,
                fundsRecipient: payoutRecipient,
                currency: currency
            });
    }

    function _buildNewSalesConfig(
        uint96 pricePerToken,
        uint64 maxTokensPerAddress,
        uint64 duration,
        address payoutRecipient
    ) private view returns (ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory) {
        uint64 saleStart = uint64(block.timestamp);
        uint64 saleEnd = duration == 0 ? type(uint64).max : saleStart + duration;

        return
            ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                pricePerToken: pricePerToken,
                saleStart: saleStart,
                saleEnd: saleEnd,
                maxTokensPerAddress: maxTokensPerAddress,
                fundsRecipient: payoutRecipient
            });
    }
}

struct DecodedCreatorAttribution {
    bytes32 structHash;
    string domainName;
    string version;
    address creator;
    bytes signature;
}

struct DelegatedTokenSetup {
    DecodedCreatorAttribution attribution;
    uint32 uid;
    string tokenURI;
    uint256 maxSupply;
    address createReferral;
}

/// @notice Utility library to decode and recover delegated token setup data from a signature.
/// Function called by the erc1155 contract is marked external to reduce contract size in calling contract.
library DelegatedTokenCreation {
    /// @notice Decode and recover delegated token setup data from a signature. Works with multiple versions of
    /// a signature.  Takes an abi encoded premint config, version of the encoded premint config, and a signature,
    /// decodes the config, and recoveres the signer of the config.  Based on the premint config, builds
    /// setup actions for the token to be created.
    /// @param premintConfigEncoded The abi encoded premint config
    /// @param premintVersion The version of the premint config
    /// @param signature The signature of the premint config
    /// @param tokenContract The address of the token contract that the premint config is for
    /// @param newTokenId The id of the token to be created
    function decodeAndRecoverDelegatedTokenSetup(
        bytes memory premintConfigEncoded,
        bytes32 premintVersion,
        bytes calldata signature,
        address tokenContract,
        uint256 newTokenId,
        address premintSignerContract
    ) external view returns (DelegatedTokenSetup memory params, DecodedCreatorAttribution memory creatorAttribution, bytes[] memory tokenSetupActions) {
        // based on version of encoded premint config, decode corresponding premint config,
        // and then recover signer from the signature, and then build token setup actions based
        // on the decoded premint config.
        if (premintVersion == PremintEncoding.HASHED_VERSION_1) {
            PremintConfig memory premintConfig = abi.decode(premintConfigEncoded, (PremintConfig));

            creatorAttribution = recoverCreatorAttribution(
                PremintEncoding.VERSION_1,
                ZoraCreator1155Attribution.hashPremint(premintConfig),
                tokenContract,
                signature,
                premintSignerContract
            );

            (params, tokenSetupActions) = _recoverDelegatedTokenSetup(premintConfig, newTokenId);
        } else if (premintVersion == PremintEncoding.HASHED_VERSION_2) {
            PremintConfigV2 memory premintConfig = abi.decode(premintConfigEncoded, (PremintConfigV2));

            creatorAttribution = recoverCreatorAttribution(
                PremintEncoding.VERSION_2,
                ZoraCreator1155Attribution.hashPremint(premintConfig),
                tokenContract,
                signature,
                premintSignerContract
            );

            (params, tokenSetupActions) = _recoverDelegatedTokenSetup(premintConfig, newTokenId);
        } else if (premintVersion == PremintEncoding.HASHED_ERC20_VERSION_1) {
            Erc20PremintConfigV1 memory premintConfig = abi.decode(premintConfigEncoded, (Erc20PremintConfigV1));

            creatorAttribution = recoverCreatorAttribution(
                PremintEncoding.ERC20_VERSION_1,
                ZoraCreator1155Attribution.hashPremint(premintConfig),
                tokenContract,
                signature,
                premintSignerContract
            );

            (params, tokenSetupActions) = _recoverDelegatedTokenSetup(premintConfig, newTokenId);
        } else {
            revert IZoraCreator1155Errors.InvalidPremintVersion();
        }
    }

    function supportedPremintSignatureVersions() external pure returns (string[] memory versions) {
        return _supportedPremintSignatureVersions();
    }

    function _supportedPremintSignatureVersions() internal pure returns (string[] memory versions) {
        versions = new string[](3);
        versions[0] = PremintEncoding.VERSION_1;
        versions[1] = PremintEncoding.VERSION_2;
        versions[2] = PremintEncoding.ERC20_VERSION_1;
    }

    function recoverCreatorAttribution(
        string memory version,
        bytes32 structHash,
        address tokenContract,
        bytes calldata signature,
        address premintSignerContract
    ) internal view returns (DecodedCreatorAttribution memory attribution) {
        attribution.structHash = structHash;
        attribution.version = version;

        attribution.creator = ZoraCreator1155Attribution.recoverSignerHashed(
            structHash,
            signature,
            tokenContract,
            keccak256(bytes(version)),
            block.chainid,
            premintSignerContract
        );

        attribution.signature = signature;
        attribution.domainName = ZoraCreator1155Attribution.NAME;
    }

    function _recoverDelegatedTokenSetup(
        Erc20PremintConfigV1 memory premintConfig,
        uint256 nextTokenId
    ) private view returns (DelegatedTokenSetup memory params, bytes[] memory tokenSetupActions) {
        validatePremint(premintConfig.tokenConfig.mintStart, premintConfig.deleted);

        params.uid = premintConfig.uid;

        tokenSetupActions = PremintTokenSetup.makeSetupNewTokenCalls({newTokenId: nextTokenId, tokenConfig: premintConfig.tokenConfig});

        params.tokenURI = premintConfig.tokenConfig.tokenURI;
        params.maxSupply = premintConfig.tokenConfig.maxSupply;
        params.createReferral = premintConfig.tokenConfig.createReferral;
    }

    function _recoverDelegatedTokenSetup(
        PremintConfigV2 memory premintConfig,
        uint256 nextTokenId
    ) private view returns (DelegatedTokenSetup memory params, bytes[] memory tokenSetupActions) {
        validatePremint(premintConfig.tokenConfig.mintStart, premintConfig.deleted);

        params.uid = premintConfig.uid;

        tokenSetupActions = PremintTokenSetup.makeSetupNewTokenCalls({newTokenId: nextTokenId, tokenConfig: premintConfig.tokenConfig});

        params.tokenURI = premintConfig.tokenConfig.tokenURI;
        params.maxSupply = premintConfig.tokenConfig.maxSupply;
        params.createReferral = premintConfig.tokenConfig.createReferral;
    }

    function _recoverDelegatedTokenSetup(
        PremintConfig memory premintConfig,
        uint256 nextTokenId
    ) private view returns (DelegatedTokenSetup memory params, bytes[] memory tokenSetupActions) {
        validatePremint(premintConfig.tokenConfig.mintStart, premintConfig.deleted);

        params.uid = premintConfig.uid;

        tokenSetupActions = PremintTokenSetup.makeSetupNewTokenCalls(nextTokenId, premintConfig.tokenConfig);

        params.tokenURI = premintConfig.tokenConfig.tokenURI;
        params.maxSupply = premintConfig.tokenConfig.maxSupply;
    }

    function validatePremint(uint64 mintStart, bool deleted) private view {
        if (mintStart != 0 && mintStart > block.timestamp) {
            // if the mint start is in the future, then revert
            revert IZoraCreator1155Errors.MintNotYetStarted();
        }
        if (deleted) {
            // if the signature says to be deleted, then dont execute any further minting logic;
            // return 0
            revert IZoraCreator1155Errors.PremintDeleted();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ContractCreationConfig {
    // Creator/admin of the created contract.  Must match the account that signed the message
    address contractAdmin;
    // Metadata URI for the created contract
    string contractURI;
    // Name of the created contract
    string contractName;
}

struct PremintConfig {
    // The config for the token to be created
    TokenCreationConfig tokenConfig;
    // Unique id of the token, used to ensure that multiple signatures can't be used to create the same intended token.
    // only one signature per token id, scoped to the contract hash can be executed.
    uint32 uid;
    // Version of this premint, scoped to the uid and contract.  Not used for logic in the contract, but used externally to track the newest version
    uint32 version;
    // If executing this signature results in preventing any signature with this uid from being minted.
    bool deleted;
}

struct TokenCreationConfig {
    // Metadata URI for the created token
    string tokenURI;
    // Max supply of the created token
    uint256 maxSupply;
    // Max tokens that can be minted for an address, 0 if unlimited
    uint64 maxTokensPerAddress;
    // Price per token in eth wei. 0 for a free mint.
    uint96 pricePerToken;
    // The start time of the mint, 0 for immediate.  Prevents signatures from being used until the start time.
    uint64 mintStart;
    // The duration of the mint, starting from the first mint of this token. 0 for infinite
    uint64 mintDuration;
    // deperecated field; will be ignored.
    uint32 royaltyMintSchedule;
    // RoyaltyBPS for created tokens. The royalty amount in basis points for secondary sales.
    uint32 royaltyBPS;
    // This is the address that will be set on the `royaltyRecipient` for the created token on the 1155 contract,
    // which is the address that receives creator rewards and secondary royalties for the token,
    // and on the `fundsRecipient` on the ZoraCreatorFixedPriceSaleStrategy contract for the token,
    // which is the address that receives paid mint funds for the token.
    address royaltyRecipient;
    // Fixed price minter address
    address fixedPriceMinter;
}

struct PremintConfigV2 {
    // The config for the token to be created
    TokenCreationConfigV2 tokenConfig;
    // Unique id of the token, used to ensure that multiple signatures can't be used to create the same intended token.
    // only one signature per token id, scoped to the contract hash can be executed.
    uint32 uid;
    // Version of this premint, scoped to the uid and contract.  Not used for logic in the contract, but used externally to track the newest version
    uint32 version;
    // If executing this signature results in preventing any signature with this uid from being minted.
    bool deleted;
}

struct TokenCreationConfigV2 {
    // Metadata URI for the created token
    string tokenURI;
    // Max supply of the created token
    uint256 maxSupply;
    // Max tokens that can be minted for an address, 0 if unlimited
    uint64 maxTokensPerAddress;
    // Price per token in eth wei. 0 for a free mint.
    uint96 pricePerToken;
    // The start time of the mint, 0 for immediate.  Prevents signatures from being used until the start time.
    uint64 mintStart;
    // The duration of the mint, starting from the first mint of this token. 0 for infinite
    uint64 mintDuration;
    // RoyaltyBPS for created tokens. The royalty amount in basis points for secondary sales.
    uint32 royaltyBPS;
    // This is the address that will be set on the `royaltyRecipient` for the created token on the 1155 contract,
    // which is the address that receives creator rewards and secondary royalties for the token,
    // and on the `fundsRecipient` on the ZoraCreatorFixedPriceSaleStrategy contract for the token,
    // which is the address that receives paid mint funds for the token.
    address payoutRecipient;
    // Fixed price minter address
    address fixedPriceMinter;
    // create referral
    address createReferral;
}

struct Erc20PremintConfigV1 {
    // The config for the token to be created
    Erc20TokenCreationConfigV1 tokenConfig;
    // Unique id of the token, used to ensure that multiple signatures can't be used to create the same intended token.
    // only one signature per token id, scoped to the contract hash can be executed.
    uint32 uid;
    // Version of this premint, scoped to the uid and contract.  Not used for logic in the contract, but used externally to track the newest version
    uint32 version;
    // If executing this signature results in preventing any signature with this uid from being minted.
    bool deleted;
}

struct Erc20TokenCreationConfigV1 {
    // Metadata URI for the created token
    string tokenURI;
    // Max supply of the created token
    uint256 maxSupply;
    // RoyaltyBPS for created tokens. The royalty amount in basis points for secondary sales.
    uint32 royaltyBPS;
    // The address that the will receive rewards/funds/royalties.
    address payoutRecipient;
    // The address that referred the creation of the token.
    address createReferral;
    // The address of the ERC20 minter module.
    address erc20Minter;
    // The start time of the mint, 0 for immediate.
    uint64 mintStart;
    // The duration of the mint, starting from the first mint of this token. 0 for infinite
    uint64 mintDuration;
    // Max tokens that can be minted for an address, 0 if unlimited
    uint64 maxTokensPerAddress;
    // The ERC20 currency address
    address currency;
    // Price per token in ERC20 currency
    uint256 pricePerToken;
}

struct MintArguments {
    address mintRecipient;
    string mintComment;
    /// array of accounts to receive rewards - mintReferral is first argument, and platformReferral is second.  platformReferral isn't supported as of now but will be in a future release.
    address[] mintRewardsRecipients;
}

struct PremintResult {
    address contractAddress;
    uint256 tokenId;
    bool createdNewContract;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IZoraMints1155} from "../interfaces/IZoraMints1155.sol";

interface IZoraMintsMinterManager {
    /**
     * @dev Mints the currently mintable ETH-based token and sends it to the specified recipient.
     *      The total value sent must match the product of the currently mintable ETH token's price and the quantity to mint.
     * @param quantity The quantity of tokens to mint.
     * @param recipient The address to receive the minted tokens.
     * @return The ID of the token that was minted.
     */
    function mintWithEth(uint256 quantity, address recipient) external payable returns (uint256);

    /// @notice Retrieves the price in ETH of the currently mintable ETH-based token.
    function getEthPrice() external view returns (uint256);

    /// @notice Gets the token id of the current mintable ETH-based token.
    function mintableEthToken() external view returns (uint256);

    function zoraMints1155() external view returns (IZoraMints1155);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {TokenConfig, Redemption} from "../ZoraMintsTypes.sol";
import {IZoraMints1155Errors} from "./IZoraMints1155Errors.sol";
import {IUpdateableTokenURI} from "./IUpdateableTokenURI.sol";

/**
 * @title IZoraMints1155 interface
 * @dev The IZoraMints1155 interface defines an implementation of the ERC1155 standard with additional features:
 *
 * Accounts can mint new tokens by sending ETH to the contract based on the current mintable token's
 * price in ETH. The amount of ETH sent must match the total price for the quantity of tokens being minted.
 * The price of a token cannot be changed, ensuring that the value of each token is fixed.
 *
 * Accounts can also redeem tokens by burning them and receiving their equivalent value in ETH.
 * The amount of ETH received is based on the quantity of tokens burned and the price per token.
 *
 */
interface IZoraMints1155 is IZoraMints1155Errors, IERC1155 {
    /// @notice Event emitted when a mint token is created
    /// @param tokenId The ID of the token
    /// @param price The price of the token
    /// @param tokenAddress The address of the token
    event TokenCreated(uint256 indexed tokenId, uint256 indexed price, address indexed tokenAddress);

    /**
     * @dev Redeems the equivalent value of a specified quantity of tokens and sends it to the recipient.
     *      This function can only be called by the current owner of the tokens. It unwraps the value of the tokens,
     *      sends it to the recipient, and then burns the tokens.
     * @param tokenId The ID of the token to redeem.
     * @param quantity The quantity of tokens to redeem.
     * @param recipient The address to receive the unwrapped funds.
     */
    function redeem(uint tokenId, uint quantity, address recipient) external returns (Redemption memory);

    function redeemBatch(uint[] calldata tokenIds, uint[] calldata quantities, address recipient) external returns (Redemption[] memory redemptions);

    // only callable by mints manager
    function mintTokenWithEth(uint256 tokenId, uint256 quantity, address recipient, bytes memory data) external payable;

    // only callable by mints manager
    function mintTokenWithERC20(uint256 tokenId, address tokenAddress, uint quantity, address recipient, bytes memory data) external;

    function createToken(uint256 tokenId, TokenConfig calldata tokenConfig) external;

    /**
     * Gets if token with the specific id has been created
     * @param tokenId The ID of the token to check.
     */
    function tokenExists(uint tokenId) external view returns (bool);

    /// @notice Helper to get the user's total balance of mints
    /// @param user User to query for balances
    function balanceOfAccount(address user) external returns (uint256);

    /**
     * Gets the price of a token
     * @param tokenId The id of the token to check
     */
    function tokenPrice(uint tokenId) external view returns (uint);

    function getTokenConfig(uint256 tokeId) external returns (TokenConfig memory);

    function MINIMUM_ETH_PRICE() external view returns (uint256);

    function MINIMUM_ERC20_PRICE() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
pragma solidity ^0.8.17;

import {IMinter1155} from "@zoralabs/shared-contracts/interfaces/IMinter1155.sol";

/// @title IMintWithMints
/// @notice Interface intended to be implemented by a 1155 creator contract to be able to mint tokens using MINTs
interface IMintWithMints {
    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, and rewards arguments,
    /// while MINTs are redeemed to pay for the mint fee, instead of paying with ETH directly.
    /// The MINTs must have been transferred to be owned by this contract before calling this function.
    /// Value sent is used for paid mints, if this is a paid mint.
    /// @param mintTokenIds The MINT token IDs that are to be redeemed.
    /// @param quantities The quantities of each MINT token id to redeem.
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param rewardsRecipients The addresses of rewards arguments - rewardsRecipients[0] = mintReferral, rewardsRecipients[1] = platformReferral
    /// @param minterArguments The arguments to pass to the minter
    /// @return quantityMinted The total quantity of tokens minted
    function mintWithMints(
        uint256[] calldata mintTokenIds,
        uint256[] calldata quantities,
        IMinter1155 minter,
        uint256 tokenId,
        address[] memory rewardsRecipients,
        bytes calldata minterArguments
    ) external payable returns (uint256 quantityMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRedeemHandler} from "./interfaces/IRedeemHandler.sol";

struct TokenConfig {
    /// @dev Price for the token to purchase.
    uint256 price;
    /// @dev Assume 0 is ETH
    address tokenAddress;
    /// @dev if set, redemptions go through this contract
    // should be an IRedeemHandler interface
    address redeemHandler;
}

struct Redemption {
    address tokenAddress;
    uint256 valueRedeemed;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;


error ADDRESS_INSUFFICIENT_BALANCE();
error ADDRESS_UNABLE_TO_SEND_VALUE();
error ADDRESS_LOW_LEVEL_CALL_FAILED();
error ADDRESS_LOW_LEVEL_CALL_WITH_VALUE_FAILED();
error ADDRESS_INSUFFICIENT_BALANCE_FOR_CALL();
error ADDRESS_LOW_LEVEL_STATIC_CALL_FAILED();
error ADDRESS_CALL_TO_NON_CONTRACT();

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance > amount) {
            revert ADDRESS_INSUFFICIENT_BALANCE();
        }
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert ADDRESS_UNABLE_TO_SEND_VALUE();
        }
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
        return functionCallWithValue(target, data, 0);
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
        if (address(this).balance < value) {
            revert ADDRESS_INSUFFICIENT_BALANCE();
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (!isContract(target)) {
                    revert ADDRESS_CALL_TO_NON_CONTRACT();
                }
            }
            return returndata;
        } else {
            _revert(returndata);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata);
        }
    }

    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert ADDRESS_LOW_LEVEL_CALL_FAILED();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

error INITIALIZABLE_CONTRACT_ALREADY_INITIALIZED();
error INITIALIZABLE_CONTRACT_IS_NOT_INITIALIZING();
error INITIALIZABLE_CONTRACT_IS_INITIALIZING();

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        if ((!isTopLevelCall || _initialized != 0) && (AddressUpgradeable.isContract(address(this)) || _initialized != 1)) {
            revert INITIALIZABLE_CONTRACT_ALREADY_INITIALIZED();
        }
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        if (_initializing || _initialized >= version) {
            revert INITIALIZABLE_CONTRACT_ALREADY_INITIALIZED();
        }
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (!_initializing) {
            revert INITIALIZABLE_CONTRACT_IS_NOT_INITIALIZING();
        }
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        if (_initializing) {
            revert INITIALIZABLE_CONTRACT_IS_INITIALIZING();
        }
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

error ERC1967_NEW_IMPL_NOT_CONTRACT();
error ERC1967_UNSUPPORTED_PROXIABLEUUID();
error ERC1967_NEW_IMPL_NOT_UUPS();
error ERC1967_NEW_ADMIN_IS_ZERO_ADDRESS();
error ERC1967_NEW_BEACON_IS_NOT_CONTRACT();
error ERC1967_BEACON_IMPL_IS_NOT_CONTRACT();
error ADDRESS_DELEGATECALL_TO_NON_CONTRACT();

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!AddressUpgradeable.isContract(newImplementation)) {
            revert ERC1967_NEW_IMPL_NOT_CONTRACT();
        } 
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) {
                    revert ERC1967_UNSUPPORTED_PROXIABLEUUID();
                }
            } catch {
                revert ERC1967_NEW_IMPL_NOT_UUPS();
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967_NEW_ADMIN_IS_ZERO_ADDRESS();
        }
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (!AddressUpgradeable.isContract(newBeacon)) {
            revert ERC1967_NEW_BEACON_IS_NOT_CONTRACT();
        }
        if (!AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation())) {
            revert ERC1967_BEACON_IMPL_IS_NOT_CONTRACT();
        }
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        if (!AddressUpgradeable.isContract(target)) {
            revert ADDRESS_DELEGATECALL_TO_NON_CONTRACT();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewardsErrors {
    error CREATOR_FUNDS_RECIPIENT_NOT_SET();
    error INVALID_ADDRESS_ZERO();
    error INVALID_ETH_AMOUNT();
    error ONLY_CREATE_REFERRAL();
}

interface IRewardSplits is IRewardsErrors {
    struct RewardsSettings {
        uint256 creatorReward;
        uint256 createReferralReward;
        uint256 mintReferralReward;
        uint256 firstMinterReward;
        uint256 zoraReward;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,

 */

/// Imagine. Mint. Enjoy.
/// @notice Interface for types used across the ZoraCreator1155 contract
/// @author @iainnash / @tbtstl
interface IZoraCreator1155TypesV1 {
    /// @notice Used to store individual token data
    struct TokenData {
        string uri;
        uint256 maxSupply;
        uint256 totalMinted;
    }

    /// @notice Used to store contract-level configuration
    struct ContractConfig {
        address owner;
        uint96 __gap1;
        address payable fundsRecipient;
        uint96 __gap2;
        ITransferHookReceiver transferHook;
        uint96 __gap3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external returns (address);

    event OwnershipTransferred(address lastOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVersionedContract {
    function contractVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface ICreatorRoyaltyErrors {
    /// @notice Thrown when a user tries to have 100% supply royalties
    error InvalidMintSchedule();
}

interface ICreatorRoyaltiesControl is IERC2981 {
    /// @notice The RoyaltyConfiguration struct is used to store the royalty configuration for a given token.
    /// @param royaltyMintSchedule Every nth token will go to the royalty recipient.
    /// @param royaltyBPS The royalty amount in basis points for secondary sales.
    /// @param royaltyRecipient The address that will receive the royalty payments.
    struct RoyaltyConfiguration {
        uint32 royaltyMintSchedule;
        uint32 royaltyBPS;
        address royaltyRecipient;
    }

    /// @notice Event emitted when royalties are updated
    event UpdatedRoyalties(uint256 indexed tokenId, address indexed user, RoyaltyConfiguration configuration);

    /// @notice External data getter to get royalties for a token
    /// @param tokenId tokenId to get royalties configuration for
    function getRoyalties(uint256 tokenId) external view returns (RoyaltyConfiguration memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Imagine. Mint. Enjoy.
/// @author @iainnash / @tbtstl
contract CreatorPermissionStorageV1 {
    mapping(uint256 => mapping(address => uint256)) public permissions;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Generic control interface for bit-based permissions-control
interface ICreatorPermissionControl {
    /// @notice Emitted when permissions are updated
    event UpdatedPermissions(uint256 indexed tokenId, address indexed user, uint256 indexed permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorRendererControl} from "../interfaces/ICreatorRendererControl.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";

/// @notice Creator Renderer Storage Configuration Contract V1
abstract contract CreatorRendererStorageV1 is ICreatorRendererControl {
    /// @notice Mapping for custom renderers
    mapping(uint256 => IRenderer1155) public customRenderers;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";

/// Imagine. Mint. Enjoy.
/// @title CreatorRoyaltiesControl
/// @author ZORA @iainnash / @tbtstl
/// @notice Royalty storage contract pattern
abstract contract CreatorRoyaltiesStorageV1 is ICreatorRoyaltiesControl {
    mapping(uint256 => RoyaltyConfiguration) public royalties;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Creator Commands used by minter modules passed back to the main modules
interface ICreatorCommands {
    /// @notice This enum is used to define supported creator action types.
    /// This can change in the future
    enum CreatorActions {
        // No operation - also the default for mintings that may not return a command
        NO_OP,
        // Send ether
        SEND_ETH,
        // Mint operation
        MINT
    }

    /// @notice This command is for
    struct Command {
        // Method for operation
        CreatorActions method;
        // Arguments used for this operation
        bytes args;
    }

    /// @notice This command set is returned from the minter back to the user
    struct CommandSet {
        Command[] commands;
        uint256 at;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICreatorCommands} from "./ICreatorCommands.sol";
import {IERC165Upgradeable} from "./IERC165Upgradeable.sol";

/// @notice Minter standard interface
/// @dev Minters need to confirm to the ERC165 selector of type(IMinter1155).interfaceId
interface IMinter1155 is IERC165Upgradeable {
    function requestMint(
        address sender,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILegacyNaming {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LegacyNamingStorageV1 {
    string internal _name;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMinterErrors} from "./IMinterErrors.sol";

interface ILimitedMintPerAddressErrors {
    error UserExceedsMintLimit(address user, uint256 limit, uint256 requestedAmount);
}

interface ICreatorRoyaltyErrors {
    /// @notice Thrown when a user tries to have 100% supply royalties
    error InvalidMintSchedule();
}

interface IZoraCreator1155Errors is ICreatorRoyaltyErrors, ILimitedMintPerAddressErrors, IMinterErrors {
    error OnlyTransfersFromZoraMints();
    error Call_TokenIdMismatch();
    error TokenIdMismatch(uint256 expected, uint256 actual);
    error UserMissingRoleForToken(address user, uint256 tokenId, uint256 role);

    error Config_TransferHookNotSupported(address proposedAddress);

    error Mint_InsolventSaleTransfer();
    error Mint_ValueTransferFail();
    error Mint_TokenIDMintNotAllowed();
    error Mint_UnknownCommand();
    error Mint_InvalidMintArrayLength();

    error Burn_NotOwnerOrApproved(address operator, address user);

    error NewOwnerNeedsToBeAdmin();

    error Sale_CannotCallNonSalesContract(address targetContract);

    error CallFailed(bytes reason);
    error Renderer_NotValidRendererContract();

    error ETHWithdrawFailed(address recipient, uint256 amount);
    error FundsWithdrawInsolvent(uint256 amount, uint256 contractValue);
    error ProtocolRewardsWithdrawFailed(address caller, address recipient, uint256 amount);

    error CannotMintMoreTokens(uint256 tokenId, uint256 quantity, uint256 totalMinted, uint256 maxSupply);

    error MintNotYetStarted();
    error PremintDeleted();

    // DelegatedMinting related errors
    error InvalidSignatureVersion();
    error premintSignerContractNotAContract();
    error InvalidSignature();
    error InvalidSigner(bytes4 magicValue);
    error premintSignerContractFailedToRecoverSigner();
    error FirstMinterAddressZero();

    error ERC1155_MINT_TO_ZERO_ADDRESS();

    error InvalidPremintVersion();
    error NonEthRedemption();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Enjoy} from "_imagine/mint/Enjoy.sol";
import {IMinter1155} from "../../interfaces/IMinter1155.sol";
import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";
import {SaleStrategy} from "../SaleStrategy.sol";
import {SaleCommandHelper} from "../utils/SaleCommandHelper.sol";
import {LimitedMintPerAddress} from "../utils/LimitedMintPerAddress.sol";
import {IMinterErrors} from "../../interfaces/IMinterErrors.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-1155-contracts

*/

/// @title ZoraCreatorFixedPriceSaleStrategy
/// @notice A sale strategy for ZoraCreator that allows for fixed price sales over a given time period
/// @author @iainnash / @tbtstl
contract ZoraCreatorFixedPriceSaleStrategy is Enjoy, SaleStrategy, LimitedMintPerAddress, IMinterErrors {
    struct SalesConfig {
        /// @notice Unix timestamp for the sale start
        uint64 saleStart;
        /// @notice Unix timestamp for the sale end
        uint64 saleEnd;
        /// @notice Max tokens that can be minted for an address, 0 if unlimited
        uint64 maxTokensPerAddress;
        /// @notice Price per token in eth wei
        uint96 pricePerToken;
        /// @notice Funds recipient (0 if no different funds recipient than the contract global)
        address fundsRecipient;
    }

    // target -> tokenId -> settings
    mapping(address => mapping(uint256 => SalesConfig)) internal salesConfigs;

    using SaleCommandHelper for ICreatorCommands.CommandSet;

    function contractURI() external pure override returns (string memory) {
        return "https://github.com/ourzora/zora-1155-contracts/";
    }

    /// @notice The name of the sale strategy
    function contractName() external pure override returns (string memory) {
        return "Fixed Price Sale Strategy";
    }

    /// @notice The version of the sale strategy
    function contractVersion() external pure override returns (string memory) {
        return "1.1.0";
    }

    event SaleSet(address indexed mediaContract, uint256 indexed tokenId, SalesConfig salesConfig);
    event MintComment(address indexed sender, address indexed tokenContract, uint256 indexed tokenId, uint256 quantity, string comment);

    /// @notice Compiles and returns the commands needed to mint a token using this sales strategy
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param ethValueSent The amount of ETH sent with the transaction
    /// @param minterArguments The arguments passed to the minter, which should be the address to mint to
    function requestMint(
        address,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands) {
        address mintTo;
        string memory comment = "";
        if (minterArguments.length == 32) {
            mintTo = abi.decode(minterArguments, (address));
        } else {
            (mintTo, comment) = abi.decode(minterArguments, (address, string));
        }

        SalesConfig storage config = salesConfigs[msg.sender][tokenId];

        // If sales config does not exist this first check will always fail.

        // Check sale end
        if (block.timestamp > config.saleEnd) {
            revert SaleEnded();
        }

        // Check sale start
        if (block.timestamp < config.saleStart) {
            revert SaleHasNotStarted();
        }

        // Check value sent
        if (config.pricePerToken * quantity != ethValueSent) {
            revert WrongValueSent();
        }

        // Check minted per address limit
        if (config.maxTokensPerAddress > 0) {
            _requireMintNotOverLimitAndUpdate(config.maxTokensPerAddress, quantity, msg.sender, tokenId, mintTo);
        }

        bool shouldTransferFunds = config.fundsRecipient != address(0);
        commands.setSize(shouldTransferFunds ? 2 : 1);

        // Mint command
        commands.mint(mintTo, tokenId, quantity);

        if (bytes(comment).length > 0) {
            emit MintComment(mintTo, msg.sender, tokenId, quantity, comment);
        }

        // Should transfer funds if funds recipient is set to a non-default address
        if (shouldTransferFunds) {
            commands.transfer(config.fundsRecipient, ethValueSent);
        }
    }

    /// @notice Sets the sale config for a given token
    function setSale(uint256 tokenId, SalesConfig memory salesConfig) external {
        salesConfigs[msg.sender][tokenId] = salesConfig;

        // Emit event
        emit SaleSet(msg.sender, tokenId, salesConfig);
    }

    /// @notice Deletes the sale config for a given token
    function resetSale(uint256 tokenId) external override {
        delete salesConfigs[msg.sender][tokenId];

        // Deleted sale emit event
        emit SaleSet(msg.sender, tokenId, salesConfigs[msg.sender][tokenId]);
    }

    /// @notice Returns the sale config for a given token
    function sale(address tokenContract, uint256 tokenId) external view returns (SalesConfig memory) {
        return salesConfigs[tokenContract][tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(LimitedMintPerAddress, SaleStrategy) returns (bool) {
        return super.supportsInterface(interfaceId) || LimitedMintPerAddress.supportsInterface(interfaceId) || SaleStrategy.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PremintConfig, PremintConfigV2, Erc20PremintConfigV1} from "../entities/Premint.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";

struct EncodedPremintConfig {
    bytes premintConfig;
    bytes32 premintConfigVersion;
    uint32 uid;
    address minter;
}

library PremintEncoding {
    string internal constant VERSION_1 = "1";
    bytes32 internal constant HASHED_VERSION_1 = keccak256(bytes(VERSION_1));
    string internal constant VERSION_2 = "2";
    bytes32 internal constant HASHED_VERSION_2 = keccak256(bytes(VERSION_2));
    string internal constant ERC20_VERSION_1 = "ERC20_1";
    bytes32 internal constant HASHED_ERC20_VERSION_1 = keccak256(bytes(ERC20_VERSION_1));

    function encodePremintV1(PremintConfig memory premintConfig) internal pure returns (EncodedPremintConfig memory) {
        return EncodedPremintConfig(abi.encode(premintConfig), HASHED_VERSION_1, premintConfig.uid, premintConfig.tokenConfig.fixedPriceMinter);
    }

    function encodePremintV2(PremintConfigV2 memory premintConfig) internal pure returns (EncodedPremintConfig memory) {
        return EncodedPremintConfig(abi.encode(premintConfig), HASHED_VERSION_2, premintConfig.uid, premintConfig.tokenConfig.fixedPriceMinter);
    }

    function encodePremintErc20V1(Erc20PremintConfigV1 memory premintConfig) internal pure returns (EncodedPremintConfig memory)  {
        return EncodedPremintConfig(abi.encode(premintConfig), HASHED_ERC20_VERSION_1, premintConfig.uid, premintConfig.tokenConfig.erc20Minter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IProtocolRewards} from "@zoralabs/protocol-rewards/src/interfaces/IProtocolRewards.sol";
import {IERC20Minter} from "../../interfaces/IERC20Minter.sol";
import {LimitedMintPerAddress} from "../../minters/utils/LimitedMintPerAddress.sol";
import {SaleStrategy} from "../../minters/SaleStrategy.sol";
import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";
import {ERC20MinterRewards} from "./ERC20MinterRewards.sol";
import {IZora1155} from "./IZora1155.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-protocol

*/

/// @title ERC20Minter
/// @notice Allows for ZoraCreator Mints to be purchased using ERC20 tokens
/// @dev While this contract _looks_ like a minter, we need to be able to directly manage ERC20 tokens. Therefore, we need to establish minter permissions but instead of using the `requestMint` flow we directly request tokens to be minted in order to safely handle the incoming ERC20 tokens.
/// @author @isabellasmallcombe
contract ERC20Minter is ReentrancyGuard, IERC20Minter, SaleStrategy, LimitedMintPerAddress, ERC20MinterRewards {
    using SafeERC20 for IERC20;

    /// @notice The address of the Zora rewards recipient
    address public zoraRewardRecipientAddress;

    /// @notice The ERC20 sale configuration for a given 1155 token
    /// @dev 1155 token address => 1155 token id => SalesConfig
    mapping(address => mapping(uint256 => SalesConfig)) internal salesConfigs;

    /// @notice Initializes the contract with a Zora rewards recipient address
    /// @dev Allows deterministic contract address, called on deploy
    function initialize(address _zoraRewardRecipientAddress) external {
        if (_zoraRewardRecipientAddress == address(0)) {
            revert AddressZero();
        }

        if (zoraRewardRecipientAddress != address(0)) {
            revert AlreadyInitialized();
        }

        zoraRewardRecipientAddress = _zoraRewardRecipientAddress;

        emit ERC20MinterInitialized(TOTAL_REWARD_PCT);
    }

    /// @notice Computes the total reward value for a given amount of ERC20 tokens
    /// @param totalValue The total number of ERC20 tokens
    function computeTotalReward(uint256 totalValue) public pure returns (uint256) {
        return (totalValue * TOTAL_REWARD_PCT) / BPS_TO_PERCENT_2_DECIMAL_PERCISION;
    }

    /// @notice Computes the rewards value given an amount and a reward percentage
    /// @param totalReward The total reward to be distributed
    /// @param rewardPct The percentage of the reward to be distributed
    function computeReward(uint256 totalReward, uint256 rewardPct) public pure returns (uint256) {
        return (totalReward * rewardPct) / BPS_TO_PERCENT_8_DECIMAL_PERCISION;
    }

    /// @notice Computes the rewards for an ERC20 mint
    /// @param totalReward The total reward to be distributed
    function computePaidMintRewards(uint256 totalReward) public pure returns (RewardsSettings memory) {
        uint256 createReferralReward = computeReward(totalReward, CREATE_REFERRAL_PAID_MINT_REWARD_PCT);
        uint256 mintReferralReward = computeReward(totalReward, MINT_REFERRAL_PAID_MINT_REWARD_PCT);
        uint256 firstMinterReward = computeReward(totalReward, FIRST_MINTER_REWARD_PCT);
        uint256 zoraReward = totalReward - (createReferralReward + mintReferralReward + firstMinterReward);

        return
            RewardsSettings({
                createReferralReward: createReferralReward,
                mintReferralReward: mintReferralReward,
                zoraReward: zoraReward,
                firstMinterReward: firstMinterReward
            });
    }

    /// @notice Gets the create referral address for a given token
    /// @param tokenContract The address of the token contract
    /// @param tokenId The ID of the token
    function getCreateReferral(address tokenContract, uint256 tokenId) public view returns (address createReferral) {
        try IZora1155(tokenContract).createReferrals(tokenId) returns (address contractCreateReferral) {
            createReferral = contractCreateReferral;
        } catch {}

        if (createReferral == address(0)) {
            createReferral = zoraRewardRecipientAddress;
        }
    }

    /// @notice Gets the first minter address for a given token
    /// @param tokenContract The address of the token contract
    /// @param tokenId The ID of the token
    function getFirstMinter(address tokenContract, uint256 tokenId) public view returns (address firstMinter) {
        try IZora1155(tokenContract).firstMinters(tokenId) returns (address contractFirstMinter) {
            firstMinter = contractFirstMinter;

            if (firstMinter == address(0)) {
                firstMinter = IZora1155(tokenContract).getCreatorRewardRecipient(tokenId);
            }
        } catch {
            firstMinter = zoraRewardRecipientAddress;
        }
    }

    /// @notice Handles the incoming transfer of ERC20 tokens
    /// @param currency The address of the currency to use for the mint
    /// @param totalValue The total value of the mint
    function _handleIncomingTransfer(address currency, uint256 totalValue) internal {
        uint256 beforeBalance = IERC20(currency).balanceOf(address(this));
        IERC20(currency).safeTransferFrom(msg.sender, address(this), totalValue);
        uint256 afterBalance = IERC20(currency).balanceOf(address(this));

        if ((beforeBalance + totalValue) != afterBalance) {
            revert ERC20TransferSlippage();
        }
    }

    /// @notice Distributes the rewards to the appropriate addresses
    /// @param totalReward The total reward to be distributed
    /// @param currency The currency used for the mint
    /// @param tokenId The ID of the token to mint
    /// @param tokenAddress The address of the token to mint
    /// @param mintReferral The address of the mint referral
    function _distributeRewards(uint256 totalReward, address currency, uint256 tokenId, address tokenAddress, address mintReferral) private {
        RewardsSettings memory settings = computePaidMintRewards(totalReward);

        address createReferral = getCreateReferral(tokenAddress, tokenId);
        address firstMinter = getFirstMinter(tokenAddress, tokenId);

        if (mintReferral == address(0)) {
            mintReferral = zoraRewardRecipientAddress;
        }

        IERC20(currency).safeTransfer(createReferral, settings.createReferralReward);
        IERC20(currency).safeTransfer(firstMinter, settings.firstMinterReward);
        IERC20(currency).safeTransfer(mintReferral, settings.mintReferralReward);
        IERC20(currency).safeTransfer(zoraRewardRecipientAddress, settings.zoraReward);

        emit ERC20RewardsDeposit(
            createReferral,
            mintReferral,
            firstMinter,
            zoraRewardRecipientAddress,
            tokenAddress,
            currency,
            tokenId,
            settings.createReferralReward,
            settings.mintReferralReward,
            settings.firstMinterReward,
            settings.zoraReward
        );
    }

    /// @notice Mints a token using an ERC20 currency, note the total value must have been approved prior to calling this function
    /// @param mintTo The address to mint the token to
    /// @param quantity The quantity of tokens to mint
    /// @param tokenAddress The address of the token to mint
    /// @param tokenId The ID of the token to mint
    /// @param totalValue The total value of the mint
    /// @param currency The address of the currency to use for the mint
    /// @param mintReferral The address of the mint referral
    /// @param comment The optional mint comment
    function mint(
        address mintTo,
        uint256 quantity,
        address tokenAddress,
        uint256 tokenId,
        uint256 totalValue,
        address currency,
        address mintReferral,
        string calldata comment
    ) external nonReentrant {
        SalesConfig storage config = salesConfigs[tokenAddress][tokenId];

        if (config.currency == address(0) || config.currency != currency) {
            revert InvalidCurrency();
        }

        if (totalValue != (config.pricePerToken * quantity)) {
            revert WrongValueSent();
        }

        if (block.timestamp < config.saleStart) {
            revert SaleHasNotStarted();
        }

        if (block.timestamp > config.saleEnd) {
            revert SaleEnded();
        }

        if (config.maxTokensPerAddress > 0) {
            _requireMintNotOverLimitAndUpdate(config.maxTokensPerAddress, quantity, tokenAddress, tokenId, mintTo);
        }

        _handleIncomingTransfer(currency, totalValue);

        IZora1155(tokenAddress).adminMint(mintTo, tokenId, quantity, "");

        uint256 totalReward = computeTotalReward(totalValue);

        _distributeRewards(totalReward, currency, tokenId, tokenAddress, mintReferral);

        IERC20(config.currency).safeTransfer(config.fundsRecipient, totalValue - totalReward);

        if (bytes(comment).length > 0) {
            emit MintComment(mintTo, tokenAddress, tokenId, quantity, comment);
        }
    }

    /// @notice The percentage of the total value that is distributed as rewards
    function totalRewardPct() external pure returns (uint256) {
        return TOTAL_REWARD_PCT;
    }

    /// @notice The URI of the contract
    function contractURI() external pure returns (string memory) {
        return "https://github.com/ourzora/zora-protocol/";
    }

    /// @notice The name of the contract
    function contractName() external pure returns (string memory) {
        return "ERC20 Minter";
    }

    /// @notice The version of the contract
    function contractVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Sets the sale config for a given token
    function setSale(uint256 tokenId, SalesConfig memory salesConfig) external {
        if (salesConfig.pricePerToken < MIN_PRICE_PER_TOKEN) {
            revert PricePerTokenTooLow();
        }
        if (salesConfig.currency == address(0)) {
            revert AddressZero();
        }
        if (salesConfig.fundsRecipient == address(0)) {
            revert AddressZero();
        }

        salesConfigs[msg.sender][tokenId] = salesConfig;

        // Emit event
        emit SaleSet(msg.sender, tokenId, salesConfig);
    }

    /// @notice Deletes the sale config for a given token
    function resetSale(uint256 tokenId) external override {
        delete salesConfigs[msg.sender][tokenId];

        // Deleted sale emit event
        emit SaleSet(msg.sender, tokenId, salesConfigs[msg.sender][tokenId]);
    }

    /// @notice Returns the sale config for a given token
    function sale(address tokenContract, uint256 tokenId) external view returns (SalesConfig memory) {
        return salesConfigs[tokenContract][tokenId];
    }

    /// @notice IERC165 interface support
    function supportsInterface(bytes4 interfaceId) public pure virtual override(LimitedMintPerAddress, SaleStrategy) returns (bool) {
        return super.supportsInterface(interfaceId) || LimitedMintPerAddress.supportsInterface(interfaceId) || SaleStrategy.supportsInterface(interfaceId);
    }

    /// @notice Reverts as `requestMint` is not used in the ERC20 minter. Call `mint` instead.
    function requestMint(address, uint256, uint256, uint256, bytes calldata) external pure returns (ICreatorCommands.CommandSet memory) {
        revert RequestMintInvalidUseMint();
    }

    /// @notice Set the Zora rewards recipient address
    /// @param recipient The new recipient address
    function setZoraRewardsRecipient(address recipient) external {
        if (msg.sender != zoraRewardRecipientAddress) {
            revert OnlyZoraRewardsRecipient();
        }

        if (recipient == address(0)) {
            revert AddressZero();
        }

        emit ZoraRewardsRecipientSet(zoraRewardRecipientAddress, recipient);

        zoraRewardRecipientAddress = recipient;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1271 {
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IZoraMints1155Errors {
    /**
     * @dev No URI allowed for nonexistent token
     */
    error NoUriForNonexistentToken();

    /**
     * @dev Occurs when the amount of ETH sent to mint tokens does not match the required amount.
     * The required amount is the product of the quantity of tokens to mint and the price per token.
     */
    error IncorrectAmountSent();

    /**
     * @dev Occurs when an attempt is made to create a token with a token ID that has already been used.
     * Each token ID should be unique and can only be used once.
     */
    error TokenAlreadyCreated();

    /**
     * @dev Occurs when an operation is attempted on a token that does not exist.
     * This can occur when trying to set a non-existent token as mintable, or when trying to redeem a non-existent token.
     */
    error TokenDoesNotExist();

    /**
     * @dev Occurs when a transfer of ETH fails.
     * This can occur when trying to send the unwrapped value of redeemed tokens to a recipient.
     */
    error ETHTransferFailed();

    /**
     * @dev Occurs when an attempt is made to set the price of a token to 0.
     */
    error InvalidTokenPrice();

    /**
     * @dev Occurs when redeem or redeemBatch is called with an invalid recipient.
     */
    error InvalidRecipient();

    /**
     * @dev Occurs when the token address does not match the expected token address.
     */
    error TokenMismatch(address storedTokenAddress, address expectedTokenAddress);

    /**
     * @dev Occurs when an attempt is made to mint a token that is not mintable.
     */
    error TokenNotMintable();

    /**
     * @dev Occurs when the length of the two arrays do not match.
     */
    error ArrayLengthMismatch(uint256 lengthA, uint256 lengthB);

    /**
     * @dev Occurs when the price of an ERC20 Token is not the same as the expected price.
     */
    error ERC20TransferSlippage();

    /**
     * @dev Occurs when the address is not a redeem handler
     */
    error NotARedeemHandler(address handler);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUpdateableTokenURI {
    /**
     * @dev Emitted when the contract URI and base URI are updated.
     */
    event URIsUpdated(string contractURI, string baseURI);

    function notifyURIsUpdated(string calldata contractURI, string calldata baseURI) external;
    function notifyUpdatedTokenURI(string calldata uri, uint256 tokenId) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRedeemHandler is IERC165 {
    function handleRedeemEth(address redeemer, uint tokenId, uint quantity, address recipient) external payable;

    function handleRedeemErc20(uint256 valueToRedeem, address redeemer, uint tokenId, uint quantity, address recipient) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IRenderer1155} from "./IRenderer1155.sol";

/// @notice Interface for creator renderer controls
interface ICreatorRendererControl {
    /// @notice Get the custom renderer contract (if any) for the given token id
    /// @dev Reverts if not custom renderer is set for this token
    function getCustomRenderer(uint256 tokenId) external view returns (IRenderer1155 renderer);

    error NoRendererForToken(uint256 tokenId);
    error RendererNotValid(address renderer);
    event RendererUpdated(uint256 indexed tokenId, address indexed renderer, address indexed user);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinterErrors {
    error CallerNotZoraCreator1155();
    error MinterContractAlreadyExists();
    error MinterContractDoesNotExist();

    error SaleEnded();
    error SaleHasNotStarted();
    error WrongValueSent();
    error InvalidMerkleProof(address mintTo, bytes32[] merkleProof, bytes32 merkleRoot);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*





             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,











 */

interface Enjoy {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IContractMetadata} from "../interfaces/IContractMetadata.sol";
import {IVersionedContract} from "@zoralabs/shared-contracts/interfaces/IVersionedContract.sol";

/// @notice Sales Strategy Helper contract template on top of IMinter1155
/// @author @iainnash / @tbtstl
abstract contract SaleStrategy is IMinter1155, IVersionedContract, IContractMetadata {
    /// @notice This function resets the sales configuration for a given tokenId and contract.
    /// @dev This function is intentioned to be called directly from the affected sales contract
    function resetSale(uint256 tokenId) external virtual;

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IMinter1155).interfaceId || interfaceId == type(IERC165Upgradeable).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorCommands} from "../../interfaces/ICreatorCommands.sol";

/// @title SaleCommandHelper
/// @notice Helper library for creating commands for the sale contract
/// @author @iainnash / @tbtstl
library SaleCommandHelper {
    /// @notice Sets the size of commands and initializes command array. Empty entries are skipped by the resolver.
    /// @dev Beware: this removes all previous command entries from memory
    /// @param commandSet command set struct storage.
    /// @param size size to set for the new struct
    function setSize(ICreatorCommands.CommandSet memory commandSet, uint256 size) internal pure {
        commandSet.commands = new ICreatorCommands.Command[](size);
    }

    /// @notice Creates a command to mint a token
    /// @param commandSet The command set to add the command to
    /// @param to The address to mint to
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    function mint(ICreatorCommands.CommandSet memory commandSet, address to, uint256 tokenId, uint256 quantity) internal pure {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({
                method: ICreatorCommands.CreatorActions.MINT,
                args: abi.encode(to, tokenId, quantity)
            });
        }
    }

    /// @notice Creates a command to transfer ETH
    /// @param commandSet The command set to add the command to
    /// @param to The address to transfer to
    /// @param amount The amount of ETH to transfer
    function transfer(ICreatorCommands.CommandSet memory commandSet, address to, uint256 amount) internal pure {
        unchecked {
            commandSet.commands[commandSet.at++] = ICreatorCommands.Command({method: ICreatorCommands.CreatorActions.SEND_ETH, args: abi.encode(to, amount)});
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILimitedMintPerAddress} from "../../interfaces/ILimitedMintPerAddress.sol";

contract LimitedMintPerAddress is ILimitedMintPerAddress {
    /// @notice Storage for slot to check user mints
    /// @notice target contract -> tokenId -> minter user -> numberMinted
    /// @dev No gap or stroage interface since this is used within non-upgradeable contracts
    mapping(address => mapping(uint256 => mapping(address => uint256))) internal mintedPerAddress;

    function getMintedPerWallet(address tokenContract, uint256 tokenId, address wallet) external view returns (uint256) {
        return mintedPerAddress[tokenContract][tokenId][wallet];
    }

    function _requireMintNotOverLimitAndUpdate(uint256 limit, uint256 numRequestedMint, address tokenContract, uint256 tokenId, address wallet) internal {
        mintedPerAddress[tokenContract][tokenId][wallet] += numRequestedMint;
        if (mintedPerAddress[tokenContract][tokenId][wallet] > limit) {
            revert UserExceedsMintLimit(wallet, limit, mintedPerAddress[tokenContract][tokenId][wallet]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(ILimitedMintPerAddress).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMinterErrors} from "@zoralabs/shared-contracts/interfaces/errors/IMinterErrors.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20Minter {
    struct RewardsSettings {
        /// @notice Amount of the create referral reward
        uint256 createReferralReward;
        /// @notice Amount of the mint referral reward
        uint256 mintReferralReward;
        /// @notice Amount of the zora reward
        uint256 zoraReward;
        /// @notice Amount of the first minter reward
        uint256 firstMinterReward;
    }

    struct SalesConfig {
        /// @notice Unix timestamp for the sale start
        uint64 saleStart;
        /// @notice Unix timestamp for the sale end
        uint64 saleEnd;
        /// @notice Max tokens that can be minted for an address, 0 if unlimited
        uint64 maxTokensPerAddress;
        /// @notice Price per token in ERC20 currency
        uint256 pricePerToken;
        /// @notice Funds recipient (0 if no different funds recipient than the contract global)
        address fundsRecipient;
        /// @notice ERC20 Currency address
        address currency;
    }

    /// @notice Rewards Deposit Event
    /// @param createReferral Creator referral address
    /// @param mintReferral Mint referral address
    /// @param firstMinter First minter address
    /// @param zora ZORA recipient address
    /// @param collection The collection address of the token
    /// @param currency Currency used for the deposit
    /// @param tokenId Token ID
    /// @param createReferralReward Creator referral reward
    /// @param mintReferralReward Mint referral amount
    /// @param firstMinterReward First minter amount
    /// @param zoraReward ZORA amount
    event ERC20RewardsDeposit(
        address indexed createReferral,
        address indexed mintReferral,
        address indexed firstMinter,
        address zora,
        address collection,
        address currency,
        uint256 tokenId,
        uint256 createReferralReward,
        uint256 mintReferralReward,
        uint256 firstMinterReward,
        uint256 zoraReward
    );

    /// @notice ERC20MinterInitialized Event
    /// @param rewardPercentage The reward percentage
    event ERC20MinterInitialized(uint256 rewardPercentage);

    /// @notice MintComment Event
    /// @param sender The sender of the comment
    /// @param tokenContract The token contract address
    /// @param tokenId The token ID
    /// @param quantity The quantity of tokens minted
    /// @param comment The comment
    event MintComment(address indexed sender, address indexed tokenContract, uint256 indexed tokenId, uint256 quantity, string comment);

    /// @notice SaleSet Event
    /// @param mediaContract The media contract address
    /// @param tokenId The token ID
    /// @param salesConfig The sales configuration
    event SaleSet(address indexed mediaContract, uint256 indexed tokenId, SalesConfig salesConfig);

    /// @notice ZoraRewardsRecipientSet Event
    /// @param prevRecipient The previous recipient address
    /// @param newRecipient The new recipient address
    event ZoraRewardsRecipientSet(address indexed prevRecipient, address indexed newRecipient);

    /// @notice Cannot set address to zero
    error AddressZero();

    /// @notice Cannot set currency address to zero
    error InvalidCurrency();

    /// @notice Price per ERC20 token is too low
    error PricePerTokenTooLow();

    /// @notice requestMint() is not used in ERC20 minter, use mint() instead
    error RequestMintInvalidUseMint();

    /// @notice Sale has already ended
    error SaleEnded();

    /// @notice Sale has not started yet
    error SaleHasNotStarted();

    /// @notice Value sent is incorrect
    error WrongValueSent();

    /// @notice ERC20 transfer slippage
    error ERC20TransferSlippage();

    /// @notice ERC20Minter is already initialized
    error AlreadyInitialized();

    /// @notice Only the Zora rewards recipient can call this function
    error OnlyZoraRewardsRecipient();

    /// @notice Mints a token using an ERC20 currency, note the total value must have been approved prior to calling this function
    /// @param mintTo The address to mint the token to
    /// @param quantity The quantity of tokens to mint
    /// @param tokenAddress The address of the token to mint
    /// @param tokenId The ID of the token to mint
    /// @param totalValue The total value of the mint
    /// @param currency The address of the currency to use for the mint
    /// @param mintReferral The address of the mint referral
    /// @param comment The optional mint comment
    function mint(
        address mintTo,
        uint256 quantity,
        address tokenAddress,
        uint256 tokenId,
        uint256 totalValue,
        address currency,
        address mintReferral,
        string calldata comment
    ) external;

    /// @notice Sets the sale config for a given token
    function setSale(uint256 tokenId, SalesConfig memory salesConfig) external;

    /// @notice Returns the sale config for a given token
    function sale(address tokenContract, uint256 tokenId) external view returns (SalesConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice ERC20Minter Helper contract template
abstract contract ERC20MinterRewards {
    uint256 internal constant MIN_PRICE_PER_TOKEN = 10_000;
    uint256 internal constant TOTAL_REWARD_PCT = 5; // 5%
    uint256 internal constant BPS_TO_PERCENT_2_DECIMAL_PERCISION = 100;
    uint256 internal constant BPS_TO_PERCENT_8_DECIMAL_PERCISION = 100_000_000;
    uint256 internal constant CREATE_REFERRAL_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value
    uint256 internal constant MINT_REFERRAL_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value
    uint256 internal constant ZORA_PAID_MINT_REWARD_PCT = 28_571400; // 28.5714%, roughly 0.000222 ETH at a 0.000777 value
    uint256 internal constant FIRST_MINTER_REWARD_PCT = 14_228500; // 14.2285%, roughly 0.000111 ETH at a 0.000777 value
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice The set of public functions on a Zora 1155 contract that are called by the ERC20 minter contract
interface IZora1155 {
    function createReferrals(uint256 tokenId) external view returns (address);

    function firstMinters(uint256 tokenId) external view returns (address);

    function getCreatorRewardRecipient(uint256 tokenId) external view returns (address);

    function adminMint(address recipient, uint256 tokenId, uint256 quantity, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHasContractName {
    /// @notice Contract name returns the pretty contract name
    function contractName() external returns (string memory);
}

interface IContractMetadata is IHasContractName {
    /// @notice Contract URI returns the uri for more information about the given contract
    function contractURI() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165Upgradeable} from "@zoralabs/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC165Upgradeable.sol";
import {ILimitedMintPerAddressErrors} from "@zoralabs/shared-contracts/interfaces/errors/IZoraCreator1155Errors.sol";

interface ILimitedMintPerAddress is IERC165Upgradeable, ILimitedMintPerAddressErrors {
    function getMintedPerWallet(address token, uint256 tokenId, address wallet) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}