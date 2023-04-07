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

contract Basic {
    address public immutable owner;
    mapping(address => bool) private isMod;
    bool public isPause = false;
    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }
    modifier onlyMod() {
        require(isMod[msg.sender] || msg.sender == owner, "Must be mod");
        _;
    }

    modifier notPause() {
        require(!isPause, "Must be not pause");
        _;
    }

    function addMod(address _mod) public onlyOwner {
        if (_mod != address(0x0)) {
            isMod[_mod] = true;
        }
    }

    function removeMod(address _mod) public onlyOwner {
        isMod[_mod] = false;
    }

    function changePause(uint256 _change) public onlyOwner {
        isPause = _change == 1;
    }

    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGene {
    function getStatus(uint256 _id) external view returns (uint256);

    function plants(uint256 index)
        external
        view
        returns (
            uint256 types,
            uint256 quality,
            uint256 performance,
            uint256 status
        );

    function change(uint256 _id, uint256[4] calldata _stats) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicAuth.sol";
import "./interfaces/IGene.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace is Basic {
    IERC721 public nft;
    IGene public gene;
    IERC20 public token;
    uint256 public minTime = 0;
    uint256 public fee = 5;
    uint256 public minNextBid = 1e6;
    struct Order {
        uint256 nftId;
        uint256 timeEnd;
        uint256 currentPrice;
        uint256 salePrice;
        address lastBid;
        address saler;
        bool isEnd;
    }
    Order[] public orders;

    event OrderCreate(
        address owner,
        uint256 orderId,
        uint256 nftId,
        uint256 timeEnd,
        uint256 currentPrice,
        uint256 salePrice
    );
    event FeeChange(uint256 newFee);
    event OrderCancel(uint256 orderId);
    event Bid(address bider, uint256 orderId, uint256 price);
    event OrderConfirmed(
        uint256 orderId,
        address buyer,
        uint256 price,
        uint256 fee
    );

    constructor(
        address _nft,
        address _gene,
        address _token
    ) {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        token = IERC20(_token);
    }

    function setMinTime(uint256 _time) public onlyOwner {
        minTime = _time;
    }

    function setMinNextBid(uint256 _min) public onlyOwner {
        minNextBid = _min;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function createOrder(
        uint256 nftId,
        uint256 timeEnd,
        uint256 initPrice,
        uint256 salePrice
    ) public {
        require(nft.ownerOf(nftId) == msg.sender, "Must be owner of NFT");
        require(gene.getStatus(nftId) == 1, "NFT need available");
        require(initPrice > 0, "Price invalid");
        require(salePrice >= initPrice || salePrice == 0, "Sale Price invalid");
        require(timeEnd >= minTime + block.timestamp, "TimeEnd is invalid");
        nft.transferFrom(msg.sender, address(this), nftId);
        orders.push(
            Order(
                nftId,
                timeEnd,
                initPrice,
                salePrice,
                address(0x0),
                msg.sender,
                false
            )
        );
        emit OrderCreate(
            msg.sender,
            orders.length - 1,
            nftId,
            timeEnd,
            initPrice,
            salePrice
        );
    }

    function cancelOrder(uint256 orderId) public {
        require(orderId < orders.length, "Order ID invalid");
        Order storage order = orders[orderId];
        require(order.saler == msg.sender, "Must be owner order");
        require(order.lastBid == address(0x0), "Must not have bider");
        require(!order.isEnd, "Must be not ended");
        order.isEnd = true;
        nft.transferFrom(address(this), msg.sender, order.nftId);
        emit OrderCancel(orderId);
    }

    function bid(uint256 orderId, uint256 value) public {
        token.transferFrom(msg.sender, address(this), value);
        require(orderId < orders.length, "Order ID invalid");
        Order storage order = orders[orderId];
        require(!order.isEnd, "Order ended");
        require(order.timeEnd > block.timestamp, "Bid time ended");
        require(
            (order.currentPrice + minNextBid <= value ||
                (order.salePrice != 0 && value == order.salePrice)),
            "Invalid bid amount"
        );
        if (order.lastBid != address(0x0))
            token.transfer(order.lastBid, order.currentPrice);
        if (order.salePrice != 0 && value >= order.salePrice) {
            token.transfer(order.saler, (order.salePrice * (100 - fee)) / 100);
            order.lastBid = msg.sender;
            order.currentPrice = order.salePrice;
            order.isEnd = true;
            nft.transferFrom(address(this), msg.sender, order.nftId);
            emit OrderConfirmed(
                orderId,
                msg.sender,
                order.salePrice,
                (order.salePrice * fee) / 100
            );
        } else {
            order.lastBid = msg.sender;
            order.currentPrice = value;
            emit Bid(msg.sender, orderId, value);
        }
    }

    function approveSold(uint256 orderId) public {
        require(orderId < orders.length, "Order ID invalid");
        Order storage order = orders[orderId];
        require(order.saler == msg.sender, "Must be owner");
        require(
            !order.isEnd && order.lastBid != address(0x0),
            "Must be can claim"
        );
        order.isEnd = true;
        nft.transferFrom(address(this), order.lastBid, order.nftId);
        token.transfer(order.saler, (order.currentPrice * (100 - fee)) / 100);
        emit OrderConfirmed(
            orderId,
            order.lastBid,
            order.currentPrice,
            (order.currentPrice * (fee)) / 100
        );
    }

    function claim(uint256 orderId) public {
        require(orderId < orders.length, "Order ID invalid");
        Order storage order = orders[orderId];
        require(
            order.timeEnd < block.timestamp &&
                !order.isEnd &&
                order.lastBid != address(0x0),
            "Must be can claim"
        );
        order.isEnd = true;
        nft.transferFrom(address(this), order.lastBid, order.nftId);
        token.transfer(order.saler, (order.currentPrice * (100 - fee)) / 100);
        emit OrderConfirmed(
            orderId,
            order.lastBid,
            order.currentPrice,
            (order.currentPrice * (fee)) / 100
        );
    }

    function funds(uint256 _a, uint256 _c) public onlyOwner {
        if (_c == 0) payable(owner).transfer(_a);
        if (_c == 1) token.transfer(owner, _a);
    }
}