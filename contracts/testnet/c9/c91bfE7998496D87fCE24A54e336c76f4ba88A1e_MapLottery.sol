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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 is IERC165 {
    /** 
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IMapAuthority {

    function pushAdmin(address target_, address nestConfigurator_, bool enable_) external;

    function pushConfigurator(address target_, address nestConfigurator_, bool enable_) external;

    function pushVault(address target_, address nestConfigurator_, bool enable_) external;

    function pushExecutor(address target_, address nestConfigurator_, bool enable_) external;

    function updateEnable(address target_, bool enable_) external;

    function admin(address target_, address user_) external view returns (bool);

    function configurator(address target_, address user_) external view returns (bool);

    function vault(address target_, address user_) external view returns (bool);

    function executor(address target_, address user_) external view returns (bool);

    function enable(address target_) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;


interface IMapLottery {
    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers) external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds
    ) external;

    /**
     * @notice Close lottery
     * @dev Callable by operator
     */
    function closeLottery() external;

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(bool _autoInjection) external;


    /**
     * @notice Start the lottery
     * @dev Callable by operator
     */
    function startLottery(uint cycle_) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
    external
    view
    returns (
        uint256[] memory,
        uint32[] memory,
        bool[] memory,
        uint256
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../libs/MapStructs.sol";

interface IMapMSFT {

    struct TokenView {
        uint256 tokenId;
        uint256 iBId;
        // 邀请人id
        uint256 inviterId;
        // MSFT等级
        uint32 level;
        // 0 普通用户,1 代理用户,3...
        uint8 tokenType;
        // MSFT是否可以转移
        bool transferable;
        address owner;
        address approved;
    }

    function mint(
        address to_,
        uint256 inviterId_,
        uint32 level_,
        uint8 tokenType_,
        bool transferable_,
        uint256 iBId_,
        uint256[] memory iBIds_,
        uint256 slotIndex_,
        uint256 value_
    ) external payable;

    function updateSlot(
        uint256 slotIndex_,
        bool update_,
        bool transferable_,
        bool isToken_,
        address tokenAddress_,
        address vaultAddress_,
        string memory name_
    ) external payable;

    function mintValue(uint256 tokenId_, uint256 slotIndex_, uint256 value_) external payable;

    function mintValue(uint256 tokenId_, address tokenAddress_, uint256 value_) external payable;

    function burnValue(uint256 tokenId_, uint256 slotIndex_, uint256 value_) external payable;

    function burnValue(uint256 tokenId_, address tokenAddress_, uint256 value_) external payable;

    function burn(uint256 tokenId_) external payable;

    function register(
        address to_,
        uint inviterId_,
        uint32 level_,
        uint8 tokenType_,
        bool transferable_,
        bool iBRegister
    ) external payable returns (uint256 newId);

    function selectSlot(address tokenAddress) external view returns (uint256);

    function listSlots() external view  returns (MapStructs.Slot[] memory);

    function tokenView(uint256 tokenId_) external view returns (TokenView memory);

    function tokenInfo(uint256 tokenId_) external view returns (MapStructs.TokenData memory);

    function ownedTokens(address owner_) external view returns (uint256[] memory);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
interface IMSFT is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _slotIndex The slot index to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 indexed _slotIndex, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _slotIndex The slot to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, uint256 indexed _slotIndex, address indexed _operator, uint256 _value);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals(uint256 _slotIndex) external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @param _slotIndex The slot for which to query the balance
     * @return The value of `_slotIndex`
     */
    function balanceOf(uint256 _tokenId, uint256 _slotIndex) external view returns (uint256);

    /**
  * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @param _tokenAddress _tokenAddress
     * @return The value of `_slotIndex`
     */
    function balanceOf(uint256 _tokenId, address _tokenAddress) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _slotIndex The slot to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        uint256 _slotIndex,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _slotIndex The slot for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, uint256 _slotIndex, address _operator) external view returns (uint256);

    /// @dev slot转账
    /// @param _fromTokenId 发起者的MSFT ID
    /// @param _toTokenId 接收者的MSFT ID
    /// @param _slotIndex slot的下标
    /// @param _value 转账的数量
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slotIndex,
        uint256 _value
    ) external payable;

    /// @dev slot转账 根据token地址得到slot进行转账
    /// @param _fromTokenId 发起者的MSFT ID
    /// @param _toTokenId 接收者的MSFT ID
    /// @param _tokenAddress slot的token地址
    /// @param _value 转账的数量
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        address _tokenAddress,
        uint256 _value
    ) external payable;

    /// @dev slot-erc20转账 直接转到EOA钱包
    /// @param _fromTokenId 发起者的MSFT ID
    /// @param _toAddress 接收者的钱包地址
    /// @param _slotIndex slot的下标
    /// @param _value 转账的数量
    function transferFrom(
        uint256 _fromTokenId,
        address _toAddress,
        uint256 _slotIndex,
        uint256 _value
    ) external payable;

    /// @dev slot-erc20转账 直接转到EOA钱包
    /// @param _fromTokenId 发起者的MSFT ID
    /// @param _toAddress 接收者的钱包地址
    /// @param _tokenAddress slot的token地址
    /// @param _value 转账的数量
    function transferFrom(
        uint256 _fromTokenId,
        address _toAddress,
        address _tokenAddress,
        uint256 _value
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber() external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

library MapStructs {
    struct TokenData {
        uint256 id;

        // 直接代理ID,如果是代理SFT则为自己的ID
        uint256 iBId;
        // 邀请人id
        uint256 inviterId;
        // 我的用户id:普通用户记录直接邀请用户，代理记录整个邀请用户树
        uint256[] inviteeIds;
        // 我的上级代理IDs,包括我自己ID,针对代理SFT
        // A1-B1-C1
        uint256[] iBIds;
        // 我的下级代理IDS
        uint256[] nextIBIds;

        // MSFT等级 1-3 普通用户1-n，代理用户 1-n 级
        uint32 level;
        // 0 普通用户,1 代理用户,3...
        uint8 tokenType;
        // MSFT是否可以转移
        bool transferable;

        address owner;
        address approved;
    }

    struct Slot {
        // slot资产是否可以转移
        bool transferable;
        // 是否是代币资产：积分、代币资产
        bool isToken;
        address tokenAddress;
        // 金库地址
        address vaultAddress;
        string name;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IMapAuthority.sol";

    error UNAUTHORIZED();
    error DISABLED();
    error AUTHORITY_INITIALIZED();

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract MapAccessControlled {

    /* ========== STATE VARIABLES ========== */

    IMapAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IMapAuthority authority_) {
        authority = authority_;
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyConfigurator() {
        _onlyConfigurator();
        _;
    }

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    modifier onlyExecutor() {
        _onlyExecutor();
        _;
    }

    modifier onlyEnable() {
        _onlyEnable();
        _;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IMapAuthority newAuthority_) internal {
        if (authority != IMapAuthority(address(0))) revert AUTHORITY_INITIALIZED();
        authority = newAuthority_;
    }

    function setAuthority(IMapAuthority newAuthority_) external {
        _onlyAdmin();
        authority = newAuthority_;
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyAdmin() internal view {
        if (!(authority.admin(address(this), msg.sender) || authority.admin(address(authority), msg.sender))) revert UNAUTHORIZED();
    }

    function _onlyConfigurator() internal view {
        if (!authority.configurator(address(this), msg.sender)) revert UNAUTHORIZED();
    }

    function _onlyVault() internal view {
        if (!authority.vault(address(this), msg.sender)) revert UNAUTHORIZED();
    }

    function _onlyExecutor() internal view {
        if (!authority.executor(address(this), msg.sender)) revert UNAUTHORIZED();
    }

    function _onlyEnable() internal view {
        if (!authority.enable(address(this))) revert DISABLED();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/IMapLottery.sol";
import "./interfaces/IMSFT.sol";
import "./interfaces/IMapMSFT.sol";
import "./MapAccessControlled.sol";

    error NO_USER_SFT();

/** @title 彩票
 * @notice 合约需持有SFT
 */
contract MapLottery is ReentrancyGuard, IMapLottery, MapAccessControlled {
    // 用户SFT的类型
    uint256 constant public USER_MSFT_TYPE = 0;

    uint256 public treasuryMSFTId;
    // 彩票奖池持有的SFT-ID
    uint256 public selfMSFTId;
    // 购买彩票的slot
    uint256 public slotIndex;

    // 彩票期号ID
    uint256 public currentLotteryId;
    // 当前票号累加递增
    uint256 public currentTicketId;
    // 每次购买和领奖的最大数量，避免交易超限
    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicket = 100 ether;
    uint256 public minPriceTicket = 10 ether;
    // 滚存奖金
    uint256 public pendingInjectionNextLottery;

    // 最小周期
    uint256 public constant MIN_LENGTH_LOTTERY = 5 minutes; // 4 hours
    // 最大周期
    uint256 public constant MAX_LENGTH_LOTTERY = 2 days + 5 minutes; // 2 days
    // 手续费
    uint256 public constant MAX_TREASURY_FEE = 3000; // 30%
    // 彩票价格
    uint256 public priceTicket = 100 ether;
    // 彩票各等级奖励百分比
    uint256[6] public rewardsBreakdown = [200, 300, 500, 1500, 2500, 5000];
    // 手续费
    uint256 public treasuryFee = 0;
    // 每期彩票周期
    uint256 public cycle = 3300;

    IMSFT public sftToken;
    IRandomNumberGenerator public randomGenerator;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicket;               // 每份彩票价格
        uint256[6] rewardsBreakdown;       // 各等级奖励百分比 相加==10000
        uint256 treasuryFee;               // 金库手续费 500: 5% // 200: 2% // 50: 0.5%
        uint256[6] amountPerBracket;       // 各等级奖励数量
        uint256[6] countWinnersPerBracket; // 每等级的中将人数
        uint256 firstTicketId;             // 本期起始彩票ID
        uint256 firstTicketIdNextLottery;  // 本期结束彩票ID
        uint256 amountCollected;           // 本期彩票奖池数量
        uint32 finalNumber;                // 本期中奖编号
    }

    struct Ticket {
        uint32 number; // 彩票ID
        address owner; // 持有者
    }

    // 每期彩票数据
    mapping(uint256 => Lottery) private _lotteries;
    // 所有彩票持有数据
    mapping(uint256 => Ticket) private _tickets;
    // 计算
    mapping(uint32 => uint32) private _bracketCalculator;

    // 每期彩票中将人数计算,累积
    mapping(uint256 => mapping(uint32 => uint256)) private _numberTicketsPerLotteryId;

    //  保存用户每期彩票购买的彩票
    mapping(address => mapping(uint256 => uint256[])) private _userTicketIdsPerLotteryId;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId, uint256 firstTicketIdNextLottery);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicket,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(uint256 indexed lotteryId, uint256 finalNumber, uint256 countWinningTickets);
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchase(address indexed buyer, uint256 indexed tokenId, uint256 indexed lotteryId, uint256 numberTickets, uint256 amount);
    event TicketsClaim(address indexed claimer, uint256 indexed tokenId, uint256 amount, uint256 indexed lotteryId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _sftTokenAddress: sft合约地址
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(address _sftTokenAddress, address _randomGeneratorAddress, address authority_) MapAccessControlled(IMapAuthority(authority_)){
        sftToken = IMSFT(_sftTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        // Initializes a mapping
        _bracketCalculator[0] = 1;
        _bracketCalculator[1] = 11;
        _bracketCalculator[2] = 111;
        _bracketCalculator[3] = 1111;
        _bracketCalculator[4] = 11111;
        _bracketCalculator[5] = 111111;
    }

    /**
     * @notice 购买当前彩票
     * @param _lotteryId 彩票期号
     * @param _ticketNumbers  1000000 - 1999999 1000123
     */
    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers)
    external
    override
    notContract
    nonReentrant
    onlyEnable
    {
        require(_ticketNumbers.length != 0, "No ticket specified");
        require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");

        require(_lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
        require(block.timestamp < _lotteries[_lotteryId].endTime, "Lottery is over");

        uint _fromTokenId = _userSFTTokenId(msg.sender);

        // 计算需要的SLOT
        uint256 amountToTransfer = _lotteries[_lotteryId].priceTicket * _ticketNumbers.length;

        // SLOT转账
        sftToken.transferFrom(_fromTokenId, selfMSFTId, slotIndex, amountToTransfer);

        // 增加当期彩票奖池数量
        _lotteries[_lotteryId].amountCollected += amountToTransfer;

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint32 thisTicketNumber = _ticketNumbers[i];

            require((thisTicketNumber >= 1000000) && (thisTicketNumber <= 1999999), "Outside range");

            // 这里保存每个彩票拆分如：彩票编号123456  1000003
            _numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
            _numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
            _numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
            _numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
            _numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
            _numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;

            // 保存每个用户当期购买的彩票ID
            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);
            // 保存彩票映射
            _tickets[currentTicketId] = Ticket({number : thisTicketNumber, owner : msg.sender});

            // 递增彩票ID
            currentTicketId++;
        }

        emit TicketsPurchase(msg.sender, _fromTokenId, _lotteryId, _ticketNumbers.length, amountToTransfer);
    }

    /**
     * @notice 领取中奖的彩票
     * @param _lotteryId 彩票期号
     * @param _ticketIds 彩票IDs
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds
    ) external override notContract nonReentrant onlyEnable {
        require(_ticketIds.length != 0, "Length must be >0");
        require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(_lotteries[_lotteryId].status == Status.Claimable, "Lottery not claimable");
        uint _toTokenId = _userSFTTokenId(msg.sender);

        // 奖金的数量
        uint256 rewardToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {

            uint256 thisTicketId = _ticketIds[i];

            require(_lotteries[_lotteryId].firstTicketIdNextLottery > thisTicketId, "TicketId too high");
            require(_lotteries[_lotteryId].firstTicketId <= thisTicketId, "TicketId too low");
            require(msg.sender == _tickets[thisTicketId].owner, "Not the owner");

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            for (uint32 j = 0; j < 6; j++) {
                uint256 rewardForTicketId = _calculateRewardsForTicketId(_lotteryId, thisTicketId, j);
                if (rewardForTicketId == 0) break;
                rewardToTransfer += rewardForTicketId;
            }
        }

        if (rewardToTransfer > 0) {
            sftToken.transferFrom(selfMSFTId, _toTokenId, slotIndex, rewardToTransfer);
        }

        emit TicketsClaim(msg.sender, _toTokenId, rewardToTransfer, _lotteryId, _ticketIds.length);
    }

    /**
     * @notice 关闭当期彩票
     * @dev Callable by operator
     */
    function closeLottery() external override nonReentrant onlyEnable {
        require(_lotteries[currentLotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp > _lotteries[currentLotteryId].endTime, "Lottery not over");
        _lotteries[currentLotteryId].firstTicketIdNextLottery = currentTicketId;

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber();

        _lotteries[currentLotteryId].status = Status.Close;

        emit LotteryClose(currentLotteryId, currentTicketId);
    }

    /**
     * @notice 开放彩票，结算后彩票可以领取
     * @param _autoInjection: 滚存奖金 = true
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(bool _autoInjection)
    external
    override
    nonReentrant
    onlyEnable
    {
        require(_lotteries[currentLotteryId].status == Status.Close, "Lottery not close");
        require(currentLotteryId == randomGenerator.viewLatestLotteryId(), "Numbers not drawn");

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        uint32 finalNumber = randomGenerator.viewRandomResult();


        // Calculate the amount to share post-treasury fee
        uint256 amountToShareToWinners = (
        ((_lotteries[currentLotteryId].amountCollected) * (10000 - _lotteries[currentLotteryId].treasuryFee))
        ) / 10000;

        // Initializes the amount to withdraw to treasury
        uint256 amountToWithdrawToTreasury;

        // Calculate prizes in CAKE for each bracket by starting from the highest one
        for (uint32 i = 0; i < 6; i++) {
            uint32 j = 5 - i;
            uint32 transformedWinningNumber = _bracketCalculator[j] + (finalNumber % (uint32(10) ** (j + 1)));

            _lotteries[currentLotteryId].countWinnersPerBracket[j] =
            _numberTicketsPerLotteryId[currentLotteryId][transformedWinningNumber];

            // A. If number of users for this _bracket number is superior to 0
            if (
                (_numberTicketsPerLotteryId[currentLotteryId][transformedWinningNumber]) != 0
            ) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (_lotteries[currentLotteryId].rewardsBreakdown[j] != 0) {
                    _lotteries[currentLotteryId].amountPerBracket[j] =
                    ((_lotteries[currentLotteryId].rewardsBreakdown[j] * amountToShareToWinners) /
                    (_numberTicketsPerLotteryId[currentLotteryId][transformedWinningNumber])) /
                    10000;

                }
                // A. No CAKE to distribute, they are added to the amount to withdraw to treasury address
            } else {
                _lotteries[currentLotteryId].amountPerBracket[j] = 0;

                amountToWithdrawToTreasury +=
                (_lotteries[currentLotteryId].rewardsBreakdown[j] * amountToShareToWinners) /
                10000;
            }
        }

        // Update internal statuses for lottery
        _lotteries[currentLotteryId].finalNumber = finalNumber;
        _lotteries[currentLotteryId].status = Status.Claimable;

        if (_autoInjection) {
            pendingInjectionNextLottery += amountToWithdrawToTreasury;
            amountToWithdrawToTreasury = 0;
        }

        amountToWithdrawToTreasury += (_lotteries[currentLotteryId].amountCollected - amountToShareToWinners);

        if (amountToWithdrawToTreasury > 0) {
            sftToken.transferFrom(selfMSFTId, treasuryMSFTId, slotIndex, amountToWithdrawToTreasury);
        }

        emit LotteryNumberDrawn(currentLotteryId, finalNumber, _numberTicketsPerLotteryId[currentLotteryId][_bracketCalculator[0] + (finalNumber % 10)]);
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external onlyConfigurator {
        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.Claimable),
            "Lottery not in claimable"
        );

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber();

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice 修改彩票合约的SFT
     * @param _selfMSFTId: SFT的ID
     */
    function setSelfMSFTId(uint256 _selfMSFTId) external onlyConfigurator {
        address owner = sftToken.ownerOf(_selfMSFTId);
        require(owner == address(this), "SFT owner!");
        selfMSFTId = _selfMSFTId;
    }

    function deposit(uint256 _amount) external onlyVault {
        require(_lotteries[currentLotteryId].status != Status.Claimable, "Lottery is Claimable");

        uint _toTokenId = _userSFTTokenId(msg.sender);
        sftToken.transferFrom(_toTokenId, selfMSFTId, slotIndex, _amount);
        _lotteries[currentLotteryId].amountCollected += _amount;
    }

    /**
    * @notice 修改彩票合约的支付的SLOT
     * @param _slotIndex: slot下标
     */
    function setSlotIndex(uint256 _slotIndex) external onlyConfigurator {
        require(_slotIndex > 0, '_slotIndex!');
        slotIndex = _slotIndex;
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     */
    function startLottery(uint cycle_) external override onlyEnable {
        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );
        currentLotteryId++;

        _lotteries[currentLotteryId] = Lottery({
        status : Status.Open,
        startTime : block.timestamp,
        endTime : block.timestamp + cycle_,
        priceTicket : priceTicket,
        rewardsBreakdown : rewardsBreakdown,
        treasuryFee : treasuryFee,
        amountPerBracket : [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
        countWinnersPerBracket : [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
        firstTicketId : currentTicketId,
        firstTicketIdNextLottery : currentTicketId,
        amountCollected : pendingInjectionNextLottery,
        finalNumber : 0
        });

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            block.timestamp + cycle_,
            priceTicket,
            currentTicketId,
            pendingInjectionNextLottery
        );

        pendingInjectionNextLottery = 0;
    }

    /**
     * @notice Set ticket price upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicket: minimum price of a ticket
     * @param _maxPriceTicket: maximum price of a ticket
     */
    function setMinAndMaxTicketPriceInCake(uint256 _minPriceTicket, uint256 _maxPriceTicket)
    external
    onlyConfigurator
    {
        require(_minPriceTicket <= _maxPriceTicket, "minPrice must be < maxPrice");

        minPriceTicket = _minPriceTicket;
        maxPriceTicket = _maxPriceTicket;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyConfigurator {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set treasury
     * @dev Only callable by owner
     * @param _treasuryMSFTId: address of the treasury
     */
    function setTreasuryMSFTId(uint _treasuryMSFTId) external onlyConfigurator {
        require(_treasuryMSFTId != 0, "Cannot be zero address");
        treasuryMSFTId = _treasuryMSFTId;
    }


    function setTicketConfig(
        uint256 _priceTicket,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee,
        uint256 _cycle
    ) external onlyConfigurator {
        require(
            (_priceTicket >= minPriceTicket) && (_priceTicket <= maxPriceTicket),
            "Outside of limits"
        );

        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

        require(
            (_rewardsBreakdown[0] +
            _rewardsBreakdown[1] +
            _rewardsBreakdown[2] +
            _rewardsBreakdown[3] +
            _rewardsBreakdown[4] +
            _rewardsBreakdown[5]) <= 10000,
            "Rewards must equal 10000"
        );

        require(
            (_cycle > MIN_LENGTH_LOTTERY) && (_cycle < MAX_LENGTH_LOTTERY),
            "Lottery length outside of range"
        );

        priceTicket = _priceTicket;
        rewardsBreakdown = _rewardsBreakdown;
        treasuryFee = _treasuryFee;
        cycle = _cycle;
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
    external
    view
    returns (uint32[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) external view returns (uint256) {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
            (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _calculateRewardsForTicketId(_lotteryId, _ticketId, _bracket);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
    external
    view
    override
    returns (
        uint256[] memory,
        uint32[] memory,
        bool[] memory,
        uint256
    )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice 计算彩票的奖金
     * @param _lotteryId: 彩票当期ID
     * @param _ticketId: 彩票ID
     * @param _bracket: 彩票命中位数
     */
    function _calculateRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) internal view returns (uint256) {
        // Retrieve the winning number combination
        uint32 winningTicketNumber = _lotteries[_lotteryId].finalNumber;

        // Retrieve the user number combination from the ticketId
        uint32 userNumber = _tickets[_ticketId].number;

        // Apply transformation to verify the claim provided by the user is true
        uint32 transformedWinningNumber = _bracketCalculator[_bracket] +
        (winningTicketNumber % (uint32(10) ** (_bracket + 1)));

        uint32 transformedUserNumber = _bracketCalculator[_bracket] + (userNumber % (uint32(10) ** (_bracket + 1)));

        // Confirm that the two transformed numbers are the same, if not throw
        if (transformedWinningNumber == transformedUserNumber) {
            return _lotteries[_lotteryId].amountPerBracket[_bracket];
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /// 获取用户SFT的ID
    function _userSFTTokenId(address owner) internal view returns (uint){
        uint256[] memory tokens = IMapMSFT(address(sftToken)).ownedTokens(owner);
        uint length = tokens.length;
        require(length > 0, 'No SFT');

        for (uint i = 0; i < length; i++) {
            uint8 tokenType = IMapMSFT(address(sftToken)).tokenView(tokens[i]).tokenType;
            if (tokenType == USER_MSFT_TYPE) return tokens[i];
        }
        revert NO_USER_SFT();
    }
}