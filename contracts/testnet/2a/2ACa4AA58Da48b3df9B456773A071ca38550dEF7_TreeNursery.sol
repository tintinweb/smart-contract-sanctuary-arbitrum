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

contract TreeNursery is Basic {
    IERC721 public nft;
    IGene public gene;
    IERC20 public water;
    uint256 public timePeriod = 2 minutes;
    struct Period {
        uint256 time;
        uint256 waterPerDay;
    }
    mapping(uint256 => Period) public period;
    struct User {
        uint256 nftId;
        uint256 timeStart;
        uint256 numberSpray;
        uint256 lastSpray;
    }
    mapping(address => User) public users;

    event StartNursery(address user, uint256 nftId, uint256 day);
    event Spray(uint256 nftId, uint256 day);
    event Claim(address user);
    event NurseryCompleted(uint256 nftId, uint256 types);

    constructor(
        address _nft,
        address _gene,
        address _water
    ) {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        water = IERC20(_water);
        period[1] = Period(3, 1e6);
        period[2] = Period(3, 1e6);
        period[3] = Period(3, 1e6);
    }

    function changePeriod(
        uint256 _num,
        uint256 time,
        uint256 waterPerDay
    ) public onlyOwner {
        period[_num] = Period(time, waterPerDay);
    }

    function changeContract(
        address _nft,
        address _gene,
        address _water
    ) public onlyOwner {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        water = IERC20(_water);
    }

    function start(uint256 _id) public {
        require(nft.ownerOf(_id) == msg.sender, "Must be owner of NFT");
        (uint256 types, uint256 quality, , uint256 status) = gene.plants(_id);
        require(status == 1 && types == 1, "NFT must be available");
        User storage user = users[msg.sender];
        require(user.nftId == 0, "Must be not use");

        user.nftId = _id;
        user.timeStart = block.timestamp;
        gene.change(_id, [0, 0, 0, uint256(2)]);
        water.transferFrom(
            msg.sender,
            address(this),
            period[quality].waterPerDay
        );
        user.lastSpray = block.timestamp;
        user.numberSpray = 1;
        emit StartNursery(msg.sender, _id, user.lastSpray);
    }

    function spray() public {
        User storage user = users[msg.sender];
        require(user.nftId != 0, "Must be use");
        (, uint256 quality, , ) = gene.plants(user.nftId);
        uint256 today = block.timestamp / timePeriod;
        require(
            today > (user.lastSpray / timePeriod),
            "Can't spray 2 time a day"
        );
        require(today < (user.lastSpray / timePeriod + 3), "Longer than 3 day");
        user.lastSpray = block.timestamp;
        user.numberSpray++;
        water.transferFrom(
            msg.sender,
            address(this),
            period[quality].waterPerDay
        );
        emit Spray(user.nftId, today);
    }

    function getStatusNursery(address _user) public view returns (uint256) {
        User storage user = users[_user];
        if (user.nftId == 0) return 0;
        (, uint256 quality, , ) = gene.plants(user.nftId);
        uint256 today = block.timestamp / timePeriod;
        if (user.numberSpray < period[quality].time) return 0;
        if ((user.lastSpray + 24 hours) < block.timestamp) return 0;
        if (
            (today > (user.lastSpray / timePeriod + 3)) &&
            user.numberSpray < period[quality].time
        ) return 2;
        return 1;
    }

    function claim() public {
        require(getStatusNursery(msg.sender) != 0, "Must be completed");
        if (getStatusNursery(msg.sender) == 1) {
            emit Claim(msg.sender);
        } else {
            User storage user = users[msg.sender];
            gene.change(user.nftId, [0, 0, 0, uint256(10)]);
            //Brun NFT
            emit NurseryCompleted(user.nftId, 10);
        }
    }

    function submit(address _user, uint256 _result) public onlyMod {
        User storage user = users[_user];
        require(getStatusNursery(_user) == 1, "Must be available");
        (, , uint256 performance, ) = gene.plants(user.nftId);
        if (_result < 10) {
            gene.change(user.nftId, [0, 0, 0, uint256(10)]);
            //Burn NFT
            emit NurseryCompleted(user.nftId, 10);
        } else if (_result < 70) {
            gene.change(user.nftId, [uint256(1), 1, 0, 1]);
            emit NurseryCompleted(user.nftId, 1);
        } else if (_result < 98) {
            gene.change(
                user.nftId,
                [uint256(1), 2, (performance * 102) / 100, 1]
            );
            emit NurseryCompleted(user.nftId, 2);
        } else {
            gene.change(
                user.nftId,
                [uint256(1), 3, (performance * 105) / 100, 1]
            );
            emit NurseryCompleted(user.nftId, 3);
        }
        user.nftId = 0;
    }

    function funds(uint256 _a) public onlyOwner {
        water.transfer(owner, _a);
    }
}