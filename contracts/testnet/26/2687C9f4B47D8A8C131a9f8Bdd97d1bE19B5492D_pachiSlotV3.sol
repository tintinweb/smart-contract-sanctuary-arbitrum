// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

//SPDX-License-Identifier: UNLICENSED
//Copyright (C) 2023 munji - All Rights Reserved

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

pragma solidity 0.8.19;

interface ISupraRouter {
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        uint256 _clientSeed
    ) external returns (uint256);

    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations
    ) external returns (uint256);
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function decimals() external view returns (uint8);
}

contract pachiSlotV3 is Ownable {
    /// VRF - SUPRA ORACLES ///
    address supraAddr;
    uint256 numConfirmations = 1;
    uint8[36] public reel;
    bool public isHalted = false;
    address[] public whitelistedTokens = [
        0x9a6f4C669D1A189EcD7f9c8bf41A79260Fe4aE43, // pachiUSDC
        0x8192dA45b932EFDc56dee24aC205d6Bcf209AA73 // Mock USDC
    ];

    // past requests Id.
    uint256[] public nonces;
    uint256 public lastNonce;
    uint8 public constant RTP = 93; // 93% RTP (accurately 92.32%)

    // events - RequestSent, RequestPaid
    event RequestSent(
        uint256 _nonce,
        address _from,
        address _betToken,
        uint32 _numWords
    ); // 몇개의 랜덤넘버 요청했는지
    event RequestFulfilled(
        uint256 _nonce,
        address _from,
        address _betToken,
        uint256[] _randomNumbers
    ); // 몇개의 랜덤넘버 받았는지
    event RequestPaid(
        uint256 _nonce,
        address _from,
        address _betToken,
        uint256[] _randomNumbers,
        uint256[3][] _reels,
        uint256[] _payouts,
        uint256 _totalPayout,
        uint256 _totalInput
    );

    // requestStructs
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a nonce exists
        bool paid; // whether the request has been paid
        uint256[] randomNumbers;
        address from;
        uint256 wager; // 단위
        address betToken;
        // uint rngCount;
        // other details will be added
    }

    mapping(address => bool) public waitingForResponse;
    mapping(uint256 => RequestStatus) s_requests; // nonce -> RequestStatus
    mapping(uint256 => uint256[2]) payouts;

    constructor(address supraSC) {
        supraAddr = supraSC;

        uint8[2][8] memory symbols = [
            [0, 8],
            [1, 7],
            [2, 6],
            [3, 5],
            [4, 4],
            [5, 3],
            [6, 2],
            [7, 1]
        ];

        // Multiplier payouts of each combination, first place is x2, second place is x3
        // (Multipliers are multiplied by ten as of solidity does not support floating point numbers,
        //  division by ten is done after the payout calculation)
        payouts[0] = [2, 25];
        payouts[1] = [5, 45];
        payouts[2] = [10, 100];
        payouts[3] = [15, 250];
        payouts[4] = [25, 550];
        payouts[5] = [45, 1650];
        payouts[6] = [150, 6550];
        payouts[7] = [1150, 10e4];

        // Populate the reels with symbols with their corresponding number of occurrence
        // (this slot has 3 same reels so we use only 1 reel)
        uint8 counter = 0;
        for (uint8 symbol = 0; symbol < symbols.length; symbol++) {
            for (uint8 occur = 0; occur < symbols[symbol][1]; occur++) {
                reel[counter] = symbols[symbol][0];
                counter++;
            }
        }

        // TODO (하나씩 추가하기)
        // 1.integrate price Oracle -> xPACHI 민팅에 필요 (한방에 될지도, TWAP ORACLE, Supra Oracle 두개 다 써야할지도)
        // 2.referrer id & userNFT id
        // 3.fee split to several addresses
    }

    function spin(
        address _betToken,
        uint256 _wager,
        uint8 rngCount
    ) external returns (uint256 nonce) {
        // require(!waitingForResponse[msg.sender], "Waiting For Response");
        // temporary disabled

        require(!isHalted, "Contract is halted");
        require(_wager > 0, "Bet amount must be greater than 0");
        require(tokenIsWhitelisted(_betToken), "Bet token is not whitelisted");
        require(
            rngCount >= 1 && rngCount <= 100,
            "rngCount must be between 1-100"
        ); // 돌리는 횟수 1~100회

        uint8 betTokenDecimal = IERC20(_betToken).decimals();
        uint256 totalBetAmount = _wager * rngCount;

        // for now, fix wager to 1 USDC
        // require(
        //     _wager == 1 * (10 ** betTokenDecimal),
        //     "Wager must be 1 USDC for now"
        // );
        require(
            _wager >= 1 * (10 ** betTokenDecimal) &&
                _wager <= 100 * (10 ** betTokenDecimal),
            "_wager must be in range of 1-100 USDC"
        );

        require(
            IERC20(_betToken).allowance(msg.sender, address(this)) >=
                totalBetAmount,
            "Bet token allowance is not enough"
        );
        require(
            IERC20(_betToken).balanceOf(address(this)) >=
                totalBetAmount * 10000, //theoretical maximum
            "Slot balance is not enough, please contact the owner"
        );

        // bool success = IERC20(_betToken).transferFrom(
        //     msg.sender,
        //     address(this),
        //     totalBetAmount
        // );
        // require(success, "Transfer failed for betting tokens");

        waitingForResponse[msg.sender] = true;

        nonce = ISupraRouter(supraAddr).generateRequest(
            "callbackSpin(uint256,uint256[])",
            rngCount,
            numConfirmations,
            9918 // clientSeed
        );
        s_requests[nonce] = RequestStatus({
            fulfilled: false,
            exists: true,
            paid: false,
            randomNumbers: new uint256[](rngCount),
            from: msg.sender,
            wager: _wager,
            betToken: _betToken
            // rngCount: rngCount
        });

        nonces.push(nonce);
        lastNonce = nonce;

        // event
        emit RequestSent(nonce, msg.sender, _betToken, rngCount);
    }

    function callbackSpin(
        uint256 _nonce,
        uint256[] calldata _randomNumbers
    ) external {
        require(
            msg.sender == supraAddr,
            "only supra router can call this function"
        );
        require(s_requests[_nonce].exists, "request not found");
        require(!s_requests[_nonce].fulfilled, "request already fulfilled");

        s_requests[_nonce].fulfilled = true;
        s_requests[_nonce].randomNumbers = _randomNumbers;

        emit RequestFulfilled(
            _nonce,
            s_requests[_nonce].from,
            s_requests[_nonce].betToken,
            _randomNumbers
        );

        executePayout(
            _nonce,
            s_requests[_nonce].wager,
            s_requests[_nonce].betToken,
            s_requests[_nonce].from,
            _randomNumbers
        );

        waitingForResponse[s_requests[_nonce].from] = false;
    }

    function executePayout(
        uint256 _nonce,
        uint256 _wager,
        address _tokenAddress,
        address _from, // indicates user address
        uint256[] memory _randomNumbers
    ) internal {
        require(!s_requests[_nonce].paid, "request already paid");
        // reels array & payout array

        uint256[3][] memory _reels = new uint256[3][](_randomNumbers.length);
        uint256[] memory _payouts = new uint256[](_randomNumbers.length);
        uint256 _totalPayout = 0;
        uint256 _totalInput = _wager * _randomNumbers.length;

        for (uint8 i = 0; i < _randomNumbers.length; i++) {
            uint256 r1 = reel[(_randomNumbers[i] % 100) % 36];
            uint256 r2 = reel[((_randomNumbers[i] % 10000) / 100) % 36];
            uint256 r3 = reel[((_randomNumbers[i] % 1000000) / 10000) % 36];

            uint256 payout = 0;

            // Checks if the symbols on reel 1 and 2 are the same
            if (r1 == r2) {
                // "pos" indicates on which position is the multiplier on "payouts" array
                uint8 pos = 0;
                // Checks if the symbols on reel 2 and 3 are the same and update pos to the corresponding position
                if (r2 == r3) pos = 1;
                payout = (_wager * payouts[r1][pos]) / 10;
            }

            _reels[i] = [r1, r2, r3];
            _payouts[i] = payout;
            _totalPayout += payout;
        }

        bool success1 = IERC20(_tokenAddress).transferFrom(
            _from,
            address(this),
            _totalInput
        );
        require(success1, "Transfer failed for betting tokens");

        s_requests[_nonce].paid = true;
        bool success2 = IERC20(_tokenAddress).transfer(_from, _totalPayout); // send payout to user
        require(success2, "Transfer failed for payout token");

        // fee split should comes here (just send to split contract)
        // code for managing xPACHI claimable amount should comes here

        emit RequestPaid(
            _nonce,
            _from,
            _tokenAddress,
            _randomNumbers,
            _reels,
            _payouts,
            _totalPayout,
            _totalInput
        );
    }

    // TODO:function spinWithNativeToken

    function getRequestStatus(
        uint256 _nonce
    ) external view returns (bool fulfilled, uint256[] memory randomNumbers) {
        require(s_requests[_nonce].exists, "request not found");
        RequestStatus memory request = s_requests[_nonce];
        return (request.fulfilled, request.randomNumbers);
    }

    // tokenIsWhitelisted
    function tokenIsWhitelisted(address token) internal view returns (bool) {
        for (uint256 i = 0; i < whitelistedTokens.length; i++) {
            if (whitelistedTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    // emergency withdraw & functions for Owner
    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        require(
            token != address(0),
            "Cannot withdraw native token, use withdrawNative()"
        );

        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawNative(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC721(address token, uint256 tokenId) external onlyOwner {
        IERC721(token).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawERC1155(
        address token,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    function setHalt(bool _isHalted) external onlyOwner {
        isHalted = _isHalted;
    }

    function setSupraAddr(address _supraAddr) external onlyOwner {
        supraAddr = _supraAddr;
    }

    function setNumConfirmations(uint256 _numConfirmations) external onlyOwner {
        numConfirmations = _numConfirmations;
    }

    receive() external payable {}
}