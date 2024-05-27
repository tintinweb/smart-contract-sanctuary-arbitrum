// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance < zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "From zero address");
        require(recipient != address(0), "To zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT

/*
    Created by Community Interface for Voting
*/

pragma solidity ^0.8.0;


interface IVendamVaribles {
    /**
    * @notice Sets the minimum fee required for renting in WEI.
    * @dev Only the DAO (Decentralized Autonomous Organization) is allowed to invoke this function.
    * @param newFee The new minimum fee value to be set.
    * Requirements:
    * - The new fee must be between 0.0001 ETH (1e14 WEI) and 1 ETH (1e18 WEI).
    */
    function setMinFee(uint256 newFee) external;

    /**
    * @notice Sets the minimum period of time for renting.
    * @dev Only the DAO is allowed to invoke this function.
    * @param newTime The new minimum rent period value in seconds.
    * Requirements:
    * - The new time must be between 1 hour (3600 seconds) and 30 days (2592000 seconds).
    */
    function setMinRentPeriod(uint256 newTime) external;

    /**
    * @notice Sets the maximum period of time for renting.
    * @dev Only the DAO is allowed to invoke this function.
    * @param newTime The new maximum rent period value in seconds.
    * Requirements:
    * - The new time must be between 31 days (2678400 seconds) and 1 year (31536000 seconds).
    */
    function setMaxRentPeriod(uint256 newTime) external;

    /**
    * @notice Sets the minimum interest rate for renting.
    * @dev Only the DAO is allowed to invoke this function.
    * @param newRate The new minimum interest rate value in basis points (0.1% increments).
    * Requirements:
    * - The new rate must be between 10 (0.1%) and 1000 (10%).
    */
    function setMinInterestRate(uint256 newRate) external;

    /**
    * @notice Sets the maximum interest rate for renting.
    * @dev Only the DAO is allowed to invoke this function.
    * @param newRate The new maximum interest rate value in basis points (0.1% increments).
    * Requirements:
    * - The new rate must be between 5000 (50%) and 100000 (1000%).
    */
    function setMaxInterestRate(uint256 newRate) external;

    /**
    * @notice Sets the grace fee for late rent payments.
    * @dev Only the DAO is allowed to invoke this function.
    * @param newRate The new grace fee value in basis points (0.1% increments).
    * Requirements:
    * - The new rate must be between 500 (5%) and 3000 (30%).
    */
    function setGraceFee(uint256 newRate) external;


}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract PoSAdmin  is IPoSAdmin, Ownable, StringNumbersConstant {
    address public proofOfStorageAddress = address(0);
    address public storagePairTokenAddress = address(0);
    address public contractStorageAddress;
    address public daoContractAddress;
    address public gasTokenAddress;
    address public gasTokenMined;
    
    constructor (address _contractStorageAddress) {
        contractStorageAddress = _contractStorageAddress;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "PoSAdmin.msg.sender != POS");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        proofOfStorageAddress = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
        storagePairTokenAddress = contractStorage.getContractAddressViaName("pairtoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        gasTokenAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        gasTokenMined = contractStorage.getContractAddressViaName("gastoken_mined", NETWORK_ID);
        emit ChangePoSAddress(proofOfStorageAddress);
        _afterSync();
    }

    function _afterSync() internal virtual {}
}

// SPDX-License-Identifier: MIT

/*
* Use Rent token to launch Datakeeper
* Deposit to earn from rent.
* This is Turbo Version (work with setup fees)
* 
* v3.5 Update
* 
* 1. More honest APY for rent and invest
* 2. Auto Rent after Repay
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVendamVaribles.sol";

import "./ERC20Unsafe.sol";
import "./PoSAdmin.sol";

contract NonTransferToken  {
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) public _balances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Renter is NonTransferToken, Ownable {
    constructor ()  NonTransferToken("Rented Storage Gastoken", "rentedTBY") {
    }

    function mint(address account, uint amount) external onlyOwner{
        _mint(account, amount);
    }

    function burn(address account, uint amount) external onlyOwner{
        _burn(account, amount);
    }
}

contract VendamVaribles is PoSAdmin, IVendamVaribles {

    uint256 public  minRentPeriod = 60*60; // 1 hour
    uint256 public  maxRentPeriod = 60*60*24*30; // 3 Months
    
    uint256 public  base_min_rate = 200; // 2%
    uint256 public  base_max_rate = 1000; // 10%

    uint256 public  strong_max_rate = 36500; // 365%


    uint256 public  minFee = 1e16; // 0.01 TBY
    uint256 public  graceFee = 500; // 5% for close or continue Rent

    constructor (address _adm) PoSAdmin(_adm) {sync();}

    // Setup Min Fee for rent in WEI
    function setMinFee(uint256 newFee) external override onlyDAO {
        require(newFee >= 1e14 && newFee <= 1e18, "setMinFee: newFee < 1e14 or > 1e18");
        minFee = newFee;
    }

    // Setup min period of rent (1 hour to 30 days)
    function setMinRentPeriod(uint256 newTime) external override onlyDAO() {
        require(newTime >= 60*60 && newTime <= TIME_30D, "setMinRentPeriod: not  1 hour < newTime > 30 days");
        minRentPeriod = newTime;
    }

    // Setup max period of rent (31 days to 1 year)
    function setMaxRentPeriod(uint256 newTime) external override onlyDAO() {
        require(newTime >= TIME_30D + TIME_1D && newTime <= TIME_1Y, "setMaxRentPeriod: not  1 hour < newTime > 30 days");
        maxRentPeriod = newTime;
    }

    function setMinInterestRate(uint256 newRate) external override onlyDAO() {
        require(newRate >= 10 && newRate <= 799, "setMinInterestRate: not in from 0.1% to 7.99%");
        base_min_rate = newRate;
    }

    function setMaxInterestRate(uint256 newRate) external override onlyDAO() {
        require(newRate >= 800 && newRate <= 2000, "setMaxInterestRate: not in from 8% to 20%");
        base_max_rate = newRate;
    }

    function setGraceFee(uint256 newRate) external override onlyDAO() {
        require(newRate >= 500 && newRate <= 3000, "setGraceFee: not in from 5% to 30%");
        graceFee = newRate;
    }
}

contract StakerV3 is ERC20, VendamVaribles {

    address public rentTokenAddress;
    uint256 public rentCount = 0;

    uint256 constant public UNDIV_85 = 8500; 

    struct rentPosition {
        address owner;
        uint256 lockedReserve;
        uint256 graceReward;
        uint256 deadline;
        uint256 maxFee;
        uint256 rent_period;
    }

    // rentId => Rent
    mapping (uint256 => rentPosition) public rentMap;

    constructor(
        address adminAddress
    ) ERC20("Automated Staked Storage GasToken", "stakedTBY") VendamVaribles(adminAddress){
        Renter rent = new Renter();
        rentTokenAddress = address(rent);
        
        // Initial Stake
        _mint(msg.sender, DECIMALS_18);
    }
    
    function getRentMapRange(uint _from, uint _to) public view returns (rentPosition[] memory) {
        rentPosition[] memory  _returns = new rentPosition[](_to - _from);
        for (uint i = _from; i < _to; i++) {
            _returns[i - _from] = rentMap[i];
        }
        return _returns;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function getFreeReserves() public view returns(uint256) {        
        IERC20 tok = IERC20(gasTokenAddress);
        uint reserves = tok.balanceOf(address(this));
        Renter rentToken = Renter(rentTokenAddress);
        uint utilized = rentToken.totalSupply();

        if (reserves <= utilized) {
            return 0;
        }
        return reserves - utilized;
    }

    function getInterest(uint _amount, uint rent_period) public view returns(uint256) {
        rent_period = max(rent_period, minRentPeriod);
        rent_period = min(maxRentPeriod, rent_period);
        IERC20 tok = IERC20(gasTokenAddress);

        // utilization with new borrow
        uint reserves = tok.balanceOf(address(this));
        Renter rentToken = Renter(rentTokenAddress);
        uint utilized = rentToken.totalSupply()+ _amount;

        uint range_used = utilized * DIV_FEE / reserves + 1;
        uint interestRate = 0;

        /*
            from 0 to UNDIV_85 (85%), fee will from base_min_rate to base_max_rate based on utilization
            from UNDIV_85 to 100%, fee will from base_max_rate to strong_max_rate
        */
        if (range_used < UNDIV_85) {
            interestRate = (range_used * (base_max_rate-base_min_rate) + base_min_rate * DIV_FEE) / UNDIV_85;
        } else {
            interestRate = (range_used * (strong_max_rate-base_max_rate) + base_max_rate * DIV_FEE) / DIV_FEE;
        }
       
        uint interestValue = interestRate * _amount * rent_period / TIME_1Y / DIV_FEE;
        return max(interestValue, minFee);
    }

    function Repay(uint rentId) public {
        rentPosition memory tmp_position = rentMap[rentId];
        require(tmp_position.deadline <= block.timestamp, "Repay: deadline > timestamp");
    
        // Burn Rented Token
        Renter rentToken = Renter(rentTokenAddress);
        rentToken.burn(tmp_position.owner, tmp_position.lockedReserve);  

        // Stake Reward
        _burn(address(this), tmp_position.graceReward);
        _mint(msg.sender, tmp_position.graceReward);
        
        // Flash this rent
        rentMap[rentId] = rentPosition(address(0), 0, 0, 0,0,0);
        rentMap[rentId] = rentMap[rentCount - 1]; // remove from map (if it last, it will already flashed)
        rentCount -= 1;
        uint availInterest = getInterest(tmp_position.lockedReserve, tmp_position.rent_period);

        if (tmp_position.maxFee >= availInterest) {
            IERC20 tok = IERC20(gasTokenAddress);

            // if have balance to pay
            if (tok.balanceOf(tmp_position.owner) >= availInterest
            && tok.allowance(tmp_position.owner, address(this)) >= availInterest) {
                borrowFor(tmp_position.owner, tmp_position.lockedReserve, tmp_position.rent_period, tmp_position.maxFee);
            }
            
        }
    }

    function borrowFor(address _for, uint _amount, uint rent_period, uint max_fee) internal {
        rent_period = max(rent_period, minRentPeriod);
        rent_period = min(rent_period, maxRentPeriod);

        require(_amount <= getFreeReserves(), "Borrow: reserve < _amount");
        uint feeInterest = getInterest(_amount, rent_period);
        require(feeInterest <= max_fee, "Borrow: maxFee < feeInterest");

        IERC20 tok = IERC20(gasTokenAddress);
        uint balanceBefore = tok.balanceOf(address(this));
        tok.transferFrom(_for, address(this), feeInterest);
        uint balanceAfter = tok.balanceOf(address(this));
        uint feeAmount = balanceAfter - balanceBefore;
        require(feeAmount == feeInterest, "Borrow: wrong feeAmount");
        // calc grace fee 
        uint graceFeeGastoken = graceFee * feeAmount / uint256(DIV_FEE);
        
        // Mint Grace Reward to contract
        uint stakedGraceReward = getStakeReturns(graceFeeGastoken, balanceBefore);
        _mint(address(this), stakedGraceReward);

        feeAmount = feeAmount - graceFeeGastoken;
        rentMap[rentCount] = rentPosition(
            _for,
            _amount,
            stakedGraceReward,
            block.timestamp + rent_period,
            max_fee,
            rent_period
        );
        rentCount += 1;

        Renter rentToken = Renter(rentTokenAddress);
        rentToken.mint(_for, _amount);   
    }


    function Borrow(uint _amount, uint rent_period, uint max_fee) public {
        borrowFor(msg.sender, _amount, rent_period, max_fee);
    }

    function set_max_fee(uint rentId, uint max_fee) public {
        rentPosition memory tmp_position = rentMap[rentId];
        require(tmp_position.owner == msg.sender, "only owner of position can change it");
        require(max_fee >= 0, "max fee not positive or 0");
        rentMap[rentId].maxFee = max_fee;
    }

    function getStakeReturns(uint _amount, uint _balanceBefore) public view returns(uint256){
        require(_amount > 0, "getStakeReturns: amount <= 0");
        require(_balanceBefore > 0, "getStakeReturns: _balanceBefore <= 0");
        return totalSupply() * _amount * uint256(DIV_FEE) / _balanceBefore / uint256(DIV_FEE);
    }

    function getUnstakeAmount(uint _amount) public view returns(uint256) {
        IERC20 tok = IERC20(gasTokenAddress);
        uint currentBalance = tok.balanceOf(address(this));
        return uint256(DIV_FEE) * currentBalance * _amount / totalSupply() / uint256(DIV_FEE);
    }

    function stake(uint256 _amount) public {
        IERC20 tok = IERC20(gasTokenAddress);
        uint balanceBefore = tok.balanceOf(address(this));
        tok.transferFrom(msg.sender, address(this), _amount);
        uint balanceAfter = tok.balanceOf(address(this));
        uint pushedAmount = balanceAfter - balanceBefore;
        uint mintAmount = getStakeReturns(pushedAmount, balanceBefore);
        _mint(msg.sender, mintAmount);
    }

    function unstake(uint _amount) public {
        uint stakerBalance = balanceOf(msg.sender);
        require(stakerBalance >= _amount, "unstake: _amount < stakerBalance");
        uint tokAmount =  getUnstakeAmount(_amount);
        require(tokAmount <= getFreeReserves(), "unstake: tokAmount > reserve");
        _burn(msg.sender, _amount);
        IERC20 tok = IERC20(gasTokenAddress);
        tok.transfer(msg.sender, tokAmount);
    }
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   uint public constant NETWORK_ID = 42161; // This is Hardhat network ID, replace it with actual

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
   uint public constant STORAGE_100GB_IN_MB = 102400; // 100 GB;
  
   // nax blocks after proof depends of network, most of them 256 is ok
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   // Polygon Network Settigns
   address public constant PAIR_TOKEN_START_ADDRESS = 0x081Ec4c0e30159C8259BAD8F4887f83010a681DC; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x15968404140CFB148365577D669477E1615557C0; // DeNet Labs Polygon Multisig
   

   // StorageToken Default Vars
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
}