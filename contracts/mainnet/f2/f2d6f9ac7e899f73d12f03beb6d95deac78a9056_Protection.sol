/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;


//  __   __    _                  ___ __ ________
//  \ \ / /_ _| |___  _ _____ _  |_  )  \__ /__ /
//   \ V / _` | / / || |_ / _` |  / / () |_ \|_ \
//    |_|\__,_|_\_\\_,_/__\__,_| /___\__/___/___/


//  / __| |_  ___  __ _ _  _ _ _                 
//  \__ \ ' \/ _ \/ _` | || | ' \                
//  |___/_||_\___/\__, |\_,_|_||_|               
//                |___/                          


// (•_•)
// ( •_•)>⌐■-■
// (⌐■_■)


// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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


// File @openzeppelin/contracts/token/ERC1155/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
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


// File @openzeppelin/contracts/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)
/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
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
}


// File contracts/utility/Permissions.sol
/**
 * @title A generic permissions-management contract for Yakuza 2033.
 *
 * @notice Yakuza 2033
 *             Telegram: t.me/yakuza2033
 *             Twitter:  yakuza2033
 *             App:      yakuza2033.com
 *
 * @author Shogun
 *             Telegram: zeroXshogun
 *             Web:      coinlord.finance
 *
 * @custom:security-contact Telegram: zeroXshogun
 */
contract Permissions is Context, Ownable {
    /// Accounts permitted to modify rules.
    mapping(address => bool) public appAddresses;

    modifier onlyApp() {
        require(appAddresses[_msgSender()] == true, "Caller is not admin");
        _;
    }

    constructor() {}

    function setPermission(address account, bool permitted)
        external
        onlyOwner
    {
        appAddresses[account] = permitted;
    }
}


// File contracts/yakuza/GloryAndInfamy.sol
/**
 * @title An experience tracking contract for Yakuza 2033.
 *
 * @notice Yakuza 2033
 *             Telegram: t.me/yakuza2033
 *             Twitter:  yakuza2033
 *             App:      yakuza2033.com
 *
 * @author Shogun
 *             Telegram: zeroXshogun
 *             Web:      coinlord.finance
 *
 * @custom:security-contact Telegram: zeroXshogun
 */
contract GloryAndInfamy is Permissions
{
    ////
    //// POINTS
    ////

    /// Yakuza members and their heroic prestige.
    mapping(address=> uint256) public glory;

    /// Yakuza members and their villainous prestige.
    mapping(address=> uint256) public infamy;

    ////
    //// INIT
    ////

    constructor() {}

    ////
    //// FUNCTIONS
    ////

    function addGlory(address account, uint256 _glory)
        external
        onlyApp
    {
        glory[account] += _glory;
    }

    function addInfamy(address account, uint256 _infamy)
        external
        onlyApp
    {
        infamy[account] += _infamy;
    }
}


// File contracts/operations/rackets/Staking.sol
interface IGenericToken {
    function decimals() external returns(uint8);
    function mint(address to, uint256 id, uint256 amount) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;
}


/**
 * @title A generic staking contract for Yakuza 2033.
 *
 * @notice Yakuza 2033
 *             Telegram: t.me/yakuza2033
 *             Twitter:  yakuza2033
 *             App:      yakuza2033.com
 *
 * @author Shogun
 *             Telegram: zeroXshogun
 *             Web:      coinlord.finance
 *
 * @custom:security-contact Telegram: zeroXshogun
 */
contract Staking is Permissions,
                    ReentrancyGuard,
                    ERC1155Holder
{
    ////
    //// ADDRESSES
    ////

    /// Token to be deposited.
    IGenericToken public inToken;

    /// NFT ID of inToken.
    uint256 public inTokenID;

    /// Token to be claimed.
    IGenericToken public outToken;

    /// NFT ID of outToken.
    uint256 public outTokenID;

    /// Contract where glory and infamy are tracked.
    GloryAndInfamy public gloryAndInfamy;

    ////
    //// STAKING
    ////

    /// Name of this staking farm.
    string public name;

    /// Points earned per second per staked inToken.
    uint256 public pointsYield;

    /// Points needed to mint 1 outToken.
    uint256 public outTokenPointsCost;

    /// Glory earned per second per staked inToken.
    uint256 public gloryYield;

    /// Infamy earned per second per staked inToken.
    uint256 public infamyYield;

    struct Balance {
        uint256 tokens;
        uint256 points;
        uint256 glory;
        uint256 infamy;
    }
    mapping(address => Balance) public balances;

    /// Timestamp at contract deploy.
    uint256 private _genesisTimestamp;

    /// Timestamp of account's last deposit/withdrawal/claim.
    /// @dev account => UNIX timestamp
    mapping(address => uint256) private _timestamps;

    event Stake(
        address indexed account,
        uint256 indexed amount
    );

    event Withdraw(
        address indexed account,
        uint256 indexed amount
    );

    event Claim(
        address indexed account,
        uint256 indexed amount
    );

    ////
    //// INIT
    ////

    /**
     * Deploy contract.
     * @param _name as string name of staking farm.
     * @param _inToken as address of staked token.
     * @param _inTokenID as uint256 ID of staked token if it's an NFT.
     * @param _outToken as address of yielded token.
     * @param _outTokenID as uint256 ID of yielded token if it's an NFT.
     * @param _gloryAndInfamy as address of GloryAndInfamy contract.
     * @param _pointsYield as uint256 rate per second at which points are earned.
     * @param _gloryYield as uint256 rate per second at which glory is earned.
     * @param _infamyYield as uint256 rate per second at which infamy is are earned.
     */
    constructor(
        string memory _name,
        address _inToken,
        uint256 _inTokenID,
        address _outToken,
        uint256 _outTokenID,
        address _gloryAndInfamy,
        uint256 _pointsYield,
        uint256 _gloryYield,
        uint256 _infamyYield
    ) {
        name = _name;

        inToken = IGenericToken(_inToken);
        inTokenID = _inTokenID;

        outToken = IGenericToken(_outToken);
        outTokenID = _outTokenID;

        gloryAndInfamy = GloryAndInfamy(_gloryAndInfamy);

        pointsYield = _pointsYield;
        gloryYield = _gloryYield;
        infamyYield = _infamyYield;
        outTokenPointsCost = 86400; // Number of seconds in a day.

        _genesisTimestamp = block.timestamp;
    }

    ////
    //// STAKING
    ////

    function getPointsCount(address account)
        private
        view
        returns(uint256)
    {
        uint256 duration = 0;
        if (_timestamps[account] > _genesisTimestamp)
            duration = block.timestamp - _timestamps[account];
        uint256 staked = balances[account].tokens;
        uint256 pointsAfterLastTimestamp = duration * pointsYield * staked;
        return balances[account].points + pointsAfterLastTimestamp;
    }

    function getGloryCount(address account)
        private
        view
        returns(uint256)
    {
        uint256 duration = 0;
        if (_timestamps[account] > _genesisTimestamp)
            duration = block.timestamp - _timestamps[account];
        uint256 staked = balances[account].tokens;
        uint256 gloryAfterLastTimestamp = duration * gloryYield * staked;
        return balances[account].glory + gloryAfterLastTimestamp;
    }

    function getInfamyCount(address account)
        private
        view
        returns(uint256)
    {
        uint256 duration = 0;
        if (_timestamps[account] > _genesisTimestamp)
            duration = block.timestamp - _timestamps[account];
        uint256 staked = balances[account].tokens;
        uint256 infamyAfterLastTimestamp = duration * infamyYield * staked;
        return balances[account].infamy + infamyAfterLastTimestamp;
    }

    function getClaimableOutTokenAmount(address account)
        public
        view
        returns(uint256)
    {
        return (getPointsCount(account) / outTokenPointsCost);
    }

    function updateYieldCounts(address account)
        private
    {
        balances[account].points = getPointsCount(account);
        balances[account].glory = getGloryCount(account);
        balances[account].infamy = getInfamyCount(account);
        _timestamps[account] = block.timestamp;
    }

    function stakeInToken(uint256 amount)
        external
        nonReentrant
    {
        address account = _msgSender();

        updateYieldCounts(account);
        inToken.safeTransferFrom(
            account,
            address(this),
            inTokenID,
            amount,
            ""
        );
        balances[account].tokens += amount;

        emit Stake(account, amount);
    }

    function withdrawInToken(uint256 amount)
        external
        nonReentrant
    {
        address account = _msgSender();
        require(balances[account].tokens >= amount, "Insufficient balance");

        updateYieldCounts(account);
        balances[account].tokens -= amount;
        inToken.safeTransferFrom(
            address(this),
            account,
            inTokenID,
            amount,
            ""
        );

        emit Withdraw(account, amount);
    }

    function claimAll()
        external
        nonReentrant
    {
        address account = _msgSender();

        uint256 amount =  getClaimableOutTokenAmount(account) * (10 ** outToken.decimals());
        updateYieldCounts(account);
        outToken.mint(
            account,
            outTokenID,
            amount
        );

        gloryAndInfamy.addGlory(account, getGloryCount(account));
        gloryAndInfamy.addInfamy(account, getInfamyCount(account));

        balances[account].points = 0;
        balances[account].glory = 0;
        balances[account].infamy = 0;

        emit Claim(account, amount);
    }
}


/**
 * @title A staking contract for Yakuza 2033.
 *
 * @notice Yakuza 2033
 *             Telegram: t.me/yakuza2033
 *             Twitter:  yakuza2033
 *             App:      yakuza2033.com
 *
 * @author Shogun
 *             Telegram: zeroXshogun
 *             Web:      coinlord.finance
 *
 * @custom:security-contact Telegram: zeroXshogun
 */
contract Protection is Staking {
    ////
    //// INIT
    ////

    /**
     * Deploy contract.
     *
     * @param operatives as address of staked token.
     * @param bugs as address of yielded token.
     * @param yakuza as address of Yakuza contract.
     */
    constructor(
        address operatives,
        address bugs,
        address yakuza
    ) Staking(
        "Protection",
        operatives,
        0,
        bugs,
        0,
        yakuza,
        20,
        3,
        0
    ) {}
}