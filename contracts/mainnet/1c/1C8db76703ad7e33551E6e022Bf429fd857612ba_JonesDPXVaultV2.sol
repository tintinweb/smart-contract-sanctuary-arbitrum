// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

/// Libraries
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SushiRouterWrapper} from "./library/SushiRouterWrapper.sol";
import {DopexDpxSsovWrapper} from "./library/DopexDpxSsovWrapper.sol";

/// Interfaces
import {IDPXSSOVV2} from "../interfaces/IDPXSSOVV2.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IJonesAsset} from "../interfaces/IJonesAsset.sol";

/// @title Jones DPX V2 Vault
/// @author Jones DAO

contract JonesDPXVaultV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SushiRouterWrapper for IUniswapV2Router02;
    using DopexDpxSsovWrapper for IDPXSSOVV2;

    // jDPX Token
    IJonesAsset public jonesAssetToken;

    // DPX Token
    IERC20 public assetToken;

    // DPX SSOV contract
    IDPXSSOVV2 private SSOV;

    // Sushiswap router
    IUniswapV2Router02 private sushiRouter;

    // SushiRouterSellingtokens
    address[] private sellingTokens;

    // SushiRoutes
    address[][] private routes;

    // true if assets are under management
    // false if users can deposit and claim
    bool public MANAGEMENT_WINDOW_OPEN = true;

    // vault cap status
    bool public vaultCapSet = false;

    // wether we should charge fees
    bool public chargeFees = false;

    // vault cap value
    uint256 public vaultCap;

    // snapshot of the vault's DPX balance from previous epoch / before management starts
    uint256 public snapshotVaultBalance;

    // snapshot of jDPX total supply from previous epoch / before management starts
    uint256 public snapshotJonesAssetSupply;

    // DAO whitelist mapping
    mapping(address => uint256) public daoWhitelist;

    // The list of addresses the contract uses
    mapping(bytes32 => address) public addresses;

    /// @param _jonesAsset jDPX contract address.
    /// @param _asset DPX contract address.
    /// @param _SSOV SSOV contract address.
    /// @param _aumMultisigAddr AUM multisig address.
    /// @param _feeDistributor Address to which we send management and performance fees.
    /// @param _externalWhitelister Non multisig address which can add new addresses to the DAO whitelist.
    /// @param _snapshotVaultBalance Vault balance snapshot value.
    /// @param _snapshotJonesAssetSupply jDPX supply snapshot value.
    constructor(
        IJonesAsset _jonesAsset,
        IERC20 _asset,
        IDPXSSOVV2 _SSOV,
        address _aumMultisigAddr,
        address _feeDistributor,
        address _externalWhitelister,
        uint256 _snapshotVaultBalance,
        uint256 _snapshotJonesAssetSupply
    ) {
        require(_aumMultisigAddr != address(0), "VE1");
        require(_snapshotVaultBalance > 0, "VE2");
        require(_snapshotJonesAssetSupply > 0, "VE2");

        jonesAssetToken = _jonesAsset;
        assetToken = _asset;
        SSOV = _SSOV;
        snapshotVaultBalance = _snapshotVaultBalance;
        snapshotJonesAssetSupply = _snapshotJonesAssetSupply;

        // set addresses
        addresses["AUMMultisig"] = _aumMultisigAddr;
        addresses["FeeDistributor"] = _feeDistributor;
        addresses["Whitelistoor"] = _externalWhitelister;
        addresses["rDPX"] = 0x32Eb7902D4134bf98A28b963D26de779AF92A212;
        addresses["wETH"] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

        sushiRouter = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        // Token spending approval for SushiSwap
        IERC20(getAddress("rDPX")).safeApprove(
            address(sushiRouter),
            type(uint256).max
        );

        // Token spending approval for SSOV
        assetToken.safeApprove(address(SSOV), type(uint256).max);

        sellingTokens = [getAddress("rDPX")];

        routes = [[getAddress("rDPX"), getAddress("wETH"), address(_asset)]];

        transferOwnership(_aumMultisigAddr);
    }

    // ============================== Depositing ==============================

    /// Mint jDPX by depositing DPX into the vault.
    /// @param _amount Amount of DPX to deposit.
    function depositAsset(uint256 _amount)
        public
        nonReentrant
        whenNotManagementWindow
    {
        require(_amount > 0, "VE2");

        if (vaultCapSet) {
            // if user is a whitelisted DAO
            if (isWhitelisted(msg.sender)) {
                require(_amount <= daoWhitelist[msg.sender], "VE2");

                // update whitelisted amount
                daoWhitelist[msg.sender] = daoWhitelist[msg.sender].sub(
                    _amount
                );

                emit WhitelistUpdate(msg.sender, daoWhitelist[msg.sender]);
            } else {
                require(
                    assetToken.balanceOf(address(this)).add(_amount) <=
                        vaultCap,
                    "VE3"
                );
            }
        }

        uint256 mintableJAsset = convertToJAsset(_amount);

        // deposit DPX into the vault
        assetToken.safeTransferFrom(msg.sender, address(this), _amount);

        // mint jDPX
        jonesAssetToken.mint(msg.sender, mintableJAsset);

        emit Deposited(msg.sender, mintableJAsset, _amount);
    }

    // ============================== Claiming ==============================

    /// Burn jDPX and redeem DPX from the vault.
    /// @dev Assumes both tokens have same decimal places.
    /// @param _amount Amount of jDPX to burn.
    function claimAsset(uint256 _amount)
        public
        nonReentrant
        whenNotManagementWindow
    {
        require(_amount > 0, "VE2");
        require(jonesAssetToken.balanceOf(msg.sender) >= _amount, "VE4");
        uint256 redeemableAsset = convertToAsset(_amount);

        // burn jDPX
        jonesAssetToken.burnFrom(msg.sender, _amount);

        // redeem DPX
        assetToken.transfer(msg.sender, redeemableAsset);

        emit Claimed(msg.sender, redeemableAsset, _amount);
    }

    // ============================== Setters ==============================

    /// Claims and deposits close, assets are under vault control.
    function openManagementWindow() public onlyOwner whenNotManagementWindow {
        _executeSnapshot();

        if (chargeFees) {
            // send management fee to fee distributor (2% annually)
            // 1 / 600 = 2 / (100 * 12)
            assetToken.safeTransfer(
                getAddress("FeeDistributor"),
                assetToken.balanceOf(address(this)).div(600)
            );
        }

        MANAGEMENT_WINDOW_OPEN = true;
        emit EpochStarted(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /// Initial setup of the vault.
    /// @dev run when vault should open for the first contract's epoch.
    /// @param _vaultCapSet True if vault cap is set.
    /// @param _vaultCap Vault cap (18 decimal).
    /// @param _snapshotVaultBalance Update vault balance (18 decimal).
    function initialRun(
        bool _vaultCapSet,
        uint256 _vaultCap,
        uint256 _snapshotVaultBalance
    ) public onlyOwner whenManagementWindow {
        // set vault cap if true
        if (_vaultCapSet) {
            require(_vaultCap > 0, "VE2");
            vaultCap = _vaultCap;
            vaultCapSet = true;
        }

        snapshotVaultBalance = _snapshotVaultBalance;

        MANAGEMENT_WINDOW_OPEN = false;
        emit EpochEnded(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /// @notice Open vault for deposits and claims.
    /// @dev claims rewards from Dopex, sells DPX and rDPX rewards, sends performance fee to fee distributor.
    /// @param _vaultCapSet True if vault cap is set.
    /// @param _vaultCap Vault cap (18 decimal).
    /// @param _assetAmtFromrDpx DPX output amount from selling rDPX.
    function closeManagementWindow(
        bool _vaultCapSet,
        uint256 _vaultCap,
        uint256 _assetAmtFromrDpx
    ) public onlyOwner whenManagementWindow {
        // claim deposits and settle calls from SSOV
        SSOV.settleEpoch(address(this));

        // Sell rDPX for DPX
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _assetAmtFromrDpx;

        sushiRouter.sellTokens(amounts, sellingTokens, address(this), routes);

        uint256 balanceNow = assetToken.balanceOf(address(this));

        if ((balanceNow > snapshotVaultBalance) && chargeFees) {
            // send performance fee to fee distributor (20% on profit wrt benchmark)
            // 1 / 5 = 20 / 100
            assetToken.safeTransfer(
                getAddress("FeeDistributor"),
                balanceNow.sub(snapshotVaultBalance).div(5)
            );
        }

        // update snapshot
        _executeSnapshot();

        // set vault cap if true
        if (_vaultCapSet) {
            require(_vaultCap > 0, "VE2");
            vaultCap = _vaultCap;
            vaultCapSet = true;
        }

        MANAGEMENT_WINDOW_OPEN = false;
        emit EpochEnded(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /// Update SSOV contract address in case it changes.
    /// @dev This function is called by the AUM multisig.
    function updateSSOVAddress(IDPXSSOVV2 _newSSOV) public onlyOwner {
        assetToken.safeApprove(address(SSOV), 0); // revoke old
        SSOV = _newSSOV;
        assetToken.safeApprove(address(SSOV), type(uint256).max); // approve new
    }

    /// Update vault value snapshot.
    function _executeSnapshot() private {
        snapshotJonesAssetSupply = jonesAssetToken.totalSupply();
        snapshotVaultBalance = assetToken.balanceOf(address(this));

        emit Snapshot(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    // ============================== AUM multisig functions ==============================

    /// Migrate vault to new vault contract.
    /// @dev acts as emergency withdrawal if needed.
    /// @param _to New vault contract address.
    /// @param _tokens Addresses of tokens to be migrated.
    function migrateVault(address _to, address[] memory _tokens)
        public
        onlyOwner
        whenManagementWindow
    {
        // migrate other ERC20 Tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 tkn = IERC20(_tokens[i]);
            uint256 assetBalance = tkn.balanceOf(address(this));
            if (assetBalance > 0) {
                tkn.transfer(_to, assetBalance);
            }
        }

        // migrate ETH balance
        uint256 balanceGwei = address(this).balance;
        if (balanceGwei > 0) {
            payable(_to).transfer(balanceGwei);
        }
    }

    /// Update whether we should be charging fees.
    function setChargeFees(bool _status) public onlyOwner {
        chargeFees = _status;
    }

    // ============================== Dopex interaction ==============================

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of DPX to deposit.
     * @return Whether deposit was successful.
     */
    function depositSSOV(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        whenManagementWindow
        returns (bool)
    {
        return SSOV.depositSSOV(_strikeIndex, _amount, address(this));
    }

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of DPX to deposit.
     * @return Whether deposits went through successfully.
     */
    function depositSSOVMultiple(
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts
    ) public onlyOwner whenManagementWindow returns (bool) {
        return
            SSOV.depositSSOVMultiple(_strikeIndices, _amounts, address(this));
    }

    /**
     * Buys calls from Dopex SSOV.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of calls to purchase.
     * @return Whether call purchase went through successfully.
     */
    function purchaseCall(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        whenManagementWindow
        returns (bool)
    {
        return SSOV.purchaseCall(_strikeIndex, _amount, address(this));
    }

    // ============================== DAO Whitelist ==============================

    /// Adds a new DAO to the whitelist.
    /// @param _addr address to be added to the whitelist.
    /// @param _amount allowed amount for this address.
    function addToWhitelist(address _addr, uint256 _amount)
        public
        onlyWhitelistoors
    {
        require(!isWhitelisted(_addr), "VE5");
        daoWhitelist[_addr] = _amount;
        emit WhitelistUpdate(_addr, _amount);
    }

    /// Check if address is whitelisted.
    /// @param _addr address to be checked.
    /// @return Whether address is whitelisted.
    function isWhitelisted(address _addr) public view returns (bool) {
        return daoWhitelist[_addr] > 0;
    }

    /// Removes an address from the whitelist.
    /// @param _addr address to be removed.
    function removeFromWhitelist(address _addr) public onlyWhitelistoors {
        require(isWhitelisted(_addr), "VE6");
        daoWhitelist[_addr] = 0;
        emit WhitelistUpdate(_addr, 0);
    }

    // ============================== Views ==============================

    /// Calculates claimable DPX for a given user.
    /// @param _user user address.
    /// @return claimable DPX.
    function claimableAsset(address _user) public view returns (uint256) {
        uint256 usrBalance = jonesAssetToken.balanceOf(_user);
        if (usrBalance > 0) {
            return convertToAsset(usrBalance);
        }
        return 0;
    }

    /// Calculates claimable DPX amount for a given amount of jDPX.
    /// @param _jAssetAmount Amount of jDPX.
    /// @return claimable DPX amount.
    function convertToAsset(uint256 _jAssetAmount)
        public
        view
        returns (uint256)
    {
        return
            _jAssetAmount.mul(snapshotVaultBalance).div(
                snapshotJonesAssetSupply
            );
    }

    /// Calculates mintable jDPX amount for a given amount of DPX.
    /// @param _assetAmount Amount of DPX.
    /// @return mintable jDPX amount.
    function convertToJAsset(uint256 _assetAmount)
        public
        view
        returns (uint256)
    {
        return
            _assetAmount.mul(snapshotJonesAssetSupply).div(
                snapshotVaultBalance
            );
    }

    /// Gets the address of a set contract
    /// @param _name Name of the contract
    /// @return The address of the contract
    function getAddress(bytes32 _name) public view returns (address) {
        return addresses[_name];
    }

    // ============================== Modifiers ==============================

    /// When both deposits and claiming are closed, vault can manage DPX.
    modifier whenManagementWindow() {
        require(MANAGEMENT_WINDOW_OPEN, "VE7");
        _;
    }

    /// When management window is closed, deposits and claiming are open.
    modifier whenNotManagementWindow() {
        require(!MANAGEMENT_WINDOW_OPEN, "VE8");
        _;
    }

    /// When message sender is either the multisig or the whitelist manager
    modifier onlyWhitelistoors() {
        require(
            msg.sender == owner() || msg.sender == getAddress("Whitelistoor"),
            "VE9"
        );
        _;
    }

    // ============================== Events ==============================

    /// emitted on user deposit
    /// @param _from depositor address (indexed)
    /// @param _assetAmount DPX deposit amount
    /// @param _jonesAssetAmount jDPX mint amount
    event Deposited(
        address indexed _from,
        uint256 _assetAmount,
        uint256 _jonesAssetAmount
    );

    /// emitted on user claim
    /// @param _from claimer address (indexed)
    /// @param _assetAmount DPX claim amount
    /// @param _jonesAssetAmount jDPX burn amount
    event Claimed(
        address indexed _from,
        uint256 _assetAmount,
        uint256 _jonesAssetAmount
    );

    /// emitted when vault balance snapshot is taken
    /// @param _timestamp snapshot timestamp (indexed)
    /// @param _vaultBalance vault balance value
    /// @param _jonesAssetSupply jDPX total supply value
    event Snapshot(
        uint256 indexed _timestamp,
        uint256 _vaultBalance,
        uint256 _jonesAssetSupply
    );

    /// emitted when asset management window is opened
    /// @param _timestamp snapshot timestamp (indexed)
    /// @param _assetAmount new vault balance value
    /// @param _jonesAssetSupply jDPX total supply at this time
    event EpochStarted(
        uint256 indexed _timestamp,
        uint256 _assetAmount,
        uint256 _jonesAssetSupply
    );

    /// emitted when claim and deposit windows are open
    /// @param _timestamp snapshot timestamp (indexed)
    /// @param _assetAmount new vault balance value
    /// @param _jonesAssetSupply jDPX total supply at this time
    event EpochEnded(
        uint256 indexed _timestamp,
        uint256 _assetAmount,
        uint256 _jonesAssetSupply
    );

    /// emitted when whitelist is updated
    /// @param _address whitelisted address (indexed)
    /// @param _amount whitelisted new amount
    event WhitelistUpdate(address indexed _address, uint256 _amount);
}

// ERROR MAPPING:
// {
//   "VE1": "Vault: Address cannot be a zero address",
//   "VE2": "Vault: Invalid amount",
//   "VE3": "Vault: Amount exceeds vault cap",
//   "VE4": "Vault: Insufficient balance",
//   "VE5": "Vault: Already whitelisted",
//   "VE6": "Vault: Address not in whitelist",
//   "VE7": "Vault: Management window is not open",
//   "VE8": "Vault: Management window is  open",
//   "VE9": "Vault: User does not have whitelisting permissions",
// }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library SushiRouterWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// Sells the received tokens for the provided amounts for the last token in the route
    /// Temporary solution until we implement accumulation policy.
    /// @param self the sushi router used to perform the sale.
    /// @param _assetAmounts output amount from selling the tokens.
    /// @param _tokens tokens to sell.
    /// @param _recepient recepient address.
    /// @param _routes routes to sell each token
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp.add(120);
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /// Sells the received tokens for the provided amounts for ETH
    /// Temporary solution until we implement accumulation policy.
    /// @param self the sushi router used to perform the sale.
    /// @param _assetAmounts output amount from selling the tokens.
    /// @param _tokens tokens to sell.
    /// @param _recepient recepient address.
    /// @param _routes routes to sell each token.
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp.add(120);
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    // }
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDPXSSOVV2} from "../../interfaces/IDPXSSOVV2.sol";

library DopexDpxSsovWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant TOKEN = 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55;

    // ============================== Dopex Arb Ssov wrapper interaction ==============================

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of token to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposit was successful.
     */
    function depositSSOV(
        IDPXSSOVV2 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _depositor
    ) public returns (bool) {
        self.deposit(_strikeIndex, _amount, _depositor);
        emit SSOVDeposit(self.currentEpoch(), _strikeIndex, _amount, TOKEN);
        return true;
    }

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of ETH to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposits went through successfully.
     */
    function depositSSOVMultiple(
        IDPXSSOVV2 self,
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts,
        address _depositor
    ) public returns (bool) {
        require(
            _strikeIndices.length == _amounts.length,
            "Arguments Lenght do not match"
        );

        self.depositMultiple(_strikeIndices, _amounts, _depositor);

        for (uint256 i = 0; i < _amounts.length; i++) {
            emit SSOVDeposit(
                self.currentEpoch(),
                _strikeIndices[i],
                _amounts[i],
                TOKEN
            );
        }

        return true;
    }

    /**
     * Buys calls from Dopex SSOV.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of calls to purchase.
     * @param _buyer call buyer
     * @return Whether call purchase went through successfully.
     */
    function purchaseCall(
        IDPXSSOVV2 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _buyer
    ) public returns (bool) {
        (uint256 premium, uint256 totalFee) = self.purchase(
            _strikeIndex,
            _amount,
            _buyer
        );
        emit SSOVCallPurchase(
            self.currentEpoch(),
            _strikeIndex,
            _amount,
            premium,
            totalFee,
            TOKEN
        );
        return true;
    }

    /**
     * Claims deposits and settle calls from Dopex SSOV at the end of an epoch.
     * @param _caller the address seleting the epoch
     * @return Whether settling was successful.
     */
    function settleEpoch(IDPXSSOVV2 self, address _caller)
        public
        returns (bool)
    {
        uint256 epoch = self.currentEpoch();

        // calls
        address[] memory strikeTokens = self.getEpochStrikeTokens(epoch);
        for (uint256 i = 0; i < strikeTokens.length; i++) {
            IERC20 strikeToken = IERC20(strikeTokens[i]);
            uint256 strikeTokenBalance = strikeToken.balanceOf(_caller);
            if (strikeTokenBalance > 0) {
                strikeToken.safeApprove(address(self), strikeTokenBalance);
                self.settle(i, strikeTokenBalance, epoch);
            }
        }

        // deposits
        uint256[] memory vaultDeposits = self.getUserEpochDeposits(
            epoch,
            _caller
        );
        for (uint256 i = 0; i < vaultDeposits.length; i++) {
            if (vaultDeposits[i] > 0) {
                self.withdraw(epoch, i);
            }
        }

        return true;
    }

    // ============================== Events ==============================

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposit amount
     */
    event SSOVDeposit(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        address _token
    );

    /**
     * emitted when new call from SSOV is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount call amount
     * @param _premium call premium
     * @param _totalFee call total fee
     */
    event SSOVCallPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IDPXSSOVV2 {
    function currentEpoch() external view returns (uint256);

    function deposit(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (bool);

    function depositMultiple(
        uint256[] calldata strikeIndices,
        uint256[] calldata amounts,
        address user
    ) external returns (bool);

    function purchase(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256, uint256);

    function settle(
        uint256 strikeIndex,
        uint256 amount,
        uint256 epoch
    ) external returns (uint256 pnl);

    function withdraw(uint256 withdrawEpoch, uint256 strikeIndex)
        external
        returns (uint256[2] memory); // biggest difference

    function getEpochStrikeTokens(uint256 epoch)
        external
        view
        returns (address[] memory);

    function getUserEpochDeposits(uint256 epoch, address user)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJonesAsset is IERC20 {
    /// @dev JonesAsset interface
    function mint(address recipient, uint256 amount) external;

    function giveMinterRole(address account) external;

    function revokeMinterRole(address account) external;

    /// @dev IERC20Burnable interface
    function burnFrom(address account, uint256 amount) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}