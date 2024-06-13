// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @notice implements a method to read uint256 data from storage at a bytes32 storage slot key.
contract StorageRead {
    function readFromStorage(bytes32 slot_) public view returns (uint256 result_) {
        assembly {
            result_ := sload(slot_) // read value from the storage slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

contract Error {
    error FluidVaultError(uint256 errorId_);

    /// @notice used to simulate liquidation to find the maximum liquidatable amounts
    error FluidLiquidateResult(uint256 colLiquidated, uint256 debtLiquidated);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

library ErrorTypes {
    /***********************************|
    |           Vault Factory           | 
    |__________________________________*/

    uint256 internal constant VaultFactory__InvalidOperation = 30001;
    uint256 internal constant VaultFactory__Unauthorized = 30002;
    uint256 internal constant VaultFactory__SameTokenNotAllowed = 30003;
    uint256 internal constant VaultFactory__InvalidParams = 30004;
    uint256 internal constant VaultFactory__InvalidVault = 30005;
    uint256 internal constant VaultFactory__InvalidVaultAddress = 30006;
    uint256 internal constant VaultFactory__OnlyDelegateCallAllowed = 30007;

    /***********************************|
    |            VaultT1                | 
    |__________________________________*/

    /// @notice thrown at reentrancy
    uint256 internal constant VaultT1__AlreadyEntered = 31001;

    /// @notice thrown when user sends deposit & borrow amount as 0
    uint256 internal constant VaultT1__InvalidOperateAmount = 31002;

    /// @notice thrown when msg.value is not in sync with native token deposit or payback
    uint256 internal constant VaultT1__InvalidMsgValueOperate = 31003;

    /// @notice thrown when msg.sender is not the owner of the vault
    uint256 internal constant VaultT1__NotAnOwner = 31004;

    /// @notice thrown when user's position does not exist. Sending the wrong index from the frontend
    uint256 internal constant VaultT1__TickIsEmpty = 31005;

    /// @notice thrown when the user's position is above CF and the user tries to make it more risky by trying to withdraw or borrow
    uint256 internal constant VaultT1__PositionAboveCF = 31006;

    /// @notice thrown when the top tick is not initialized. Happens if the vault is totally new or all the user's left
    uint256 internal constant VaultT1__TopTickDoesNotExist = 31007;

    /// @notice thrown when msg.value in liquidate is not in sync payback
    uint256 internal constant VaultT1__InvalidMsgValueLiquidate = 31008;

    /// @notice thrown when slippage is more on liquidation than what the liquidator sent
    uint256 internal constant VaultT1__ExcessSlippageLiquidation = 31009;

    /// @notice thrown when msg.sender is not the rebalancer/reserve contract
    uint256 internal constant VaultT1__NotRebalancer = 31010;

    /// @notice thrown when NFT of one vault interacts with the NFT of other vault
    uint256 internal constant VaultT1__NftNotOfThisVault = 31011;

    /// @notice thrown when the token is not initialized on the liquidity contract
    uint256 internal constant VaultT1__TokenNotInitialized = 31012;

    /// @notice thrown when admin updates fallback if a non-auth calls vault
    uint256 internal constant VaultT1__NotAnAuth = 31013;

    /// @notice thrown in operate when user tries to witdhraw more collateral than deposited
    uint256 internal constant VaultT1__ExcessCollateralWithdrawal = 31014;

    /// @notice thrown in operate when user tries to payback more debt than borrowed
    uint256 internal constant VaultT1__ExcessDebtPayback = 31015;

    /// @notice thrown when user try to withdrawal more than operate's withdrawal limit
    uint256 internal constant VaultT1__WithdrawMoreThanOperateLimit = 31016;

    /// @notice thrown when caller of liquidityCallback is not Liquidity
    uint256 internal constant VaultT1__InvalidLiquidityCallbackAddress = 31017;

    /// @notice thrown when reentrancy is not already on
    uint256 internal constant VaultT1__NotEntered = 31018;

    /// @notice thrown when someone directly calls secondary implementation contract
    uint256 internal constant VaultT1__OnlyDelegateCallAllowed = 31019;

    /// @notice thrown when the safeTransferFrom for a token amount failed
    uint256 internal constant VaultT1__TransferFromFailed = 31020;

    /// @notice thrown when exchange price overflows while updating on storage
    uint256 internal constant VaultT1__ExchangePriceOverFlow = 31021;

    /// @notice thrown when debt to liquidate amt is sent wrong
    uint256 internal constant VaultT1__InvalidLiquidationAmt = 31022;

    /// @notice thrown when user debt or collateral goes above 2**128 or below -2**128
    uint256 internal constant VaultT1__UserCollateralDebtExceed = 31023;

    /// @notice thrown if on liquidation branch debt becomes lower than 100
    uint256 internal constant VaultT1__BranchDebtTooLow = 31024;

    /// @notice thrown when tick's debt is less than 10000
    uint256 internal constant VaultT1__TickDebtTooLow = 31025;

    /// @notice thrown when the received new liquidity exchange price is of unexpected value (< than the old one)
    uint256 internal constant VaultT1__LiquidityExchangePriceUnexpected = 31026;

    /// @notice thrown when user's debt is less than 10000
    uint256 internal constant VaultT1__UserDebtTooLow = 31027;

    /// @notice thrown when on only payback and only deposit the ratio of position increases
    uint256 internal constant VaultT1__InvalidPaybackOrDeposit = 31028;

    /// @notice thrown when liquidation just happens of a single partial
    uint256 internal constant VaultT1__InvalidLiquidation = 31029;

    /// @notice thrown when msg.value is sent wrong in rebalance
    uint256 internal constant VaultT1__InvalidMsgValueInRebalance = 31030;

    /// @notice thrown when nothing rebalanced
    uint256 internal constant VaultT1__NothingToRebalance = 31031;

    /***********************************|
    |              ERC721               | 
    |__________________________________*/

    uint256 internal constant ERC721__InvalidParams = 32001;
    uint256 internal constant ERC721__Unauthorized = 32002;
    uint256 internal constant ERC721__InvalidOperation = 32003;
    uint256 internal constant ERC721__UnsafeRecipient = 32004;
    uint256 internal constant ERC721__OutOfBoundsIndex = 32005;

    /***********************************|
    |            Vault Admin            | 
    |__________________________________*/

    /// @notice thrown when admin tries to setup invalid value which are crossing limits
    uint256 internal constant VaultT1Admin__ValueAboveLimit = 33001;

    /// @notice when someone directly calls admin implementation contract
    uint256 internal constant VaultT1Admin__OnlyDelegateCallAllowed = 33002;

    /// @notice thrown when auth sends NFT ID as 0 while collecting dust debt
    uint256 internal constant VaultT1Admin__NftIdShouldBeNonZero = 33003;

    /// @notice thrown when trying to collect dust debt of NFT which is not of this vault
    uint256 internal constant VaultT1Admin__NftNotOfThisVault = 33004;

    /// @notice thrown when dust debt of NFT is 0, meaning nothing to collect
    uint256 internal constant VaultT1Admin__DustDebtIsZero = 33005;

    /// @notice thrown when final debt after liquidation is not 0, meaning position 100% liquidated
    uint256 internal constant VaultT1Admin__FinalDebtShouldBeZero = 33006;

    /// @notice thrown when NFT is not liquidated state
    uint256 internal constant VaultT1Admin__NftNotLiquidated = 33007;

    /// @notice thrown when total absorbed dust debt is 0
    uint256 internal constant VaultT1Admin__AbsorbedDustDebtIsZero = 33008;

    /// @notice thrown when address is set as 0
    uint256 internal constant VaultT1Admin__AddressZeroNotAllowed = 33009;

    /***********************************|
    |            Vault Rewards          | 
    |__________________________________*/

    uint256 internal constant VaultRewards__Unauthorized = 34001;
    uint256 internal constant VaultRewards__AddressZero = 34002;
    uint256 internal constant VaultRewards__InvalidParams = 34003;
    uint256 internal constant VaultRewards__NewMagnifierSameAsOldMagnifier = 34004;
    uint256 internal constant VaultRewards__NotTheInitiator = 34005;
    uint256 internal constant VaultRewards__AlreadyStarted = 34006;
    uint256 internal constant VaultRewards__RewardsNotStartedOrEnded = 34007;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ErrorTypes } from "../../errorTypes.sol";
import { Error } from "../../error.sol";

/// @notice Fluid Vault Factory ERC721 base contract. Implements the ERC721 standard, based on Solmate.
/// In addition, implements ERC721 Enumerable.
/// Modern, minimalist, and gas efficient ERC-721 with Enumerable implementation.
///
/// @author Instadapp
/// @author Modified Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is Error {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    // token id => token config
    // uint160 0 - 159: address:: owner
    // uint32 160 - 191: uint32:: index
    // uint32 192 - 223: uint32:: vaultId
    // uint32 224 - 255: uint32:: null
    mapping(uint256 => uint256) internal _tokenConfig;

    // owner => slot => index
    /*
    // slot 0: 
    // uint32 0 - 31: uint32:: balanceOf
    // uint224 32 - 255: 7 tokenIds each of uint32 packed
    // slot N (N >= 1)
    // uint32 * 8 each tokenId
    */
    mapping(address => mapping(uint256 => uint256)) internal _ownerConfig;

    /// @notice returns `owner_` of NFT with `id_`
    function ownerOf(uint256 id_) public view virtual returns (address owner_) {
        if ((owner_ = address(uint160(_tokenConfig[id_]))) == address(0))
            revert FluidVaultError(ErrorTypes.ERC721__InvalidParams);
    }

    /// @notice returns total count of NFTs owned by `owner_`
    function balanceOf(address owner_) public view virtual returns (uint256) {
        if (owner_ == address(0)) revert FluidVaultError(ErrorTypes.ERC721__InvalidParams);

        return _ownerConfig[owner_][0] & type(uint32).max;
    }

    /*//////////////////////////////////////////////////////////////
                    ERC721Enumerable STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice total amount of tokens stored by the contract.
    uint256 public totalSupply;

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice trackes if a NFT id is approved for a certain address.
    mapping(uint256 => address) public getApproved;

    /// @notice trackes if all the NFTs of an owner are approved for a certain other address.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice approves an NFT with `id_` to be spent (transferred) by `spender_`
    function approve(address spender_, uint256 id_) public virtual {
        address owner_ = address(uint160(_tokenConfig[id_]));
        if (!(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender]))
            revert FluidVaultError(ErrorTypes.ERC721__Unauthorized);

        getApproved[id_] = spender_;

        emit Approval(owner_, spender_, id_);
    }

    /// @notice approves all NFTs owned by msg.sender to be spent (transferred) by `operator_`
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;

        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    /// @notice transfers an NFT with `id_` `from_` address `to_` address without safe check
    function transferFrom(address from_, address to_, uint256 id_) public virtual {
        uint256 tokenConfig_ = _tokenConfig[id_];
        if (from_ != address(uint160(tokenConfig_))) revert FluidVaultError(ErrorTypes.ERC721__InvalidParams);

        if (!(msg.sender == from_ || isApprovedForAll[from_][msg.sender] || msg.sender == getApproved[id_]))
            revert FluidVaultError(ErrorTypes.ERC721__Unauthorized);

        // call _transfer with vaultId extracted from tokenConfig_
        _transfer(from_, to_, id_, (tokenConfig_ >> 192) & type(uint32).max);

        delete getApproved[id_];

        emit Transfer(from_, to_, id_);
    }

    /// @notice transfers an NFT with `id_` `from_` address `to_` address
    function safeTransferFrom(address from_, address to_, uint256 id_) public virtual {
        transferFrom(from_, to_, id_);

        if (
            !(to_.code.length == 0 ||
                ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, id_, "") ==
                ERC721TokenReceiver.onERC721Received.selector)
        ) revert FluidVaultError(ErrorTypes.ERC721__UnsafeRecipient);
    }

    /// @notice transfers an NFT with `id_` `from_` address `to_` address, passing `data_` to `onERC721Received` callback
    function safeTransferFrom(address from_, address to_, uint256 id_, bytes calldata data_) public virtual {
        transferFrom(from_, to_, id_);

        if (
            !((to_.code.length == 0) ||
                ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, id_, data_) ==
                ERC721TokenReceiver.onERC721Received.selector)
        ) revert FluidVaultError(ErrorTypes.ERC721__UnsafeRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721Enumerable LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a token ID at a given `index_` of all the tokens stored by the contract.
    /// Use along with {totalSupply} to enumerate all tokens.
    function tokenByIndex(uint256 index_) external view returns (uint256) {
        if (index_ >= totalSupply) {
            revert FluidVaultError(ErrorTypes.ERC721__OutOfBoundsIndex);
        }
        return index_ + 1;
    }

    /// @notice Returns a token ID owned by `owner_` at a given `index_` of its token list.
    /// Use along with {balanceOf} to enumerate all of `owner_`'s tokens.
    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256) {
        if (index_ >= balanceOf(owner_)) {
            revert FluidVaultError(ErrorTypes.ERC721__OutOfBoundsIndex);
        }

        index_ = index_ + 1;
        return (_ownerConfig[owner_][index_ / 8] >> ((index_ % 8) * 32)) & type(uint32).max;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId_) public view virtual returns (bool) {
        return
            interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId_ == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId_ == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId_ == 0x780e9d63; // ERC165 Interface ID for ERC721Enumberable
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from_, address to_, uint256 id_, uint256 vaultId_) internal {
        if (to_ == address(0)) {
            revert FluidVaultError(ErrorTypes.ERC721__InvalidOperation);
        } else if (from_ == address(0)) {
            _add(to_, id_, vaultId_);
        } else if (to_ != from_) {
            _remove(from_, id_);
            _add(to_, id_, vaultId_);
        }
    }

    function _add(address user_, uint256 id_, uint256 vaultId_) private {
        uint256 ownerConfig_ = _ownerConfig[user_][0];
        unchecked {
            // index starts from `1`
            uint256 balanceOf_ = (ownerConfig_ & type(uint32).max) + 1;

            _tokenConfig[id_] = (uint160(user_) | (balanceOf_ << 160) | (vaultId_ << 192));

            _ownerConfig[user_][0] = (ownerConfig_ & ~uint256(type(uint32).max)) | (balanceOf_);

            uint256 wordIndex_ = (balanceOf_ / 8);
            _ownerConfig[user_][wordIndex_] = _ownerConfig[user_][wordIndex_] | (id_ << ((balanceOf_ % 8) * 32));
        }
    }

    function _remove(address user_, uint256 id_) private {
        uint256 temp_ = _tokenConfig[id_];

        // fetching `id_` details and deleting it.
        uint256 tokenIndex_ = (temp_ >> 160) & type(uint32).max;
        _tokenConfig[id_] = 0;

        // fetching & updating balance
        temp_ = _ownerConfig[user_][0];
        uint256 lastTokenIndex_ = (temp_ & type(uint32).max); // (lastTokenIndex_ = balanceOf)
        _ownerConfig[user_][0] = (temp_ & ~uint256(type(uint32).max)) | (lastTokenIndex_ - 1);

        {
            unchecked {
                uint256 lastTokenWordIndex_ = (lastTokenIndex_ / 8);
                uint256 lastTokenBitShift_ = (lastTokenIndex_ % 8) * 32;
                temp_ = _ownerConfig[user_][lastTokenWordIndex_];

                // replace `id_` tokenId with `last` tokenId.
                if (lastTokenIndex_ != tokenIndex_) {
                    uint256 wordIndex_ = (tokenIndex_ / 8);
                    uint256 bitShift_ = (tokenIndex_ % 8) * 32;

                    // temp_ here is _ownerConfig[user_][lastTokenWordIndex_];
                    uint256 lastTokenId_ = uint256((temp_ >> lastTokenBitShift_) & type(uint32).max);
                    if (wordIndex_ == lastTokenWordIndex_) {
                        // this case, when lastToken and currentToken are in same slot.
                        // updating temp_ as we will remove the lastToken from this slot itself
                        temp_ = (temp_ & ~(uint256(type(uint32).max) << bitShift_)) | (lastTokenId_ << bitShift_);
                    } else {
                        _ownerConfig[user_][wordIndex_] =
                            (_ownerConfig[user_][wordIndex_] & ~(uint256(type(uint32).max) << bitShift_)) |
                            (lastTokenId_ << bitShift_);
                    }
                    _tokenConfig[lastTokenId_] =
                        (_tokenConfig[lastTokenId_] & ~(uint256(type(uint32).max) << 160)) |
                        (tokenIndex_ << 160);
                }

                // temp_ here is _ownerConfig[user_][lastTokenWordIndex_];
                _ownerConfig[user_][lastTokenWordIndex_] = temp_ & ~(uint256(type(uint32).max) << lastTokenBitShift_);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to_, uint256 vaultId_) internal virtual returns (uint256 id_) {

        unchecked {
            ++totalSupply;
        }

        id_ = totalSupply;
        if (id_ >= type(uint32).max || _tokenConfig[id_] != 0) revert FluidVaultError(ErrorTypes.ERC721__InvalidParams);

        _transfer(address(0), to_, id_, vaultId_);

        emit Transfer(address(0), to_, id_);
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Owned } from "solmate/src/auth/Owned.sol";
import { ERC721 } from "./ERC721/ERC721.sol";
import { ErrorTypes } from "../errorTypes.sol";

import { StorageRead } from "../../../libraries/storageRead.sol";

abstract contract VaultFactoryVariables is Owned, ERC721, StorageRead {
    /// @dev ERC721 tokens name
    string internal constant ERC721_NAME = "Fluid Vault";
    /// @dev ERC721 tokens symbol
    string internal constant ERC721_SYMBOL = "fVLT";

    /*//////////////////////////////////////////////////////////////
                          STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // ------------ storage variables from inherited contracts (Owned and ERC721) come before vars here --------

    // ----------------------- slot 0 ---------------------------
    // address public owner; // from Owned

    // 12 bytes empty

    // ----------------------- slot 1 ---------------------------
    // string public name;

    // ----------------------- slot 2 ---------------------------
    // string public symbol;

    // ----------------------- slot 3 ---------------------------
    // mapping(uint256 => uint256) internal _tokenConfig;

    // ----------------------- slot 4 ---------------------------
    // mapping(address => mapping(uint256 => uint256)) internal _ownerConfig;

    // ----------------------- slot 5 ---------------------------
    // uint256 public totalSupply;

    // ----------------------- slot 6 ---------------------------
    // mapping(uint256 => address) public getApproved;

    // ----------------------- slot 7  ---------------------------
    // mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ----------------------- slot 8  ---------------------------
    /// @dev deployer can deploy new Vault contract
    /// owner can add/remove deployer.
    /// Owner is deployer by default.
    mapping(address => bool) internal _deployers;

    // ----------------------- slot 9  ---------------------------
    /// @dev global auths can update any vault config.
    /// owner can add/remove global auths.
    /// Owner is global auth by default.
    mapping(address => bool) internal _globalAuths;

    // ----------------------- slot 10  ---------------------------
    /// @dev vault auths can update specific vault config.
    /// owner can add/remove vault auths.
    /// Owner is vault auth by default.
    /// vault => auth => add/remove
    mapping(address => mapping(address => bool)) internal _vaultAuths;

    // ----------------------- slot 11 ---------------------------
    /// @dev total no of vaults deployed by the factory
    /// only addresses that have deployer role or owner can deploy new vault.
    uint256 internal _totalVaults;

    // ----------------------- slot 12 ---------------------------
    /// @dev vault deployment logics for deploying vault
    /// These logic contracts hold the deployment logics of specific vaults and are called via .delegatecall inside deployVault().
    /// only addresses that have owner can add/remove new vault deployment logic.
    mapping(address => bool) internal _vaultDeploymentLogics;

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address owner_) Owned(owner_) ERC721(ERC721_NAME, ERC721_SYMBOL) {}
}

abstract contract VaultFactoryEvents {
    /// @dev Emitted when a new vault is deployed.
    /// @param vault The address of the newly deployed vault.
    /// @param vaultId The id of the newly deployed vault.
    event VaultDeployed(address indexed vault, uint256 indexed vaultId);

    /// @dev Emitted when a new token/position is minted by a vault.
    /// @param vault The address of the vault that minted the token.
    /// @param user The address of the user who received the minted token.
    /// @param tokenId The ID of the newly minted token.
    event NewPositionMinted(address indexed vault, address indexed user, uint256 indexed tokenId);

    /// @dev Emitted when the deployer is modified by owner.
    /// @param deployer Address whose deployer status is updated.
    /// @param allowed Indicates whether the address is authorized as a deployer or not.
    event LogSetDeployer(address indexed deployer, bool indexed allowed);

    /// @dev Emitted when the globalAuth is modified by owner.
    /// @param globalAuth Address whose globalAuth status is updated.
    /// @param allowed Indicates whether the address is authorized as a deployer or not.
    event LogSetGlobalAuth(address indexed globalAuth, bool indexed allowed);

    /// @dev Emitted when the vaultAuth is modified by owner.
    /// @param vaultAuth Address whose vaultAuth status is updated.
    /// @param allowed Indicates whether the address is authorized as a deployer or not.
    /// @param vault Address of the specific vault related to the authorization change.
    event LogSetVaultAuth(address indexed vaultAuth, bool indexed allowed, address indexed vault);

    /// @dev Emitted when the vault deployment logic is modified by owner.
    /// @param vaultDeploymentLogic The address of the vault deployment logic contract.
    /// @param allowed  Indicates whether the address is authorized as a deployer or not.
    event LogSetVaultDeploymentLogic(address indexed vaultDeploymentLogic, bool indexed allowed);
}

abstract contract VaultFactoryCore is VaultFactoryVariables, VaultFactoryEvents {
    constructor(address owner_) validAddress(owner_) VaultFactoryVariables(owner_) {}

    /// @dev validates that an address is not the zero address
    modifier validAddress(address value_) {
        if (value_ == address(0)) {
            revert FluidVaultError(ErrorTypes.VaultFactory__InvalidParams);
        }
        _;
    }
}

/// @dev Implements Vault Factory auth-only callable methods. Owner / auths can set various config values and
/// can define the allow-listed deployers.
abstract contract VaultFactoryAuth is VaultFactoryCore {
    /// @notice                         Sets an address (`deployer_`) as allowed deployer or not.
    ///                                 This function can only be called by the owner.
    /// @param deployer_                The address to be set as deployer.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy vaults.
    function setDeployer(address deployer_, bool allowed_) external onlyOwner validAddress(deployer_) {
        _deployers[deployer_] = allowed_;

        emit LogSetDeployer(deployer_, allowed_);
    }

    /// @notice                         Sets an address (`globalAuth_`) as a global authorization or not.
    ///                                 This function can only be called by the owner.
    /// @param globalAuth_              The address to be set as global authorization.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to update any vault config.
    function setGlobalAuth(address globalAuth_, bool allowed_) external onlyOwner validAddress(globalAuth_) {
        _globalAuths[globalAuth_] = allowed_;

        emit LogSetGlobalAuth(globalAuth_, allowed_);
    }

    /// @notice                         Sets an address (`vaultAuth_`) as allowed vault authorization or not for a specific vault (`vault_`).
    ///                                 This function can only be called by the owner.
    /// @param vault_                   The address of the vault for which the authorization is being set.
    /// @param vaultAuth_               The address to be set as vault authorization.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to update the specific vault config.
    function setVaultAuth(
        address vault_,
        address vaultAuth_,
        bool allowed_
    ) external onlyOwner validAddress(vaultAuth_) {
        _vaultAuths[vault_][vaultAuth_] = allowed_;

        emit LogSetVaultAuth(vaultAuth_, allowed_, vault_);
    }

    /// @notice                         Sets an address as allowed vault deployment logic (`deploymentLogic_`) contract or not.
    ///                                 This function can only be called by the owner.
    /// @param deploymentLogic_         The address of the vault deployment logic contract to be set.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy new type of vault.
    function setVaultDeploymentLogic(
        address deploymentLogic_,
        bool allowed_
    ) public onlyOwner validAddress(deploymentLogic_) {
        _vaultDeploymentLogics[deploymentLogic_] = allowed_;

        emit LogSetVaultDeploymentLogic(deploymentLogic_, allowed_);
    }

    /// @notice                         Spell allows owner aka governance to do any arbitrary call on factory
    /// @param target_                  Address to which the call needs to be delegated
    /// @param data_                    Data to execute at the delegated address
    function spell(address target_, bytes memory data_) external onlyOwner returns (bytes memory response_) {
        assembly {
            let succeeded := delegatecall(gas(), target_, add(data_, 0x20), mload(data_), 0, 0)
            let size := returndatasize()

            response_ := mload(0x40)
            mstore(0x40, add(response_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response_, size)
            returndatacopy(add(response_, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /// @notice                         Checks if the provided address (`deployer_`) is authorized as a deployer.
    /// @param deployer_                The address to be checked for deployer authorization.
    /// @return                         Returns `true` if the address is a deployer, otherwise `false`.
    function isDeployer(address deployer_) public view returns (bool) {
        return _deployers[deployer_] || owner == deployer_;
    }

    /// @notice                         Checks if the provided address (`globalAuth_`) has global vault authorization privileges.
    /// @param globalAuth_              The address to be checked for global authorization privileges.
    /// @return                         Returns `true` if the given address has global authorization privileges, otherwise `false`.
    function isGlobalAuth(address globalAuth_) public view returns (bool) {
        return _globalAuths[globalAuth_] || owner == globalAuth_;
    }

    /// @notice                         Checks if the provided address (`vaultAuth_`) has vault authorization privileges for the specified vault (`vault_`).
    /// @param vault_                   The address of the vault to check.
    /// @param vaultAuth_               The address to be checked for vault authorization privileges.
    /// @return                         Returns `true` if the given address has vault authorization privileges for the specified vault, otherwise `false`.
    function isVaultAuth(address vault_, address vaultAuth_) public view returns (bool) {
        return _vaultAuths[vault_][vaultAuth_] || owner == vaultAuth_;
    }

    /// @notice                         Checks if the provided (`vaultDeploymentLogic_`) address has authorization for vault deployment.
    /// @param vaultDeploymentLogic_    The address of the vault deploy logic to check for authorization privileges.
    /// @return                         Returns `true` if the given address has authorization privileges for vault deployment, otherwise `false`.
    function isVaultDeploymentLogic(address vaultDeploymentLogic_) public view returns (bool) {
        return _vaultDeploymentLogics[vaultDeploymentLogic_];
    }
}

/// @dev implements VaultFactory deploy vault related methods.
abstract contract VaultFactoryDeployment is VaultFactoryCore, VaultFactoryAuth {
    /// @dev                            Deploys a contract using the CREATE opcode with the provided bytecode (`bytecode_`).
    ///                                 This is an internal function, meant to be used within the contract to facilitate the deployment of other contracts.
    /// @param bytecode_                The bytecode of the contract to be deployed.
    /// @return address_                Returns the address of the deployed contract.
    function _deploy(bytes memory bytecode_) internal returns (address address_) {
        if (bytecode_.length == 0) {
            revert FluidVaultError(ErrorTypes.VaultFactory__InvalidOperation);
        }
        /// @solidity memory-safe-assembly
        assembly {
            address_ := create(0, add(bytecode_, 0x20), mload(bytecode_))
        }
        if (address_ == address(0)) {
            revert FluidVaultError(ErrorTypes.VaultFactory__InvalidOperation);
        }
    }

    /// @notice                         Deploys a new vault using the specified deployment logic `vaultDeploymentLogic_` and data `vaultDeploymentData_`.
    ///                                 Only accounts with deployer access or the owner can deploy a new vault.
    /// @param vaultDeploymentLogic_    The address of the vault deployment logic contract.
    /// @param vaultDeploymentData_     The data to be used for vault deployment.
    /// @return vault_                  Returns the address of the newly deployed vault.
    function deployVault(
        address vaultDeploymentLogic_,
        bytes calldata vaultDeploymentData_
    ) external returns (address vault_) {
        // Revert if msg.sender doesn't have deployer access or is an owner.
        if (!isDeployer(msg.sender)) revert FluidVaultError(ErrorTypes.VaultFactory__Unauthorized);
        // Revert if vaultDeploymentLogic_ is not whitelisted.
        if (!isVaultDeploymentLogic(vaultDeploymentLogic_))
            revert FluidVaultError(ErrorTypes.VaultFactory__Unauthorized);

        // Vault ID for the new vault and also acts as `nonce` for CREATE
        uint256 vaultId_ = ++_totalVaults;

        // compute vault address for vault id.
        vault_ = getVaultAddress(vaultId_);

        // deploy the vault using vault deployment logic by making .delegatecall
        (bool success_, bytes memory data_) = vaultDeploymentLogic_.delegatecall(vaultDeploymentData_);

        if (!(success_ && vault_ == _deploy(abi.decode(data_, (bytes))) && isVault(vault_))) {
            revert FluidVaultError(ErrorTypes.VaultFactory__InvalidVaultAddress);
        }

        emit VaultDeployed(vault_, vaultId_);
    }

    /// @notice                         Computes the address of a vault based on its given ID (`vaultId_`).
    /// @param vaultId_                 The ID of the vault.
    /// @return vault_                  Returns the computed address of the vault.
    function getVaultAddress(uint256 vaultId_) public view returns (address vault_) {
        // @dev based on https://ethereum.stackexchange.com/a/61413

        // nonce of smart contract always starts with 1. so, with nonce 0 there won't be any deployment
        // hence, nonce of vault deployment starts with 1.
        bytes memory data;
        if (vaultId_ == 0x00) {
            return address(0);
        } else if (vaultId_ <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), uint8(vaultId_));
        } else if (vaultId_ <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), address(this), bytes1(0x81), uint8(vaultId_));
        } else if (vaultId_ <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), address(this), bytes1(0x82), uint16(vaultId_));
        } else if (vaultId_ <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), address(this), bytes1(0x83), uint24(vaultId_));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), address(this), bytes1(0x84), uint32(vaultId_));
        }

        return address(uint160(uint256(keccak256(data))));
    }

    /// @notice                         Checks if a given address (`vault_`) corresponds to a valid vault.
    /// @param vault_                   The vault address to check.
    /// @return                         Returns `true` if the given address corresponds to a valid vault, otherwise `false`.
    function isVault(address vault_) public view returns (bool) {
        if (vault_.code.length == 0) {
            return false;
        } else {
            // VAULT_ID() function signature is 0x540acabc
            (bool success_, bytes memory data_) = vault_.staticcall(hex"540acabc");
            return success_ && vault_ == getVaultAddress(abi.decode(data_, (uint256)));
        }
    }

    /// @notice                   Returns the total number of vaults deployed by the factory.
    /// @return                   Returns the total number of vaults.
    function totalVaults() external view returns (uint256) {
        return _totalVaults;
    }
}

abstract contract VaultFactoryERC721 is VaultFactoryCore, VaultFactoryDeployment {
    /// @notice                   Mints a new ERC721 token for a specific vault (`vaultId_`) to a specified user (`user_`).
    ///                           Only the corresponding vault is authorized to mint a token.
    /// @param vaultId_           The ID of the vault that's minting the token.
    /// @param user_              The address receiving the minted token.
    /// @return tokenId_          The ID of the newly minted token.
    function mint(uint256 vaultId_, address user_) external returns (uint256 tokenId_) {
        if (msg.sender != getVaultAddress(vaultId_)) revert FluidVaultError(ErrorTypes.VaultFactory__InvalidVault);

        // Using _mint() instead of _safeMint() to allow any msg.sender to receive ERC721 without onERC721Received holder.
        tokenId_ = _mint(user_, vaultId_);

        emit NewPositionMinted(msg.sender, user_, tokenId_);
    }

    /// @notice                   Returns the URI of the specified token ID (`id_`).
    ///                           In this implementation, an empty string is returned as no specific URI is defined.
    /// @param id_                The ID of the token to query.
    /// @return                   An empty string since no specific URI is defined in this implementation.
    function tokenURI(uint256 id_) public view virtual override returns (string memory) {
        return "";
    }
}

/// @title Fluid VaultFactory
/// @notice creates Fluid vault protocol vaults, which are interacting with Fluid Liquidity to deposit / borrow funds.
/// Vaults are created at a deterministic address, given an incrementing `vaultId` (see `getVaultAddress()`).
/// Vaults can only be deployed by allow-listed deployer addresses.
/// This factory also implements ERC721-Enumerable, the NFTs are used to represent created user positions. Only vaults
/// can mint new NFTs.
/// @dev Note the deployed vaults start out with no config at Liquidity contract.
/// This must be done by Liquidity auths in a separate step, otherwise no deposits will be possible.
/// This contract is not upgradeable. It supports adding new vault deployment logic contracts for new, future vaults.
contract FluidVaultFactory is VaultFactoryCore, VaultFactoryAuth, VaultFactoryDeployment, VaultFactoryERC721 {
    constructor(address owner_) VaultFactoryCore(owner_) {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}