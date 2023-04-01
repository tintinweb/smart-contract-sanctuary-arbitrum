// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xc97ae3d5.
 */
interface IERC3525 is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */ 
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function request(uint256 callbackGasLimit, uint256 confirmations)
        external
        returns (uint256);

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IAlgorithmFacet {

    function calculateLotteryReward(
        uint256 _seed,
        uint256 _count,
        uint256 _bonusPool,
        uint256 _jackPool,
        uint256 _decimals
    )
        external
        view
        returns (
            uint256 result,
            uint256 bonus,
            uint256 jack
        );
    
    function calculateMintAmount(
        uint256 _value,
        uint256 _currencyDecimals,
        uint256 _valuesDecimals
    ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IGameFacet {

    function play(address _player, uint _count) external returns (uint quantity);

    function estimateFee(uint times) external view returns (uint);

    function price() external view returns (uint);

    function currency() external view returns (address);
    
    function voucherRatio() external view returns (uint);

    function valuesTotalSupply() external view returns (uint);

    function premitQuantity() external view returns (uint);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IPlayground {

    event UserMintShares(address indexed _user, uint indexed _slot, uint _amount);
    event UserBurnShares(address indexed _user, uint indexed _slot, uint _amount, uint _value);
    event DividendPoolChange(uint indexed _slot, uint _total, uint _current, uint _value);
    event UserClaimDividend(address indexed _user, uint indexed _slot, uint _value);

    function registerGame(uint _slot, address _game, uint _sharesFunds) external;

    function setEnable(uint _slot, bool _off) external;
    
    function isEnable(uint _slot) external view returns (bool);

    function addDividendPool(uint _slot, uint _amount) external;

    function getUserSharesValue(address _user, uint _slot) external view returns (uint);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./libraries/Structs.sol";

struct AppStorage {

    address currency;
    address randomizer;
    address voucher;

    uint basePot;
    uint bonusPot;
    uint jackPot;
    uint protocolIncome;

    uint totalPayin;
    uint totalPayout;

    uint cyclePrevious;
    uint cycleCurrent;
    uint cycleProgress;

    uint[] intvals;
    uint[] rewards;
    uint[] fibonacci;
    
    uint[50] gaps;

    mapping(uint => LotteryRequest) playerRequest;
    mapping(address => uint) playerExpend;
    mapping(address => uint) playerIncome;
    mapping(address => bool) claim;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@solvprotocol/erc-3525/IERC3525.sol";

import {AppStorage} from "../AppStorage.sol";
import {IGameFacet} from "../../interfaces/lottery/IGameFacet.sol";
import {IAlgorithmFacet} from "../../interfaces/lottery/IAlgorithmFacet.sol";
import {IPlayground} from "../../interfaces/voucher/IPlayground.sol";
import {IRandomizer} from "../../interfaces/IRandomizer.sol";
import {Events} from "../libraries/Events.sol";
import "../libraries/Structs.sol";

contract GameFacet is IGameFacet {
    AppStorage s;

    error Unauthorized();
    error AddressIsZero();
    error InvalidTimes();
    

    function play(address _player, uint256 _times) external returns (uint quantity) {
        // if (msg.sender != s.voucher) revert Unauthorized();
        // if (_player == address(0)) revert AddressIsZero();
        // if (_times > 100) revert InvalidTimes();
        require(msg.sender == s.voucher, "Unauthorized");
        require(_player != address(0), "AddressIsZero");
        require(_times <= 100, "InvalidTimes");

        uint256 gasLimit = _playGasLimit(_times);

        IERC20Metadata usdt = _currency();
        uint256 payin = _price() * _times;

        quantity = IAlgorithmFacet(address(this)).calculateMintAmount(
            s.totalPayin,
            usdt.decimals(),
            IERC3525(s.voucher).valueDecimals()
        );

        uint256 per = payin / 100;
        s.bonusPot = s.bonusPot + per * 78;
        s.jackPot = s.jackPot + per * 12;

        s.playerExpend[_player] += payin;
        s.totalPayin = s.totalPayin + payin;

        s.cycleProgress = s.cycleProgress + _times;

        if (s.cycleProgress >= s.cycleCurrent) {
            s.cycleProgress = s.cycleProgress - s.cycleCurrent;
            (s.cyclePrevious, s.cycleCurrent) = _next(s.cyclePrevious, s.cycleCurrent);

            uint256 value = s.jackPot / 2;
            s.jackPot = s.jackPot - value;

            usdt.approve(msg.sender, value);
            _voucher().addDividendPool(_slot(), value);

            emit Events.JackpotDividends(s.cyclePrevious, s.cycleCurrent, value);
        }

        uint256 id = _randomizer().request(gasLimit);
        LotteryRequest storage req = s.playerRequest[id];
        req.player = msg.sender;
        req.times = _times;
    }

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        // if (msg.sender != s.randomizer) revert Unauthorized();
        require(msg.sender == s.randomizer, "Unauthorized");

        LotteryRequest memory req = s.playerRequest[_id];
        (uint256 result, uint256 bonus, uint256 jack) = IAlgorithmFacet(
            address(this)
        ).calculateLotteryReward(
                uint256(_value),
                req.times,
                s.bonusPot,
                s.jackPot,
                _currency().decimals()
            );

        uint256 bonusTax;
        uint256 jackTax;

        if (bonus > 0) {
            bonusTax = bonus / 50;
            s.bonusPot -= bonus;
        }
        if (jack > 0) {
            jackTax = jack / 50;
            s.jackPot -= jack;
        }

        uint256 payout = (bonus - bonusTax) + (jack - jackTax);
        _currency().transfer(req.player, payout);

        s.playerIncome[req.player] += payout;
        s.totalPayout = s.totalPayout + payout;
        s.protocolIncome = s.protocolIncome + (bonusTax + jackTax);

        emit Events.LotteryResult(req.player, result, bonus, jack);
    }

    function estimateFee(uint times) external view returns (uint) {
        return _randomizer().estimateFee(_playGasLimit(times));
    }

    function _playGasLimit(uint _times) internal pure returns (uint) {
        return 100000 + _times * 3000;
    }

    function _next(uint256 a, uint256 b) internal pure returns (uint256, uint256) {
        return (b, (b * 1191) / 1000 - (b - a));
    }

    function price() external view returns (uint256) {
        return _price();
    }

    function currency() external view returns (address) {
        return s.currency;
    }

    function voucherRatio() external pure returns (uint256) {
        return 10;
    }

    function valuesTotalSupply() external pure returns (uint256) {
        return 21 * 10**10;
    }

    function premitQuantity() external pure returns (uint256) {
        return 21 * 10**9;
    }

    function _currency() internal view returns (IERC20Metadata) {
        return IERC20Metadata(s.currency);
    }

    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(s.randomizer);
    }

    function _voucher() internal view returns (IPlayground) {
        return IPlayground(s.voucher);
    }

    function _price() internal view returns (uint256) {
        return 2 * 10**_currency().decimals();
    }

    function _slot() internal pure returns (uint256) {
        return 100;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library Events {

    event LotteryPlay(address indexed player, uint indexed requestId, uint count);
    event LotteryResult(address indexed player, uint indexed result, uint bonus, uint jack);

    event JackpotDividends(uint previous, uint current, uint value);

    event ClaimAirdrop(address indexed user, uint indexed value);

    event InitLotteryPot(address indexed admin, uint bonusPot, uint jackPot);
    event WithdrawLotteryPot(address indexed admin, address indexed receiver, uint funds);
    
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct LotteryRequest {
    address player;
    uint times;
}