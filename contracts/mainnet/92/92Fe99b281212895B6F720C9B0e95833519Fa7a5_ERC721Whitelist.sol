// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeManager {
    //********************EVENT*******************************//
    event Withdrawal(address payment, address account, uint256 amount);
    event ApproveAdded(address payment, address account, uint256 amount);
    event ApproveReduced(address payment, address account, uint256 amount);

    //********************FUNCTION*******************************//

    /// @dev pay the baseFee
    /// @notice the msg.value should be equal to baseFee
    function payBaseFee() external payable;

    /// @dev approve payment to spender.
    /// @notice  only allowed by owner.
    function addApprove(address payment, address spender, uint256 amount) external;

    /// @notice  only allowed by owner.
    function reduceApprove(address payment, address spender, uint256 amount) external;

    /// @dev set base fee of create a game, the payment is eth
    /// @notice only owner
    function setBaseFee(uint256 amount) external;

    /// @dev set factory to calc fee
    /// @notice only owner, factor<=100
    function setFactor(uint256 factor) external;

    /// @dev withdraw if have enough allowance
    function withdraw(address payment, uint256 amount) external;

    /// @dev calc fee
    function calcFee(uint256 amount) external view returns (uint256);

    function baseFee() external view returns (uint256);

    function getFactor() external view returns (uint256);

    function allowance(address payment, address spender) external view returns (uint256);

    function totalBaseFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGlobalNftDeployer {
    //********************EVENT*******************************//
    event GlobalNftMinted(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);
    event GlobalNftBurned(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);

    //********************FUNCTION*******************************//
    function calcAddr(uint64 originChain, address originAddr) external view returns (address);

    function tokenURI(address globalNft, uint256 tokenId) external view returns (string memory);

    function isGlobalNft(address collection) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Types.sol";
import "./IGlobalNftDeployer.sol";

/**huntnft
 * @title the interface hunt main bridge which is used to receive msg from sub bridge and send withdraw method to sub bridge
 */
interface IHuntBridge is IGlobalNftDeployer {
    //********************EVENT*******************************//
    event NftTransfer(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient
    );
    event NftDepositFinalized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    //withdraw initialized event
    event NftWithdrawInitialized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    // dao event
    event SubBridgeInfoChanged(uint64[] _originChains, address[] _addrs);
    event Paused(bool);

    //********************FUNCTION*******************************//

    /**
     * @dev owener of nft withdraw nft to recipient located at it's src network
     * @param originChain origin chain id of nft
     * @param addr nft address
     * @param tokenId tokenId
     * @param recipient recipient address of nft origin network
     * @param refund refund account who receive the lz refund
     */
    function withdraw(
        uint64 originChain,
        address addr,
        uint256 tokenId,
        address recipient,
        address payable refund
    ) external payable;

    /**
     * @dev set subbridge info lz chainId => subBridge
     * @param _originChains a slice of various origin chainId
     * @param _addrs a slice of subBridge of specific lz chainId
     * @notice only owner
     */
    function setSubBridgeInfo(uint64[] calldata _originChains, address[] calldata _addrs) external;

    /// @return get sub bridge address by lz id
    function getSubBridgeByLzId(uint16 lzId) external view returns (address);

    /// @return get layerzero id by chainId
    function getLzIdByChainId(uint64 chainId) external view returns (uint16);

    /// @return estimate fee for withdraw nft back to origin chain
    function estimateFees(uint64 destChainId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IHuntGameValidator.sol";

/**huntnft
 * @title the interface manage the asset that user deposited, which can be used when hunt game fulfilled user's condition
 * by IHuntGameValidator
 */
interface IHunterAssetManager {
    //********************EVENT*******************************//
    /// @notice if payment is zero, means native token
    event HunterAssetUsed(address indexed _hunter, address _huntGame, address _payment, uint256 _value);
    event HunterAssetDeposited(address indexed _hunter, address _payment, uint256 _value);
    event HunterAssetWithdrawal(address indexed _hunter, address _payment, uint256 _value);
    event HuntGameValidatorChanged(address indexed _hunter, address _huntGameValidator);
    event OfficialHuntGameValidatorChanged(uint8 _type, address _huntGameValidator);

    //********************FUNCTION*******************************//
    /**
     * @dev help a hunter to participate in a hunt game with bullet
     * @param _hunter choose a hunter to try to participate in a hunt game
     * @param _huntGame the hunt game that want to participate in
     * @param _bullet the bullet num try to buy
     * @notice the hunt game should record in huntnft factory;the asset manager will check the hunt using IHuntGameValidator.isHuntGamePermitted,and then
     * need to invoke IHuntGameValidator.afterValidated to change state if needed.
     */
    function hunt(address _hunter, IHuntGame _huntGame, uint64 _bullet) external;

    /**
     * @dev hunter try to deposit payment token to asset manager
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to deposit
     */
    function deposit(address _payment, uint256 _value) external;

    /// @dev same, but support help others to deposit
    function deposit(address _hunter, address _payment, uint256 _value) external;

    /**
     * @dev deposit native token to asset manager
     */
    function deposit() external payable;

    ///@dev same, but help others to deposit
    function deposit(address _hunter) external payable;

    /**
     * dev withdraw token from asset manager, address(0) means native token
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to withdraw
     */
    function withdraw(address _payment, uint256 _value) external;

    /**
     * @dev user set its own hunt game validator to check the hunt game when try to
     * participate in a hunt game.If not set, just use official blue chip validator
     * @param _huntGameValidator the contract that realize the IHuntGameValidator interface
     * @notice all zero address means using official blue chip verifier
     */
    function setHuntGameValidator(IHuntGameValidator _huntGameValidator) external;

    /**
     * @dev set official hunt game validator
     * @param _huntGameValidator used for validate hunt game
     * @notice allowed by owner:
     * - 0: blue chip
     */
    function setOfficialValidator(uint8 _type, IHuntGameValidator _huntGameValidator) external;

    /// @return hunt game validator of hunter
    function getHuntGameValidator(address _hunter) external view returns (IHuntGameValidator);

    function officialValidator(uint8 _type) external view returns (IHuntGameValidator);

    function getBalance(address _hunter, address _payment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IHunterValidator is used for HuntGame to check whether a hunter is allowed to join hunt game.useful for whitelist
 */
interface IHunterValidator {
    /// @dev hunt game may register some info to validator when needed.
    /// @dev the params between register is stored in HuntNFTFactory.tempValidatorParams();
    function huntGameRegister() external;

    /**
     * @dev use validate to check the hunter, revert if check failed
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     * @notice check sender should be hunt game, just use HuntNFTFactory.isHuntGame(msg.sender);
     */
    function validateHunter(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external;

    /**
     * @dev hunt game check whether hunter can hunt on this game,the simply way is just use offline cert for hunter or
     * whitelist or check whether a hunter hold some kind of nft and so on
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     */
    function isHunterPermitted(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntNFTFactory.sol";
import "./IHunterValidator.sol";

struct HunterInfo {
    address hunter;
    uint64 bulletsAmountBefore;
    uint64 bulletNum;
    uint64 totalBullets;
    bool isFromAssetManager;
}

/**huntnft
 * @title interface of HuntGame contract
 */
interface IHuntGame {
    /**
     * @dev NFTStandard, now support standard ERC721, ERC1155
     */
    enum NFTStandard {
        GlobalERC721,
        GlobalERC1155
    }

    enum Status {
        Depositing,
        Hunting,
        Waiting,
        Timeout,
        Unclaimed,
        Claimed
    }

    //********************EVENT*******************************//
    /// emit when hunt game started, allowing hunter to hunt
    event Hunting();

    /// emit when hunter hunt in game
    event Hunted(uint64 hunterIndex, HunterInfo hunterInfo);

    /// emit when all bullet sold out, and wait for VRF
    event Waiting();

    /// emit when timeout, game is over
    event Timeout();

    /// emit when timeout and hunter withdraw asset back
    event HunterWithdrawal(uint64[] hunterIndexes);

    /// emit when NFT claimed to recipient either winner or owner of nft
    event NFTClaimed(address recipient);

    /// emit when VRF arrived, so winner is chosen, but nft and reward of owner is unclaimed
    event Unclaimed();

    /// all claimed, game is over
    event Claimed();

    /// emit when game creator claimed the reward
    event OwnerPaid();

    //********************FUNCTION*******************************//

    /**
     * @dev start hunt game when NFT is indeed owned by hunt game contract
     * @notice anyone can invoke this contract, be sure transfer exactly right contract
     */
    function startHunt() external;

    /**
     * @dev hunter hunt game by buy bullet to this game
     * @param bullet bullet num hunter try to buy
     * @notice only in hunting period and hunter should be permitted
     * if hunt game has hunter validator
     */
    function hunt(uint64 bullet) external payable;

    /// @dev same, can fulfill the payload
    function hunt(address hunter, uint64 bullet, bool _isFromAssetManager, bytes calldata payload) external payable;

    /**
     * @dev buy bullet in native token(ETH), hunter need bullet to hunt nft, just like tickets in raffle
     * @param hunter hunter
     * @param bullet bullet num
     * @param minNum how much bullet at least, tolerate async of action
     * @param isFromAssetManager whether to refund to asset manager
     * @param payload useful for hunter verify extension
     * @notice require :
     * - hunt game do accept native token
     * - hunt game is in hunting period
     */
    function huntInNative(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external payable returns (uint64);

    /// @dev same, but accept erc20
    function hunt(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external returns (uint64);

    /// @dev claim timeout when in hunting period and waiting period
    /// @notice only block.timestamp beyond the ddl and in hunting and waiting period
    function claimTimeout() external;

    /**
     * @dev withdraw bullet when timeout.the asset form HunterAssetManager will return back to HunterAssetManager.Others
     * just return back to users wallet
     * @param _hunterIndexes a set of hunter index prepared to withdraw
     * @notice if hunter already withdraw in provided index, just revert
     */
    function timeoutWithdrawBullets(uint64[] memory _hunterIndexes) external;

    /// @dev withdraw nft to creator when game timeout.The nft deposited from other chain will be returned back.
    /// @notice only in timeout period and the nft should not paid in twice.
    function timeoutWithdrawNFT() external payable;

    /// @dev same but can chose to keep in this network other than withdraw back to origin chain
    function timeoutClaimNFT(bool withdraw) external payable;

    /**
     * @dev claim nft with winner index.The NFT will be transferred to winner by native chain  or bridge.
     * @param _winnerIndex winner index which can get by getWinnerIndex method.
     * @notice only allowed when random num is filled and game is in unclaimed status,and do not try to claim twice
     */
    function claimNft(uint64 _winnerIndex) external payable;

    /// @dev same, but do not withdraw in other chain, just transfer to winner
    function claimNft(uint64 _winnerIndex, bool _withdraw) external payable;

    /**
     * @dev claim hunt game reward to the creator
     * @notice only allowed when in unclaimed status, and do not try to claim twice
     */
    function claimReward() external;

    /// @return get winner index
    /// @notice revert if random num is not filled yet
    function getWinnerIndex() external view returns (uint64);

    /// @return check hunter has the right to hunt in this game
    function canHunt(address hunter, uint64 bullet) external view returns (bool);

    /// @dev same
    function canHunt(address sender, address hunter, uint64 bullet, bytes memory payload) external view returns (bool);

    function factory() external view returns (IHuntNFTFactory);

    function gameId() external view returns (uint64);

    function owner() external view returns (address);

    function validator() external view returns (IHunterValidator);

    function ddl() external view returns (uint64);

    function bulletPrice() external view returns (uint256);

    function totalBullets() external view returns (uint64);

    function getPayment() external view returns (address);

    function nftStandard() external view returns (NFTStandard);

    function nftContract() external view returns (address);

    function tokenId() external view returns (uint256);

    function status() external view returns (Status);

    function tempHunters(
        uint256 index
    )
        external
        view
        returns (
            address hunter,
            uint64 bulletsAmountBefore,
            uint64 bulletNum,
            uint64 totalBullets,
            bool isFromAssetManager
        );

    function randomNum() external view returns (uint256);

    function requestId() external view returns (uint256);

    function winner() external view returns (address);

    function nftPaid() external view returns (bool);

    function ownerPaid() external view returns (bool);

    function leftBullet() external view returns (uint64);

    function estimateFees() external view returns (uint256);

    function userNonce() external view returns (uint256);

    function originChain() external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IHunterValidator.sol";
import "./IHuntGame.sol";
import "./IHuntNFTFactory.sol";

interface IHuntGameDeployer {
    function getPendingGame(address creator) external view returns (address);

    function calcGameAddr(address creator, uint256 nonce) external view returns (address);

    function userNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IHuntGame.sol";

/**huntnft
 * @title hunt game validator is use for hunter's asset in HuntAsseManager to check whether to join a hunt game with bullet
 */
interface IHuntGameValidator is IERC165 {
    /**
     * @dev validate hunt game and may change the status
     * @param _huntGame hunt game contract, the role is already checked before
     * @param _sender sender to want to move asset of hunter
     * @param _hunter hunter
     * @param _bullet  bullet num prepare to buy at that game
     * @notice this function should only be called by hunt asset manager.
     */
    function validateGame(IHuntGame _huntGame, address _sender, address _hunter, uint64 _bullet) external;

    /**
     * @dev this is used for hunter to check the condition of a hunt game that want to join in
     * @param _huntGame hunt game contract that want to consume the hunter's asset, the role aleady checked before
     * @param _sender sender to want to move asset of hunter
     * @param _hunter hunter
     * @param _bullet bullet num prepare to buy at that game
     */
    function isHuntGamePermitted(
        IHuntGame _huntGame,
        address _sender,
        address _hunter,
        uint64 _bullet
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntBridge.sol";
import "./IHunterAssetManager.sol";
import "./IFeeManager.sol";
import "./IHunterValidator.sol";
import "./IHuntGameDeployer.sol";

/**huntnft
 * @title interface of HuntNFTFactory
 */
interface IHuntNFTFactory {
    //********************EVENT*******************************//
    event HuntGameCreated(
        address indexed owner,
        address game,
        uint64 indexed gameId,
        address indexed hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes validatorParams
    );

    //********************FUNCTION*******************************//

    /**
     * @dev create hunt game with native token payment(hunter need eth to buy bullet)
     * @param gameOwner owner of game
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param nftContract nft
     * @param originChain origin chain id of nft
     * @param tokenId token id of nft
     * @param ddl the ddl of game,
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice required:
     * - totalBullets should less than 10_000 and large than 0
     * - ddl should larger than block.timestamp, if not, which is useless
     * - sender should approve nft first if nft is in local network.
     * - sender have enough baseFee paied to feeManager the fee is used for VRF and oracle service(such as help offline-users and so on).
     */
    function createETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /**
     * @dev create hunt game with erc20 payment
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param  nftContract nft
     * @param originChain origin chain id of nft
     * @param payment the erc20 used to buy bullet, now only support usdt
     * @param tokenId token id of nft
     * @param ddl the ddl of game
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice creator should pay the fee to create a game, the fee is used for VRF and oracle service(such as help offline-users).
     * payment should be in whitelist, which prevent malicious attach hunters.
     */
    function createHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /// @dev pay the nft as well
    /// @notice approve factory first
    function createWithPayETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable;

    /**
     * @dev request random words from ChainLink VRF
     * @return requestId the requestId of VRF
     * @notice only hunt game can invoke, and the questId should never be used before
     */
    function requestRandomWords() external returns (uint256 requestId);

    /**
     * @dev hunt game transfer erc20 from a hunter to its game
     * @dev _hunter the hunter who want to participate in hunt game
     * @dev _erc20 erc20 token
     * @dev _amount erc20 amount
     * @notice only allowed by hunt game, which guarantee the logic is right
     */
    function huntGameClaimPayment(address _hunter, address _erc20, uint256 _amount) external;

    function isHuntGame(address _addr) external view returns (bool);

    function getGameById(uint64 _gameId) external view returns (address);

    function isPaymentEnabled(address _erc20) external view returns (bool);

    function getHuntBridge() external view returns (IHuntBridge);

    function getHunterAssetManager() external view returns (IHunterAssetManager);

    function getFeeManager() external view returns (IFeeManager);

    function totalGames() external view returns (uint64);

    function tempValidatorParams() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Consts {
    bytes1 constant FLAG_ERC721 = bytes1(uint8(0));
    bytes1 constant FLAG_ERC1155 = bytes1(uint8(1));

    bytes32 constant BEACON_PROXY_CODE_HASH = 0x3f74a55adef768b97d182c8a1b516d04f0c3e0c4c1b1b534037d7c6104a39a2b;
    address constant CREATE_GAME_RECIPIENT = address(0xAAAA00000000000000000000000000000000aaaa);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Consts.sol";

library Types {
    function toHex(address addr) internal pure returns (string memory) {
        bytes memory ret = new bytes(42);
        uint ptr;
        assembly {
            mstore(add(ret, 0x20), "0x")
            ptr := add(ret, 0x22)
        }
        for (uint160 i = 0; i < 20; i++) {
            uint160 n = (uint160(addr) & (uint160(0xff) << ((20 - 1 - i) * 8))) >> ((20 - 1 - i) * 8);
            uint first = (n / 16);
            uint second = n % 16;
            bytes1 symbol1 = hexByte(first);
            bytes1 symbol2 = hexByte(second);
            assembly {
                mstore(ptr, symbol1)
                ptr := add(ptr, 1)
                mstore(ptr, symbol2)
                ptr := add(ptr, 1)
            }
        }
        return string(ret);
    }

    function hexByte(uint i) internal pure returns (bytes1) {
        require(i < 16, "wrong hex");
        if (i < 10) {
            // number ascii start from 48
            return bytes1(uint8(48 + i));
        }
        // charactor ascii start from 97
        return bytes1(uint8(97 + i - 10));
    }

    function encodeAdapterParams(uint64 extraGas) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes2(0x0001), uint256(extraGas));
    }

    function encodeNftBridgeParams(
        uint256 srcChainId,
        bool isERC1155,
        address addr,
        uint256 tokenId,
        address from,
        address recipient,
        bytes memory extraData
    ) internal pure returns (bytes memory) {
        require(srcChainId < type(uint64).max, "too large chain id");
        bytes1 flag = isERC1155 ? Consts.FLAG_ERC1155 : Consts.FLAG_ERC721;
        return abi.encodePacked(flag, abi.encode(uint64(srcChainId), addr, tokenId, from, recipient, extraData));
    }

    function decodeNftBridgeParams(
        bytes calldata data
    )
        internal
        pure
        returns (
            uint64 srcChainId,
            bool isERC1155,
            address addr,
            uint256 tokenId,
            address from,
            address recipient,
            bytes memory extraData
        )
    {
        bytes1 flag = bytes1(data);
        require(uint8(flag) <= 1);
        isERC1155 = flag == Consts.FLAG_ERC1155;
        (srcChainId, addr, tokenId, from, recipient, extraData) = abi.decode(
            data[1:data.length],
            (uint64, address, uint256, address, address, bytes)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interface/IHunterValidator.sol";
import "../../interface/IHuntGame.sol";

contract ERC721Whitelist is ERC165, IHunterValidator {
    /// huntGame=>erc721
    mapping(address => address) whitelist;
    IHuntNFTFactory factory;

    constructor(IHuntNFTFactory _factory) {
        factory = _factory;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == IHunterValidator.huntGameRegister.selector ||
            interfaceId == IHunterValidator.isHunterPermitted.selector ||
            interfaceId == IHunterValidator.validateHunter.selector ||
            ERC165.supportsInterface(interfaceId);
    }

    function huntGameRegister() public {
        bytes memory params = factory.tempValidatorParams();
        require(params.length == 20, "PARAMS_ERR");
        assert(whitelist[msg.sender] == address(0));
        whitelist[msg.sender] = address(bytes20(params));
    }

    function isHunterPermitted(
        address _game,
        address,
        address _hunter,
        uint64,
        bytes calldata
    ) public view returns (bool) {
        address _nft = whitelist[_game];
        if (_nft == address(0)) {
            revert("NO_NFT_REGISTER");
        }
        return IERC721(_nft).balanceOf(_hunter) > 0;
    }

    function validateHunter(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) public view {
        require(isHunterPermitted(_game, _sender, _hunter, _bullet, _payload), "INVALID_HUNTER");
    }
}