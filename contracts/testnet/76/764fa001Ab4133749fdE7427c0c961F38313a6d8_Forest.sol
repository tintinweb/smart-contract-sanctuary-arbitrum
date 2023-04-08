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

import "./BasicAuth.sol";
import "./interfaces/IGene.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFactory.sol";

contract Forest is Basic {
    IERC721 public nft;
    IGene public gene;
    IERC20 public water;
    IFactory public factory;
    IERC20 public token;

    uint256 public priceLand = 1e9;
    // uint256 public timePeriod = 1 days;
    uint256 public timePeriod = 2 minutes;
    struct Period {
        uint256 timeGrow;
        uint256 timeHarvest;
        uint256 waterPerDay;
        uint256 output;
        uint256 seedOutput;
    }
    mapping(uint256 => Period) public period;
    event PlantTree(
        address user,
        uint256 nftId,
        uint256 day,
        uint256 landIndex,
        uint256 waterUsed
    );
    event SprayTree(
        address user,
        uint256 nftId,
        uint256 landIndex,
        uint256 day,
        uint256 waterUsed
    );

    event BuyLand(uint256 price, uint256 landIndex, address user);

    event CompletedHarvest(uint256 landId, uint256 nftId, address user);

    event WaterRewarded(uint256 amount, address user);

    constructor(
        address _nft,
        address _gene,
        address _water,
        address _factory,
        address _token
    ) {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        water = IERC20(_water);
        token = IERC20(_token);
        factory = IFactory(_factory);
        // period[1] = Period(7, 4, 1e6, 4e6, 1);
        // period[2] = Period(10, 5, 1e6, 45e5, 2);
        // period[3] = Period(14, 7, 1e6, 5e6, 3);
        period[1] = Period(2, 1, 1e6, 4e6, 1);
        period[2] = Period(3, 2, 1e6, 45e5, 2);
        period[3] = Period(4, 3, 1e6, 5e6, 3);
    }

    function editPriceLand(uint256 _price) public onlyOwner {
        priceLand = _price;
    }

    function editPeriod(
        uint256 types,
        uint256 timeGrow,
        uint256 timeHarvest,
        uint256 waterPerDay,
        uint256 output,
        uint256 seedOutput
    ) public onlyOwner {
        period[types] = Period(
            timeGrow,
            timeHarvest,
            waterPerDay,
            output,
            seedOutput
        );
    }

    function changeContract(
        address _nft,
        address _gene,
        address _water,
        address _factory,
        address _token
    ) public onlyOwner {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        water = IERC20(_water);
        token = IERC20(_token);
        factory = IFactory(_factory);
    }

    struct User {
        uint256 max;
        mapping(uint256 => Land) land;
    }

    struct Land {
        uint256 nftId;
        uint256 timeStart;
        uint256 numberSpray;
        uint256 lastSpray;
        uint256 claimed;
    }

    mapping(address => User) public users;

    function getNextPrice(address user) public view returns (uint256) {
        return (priceLand * (11**users[user].max)) / (10**users[user].max);
    }

    function buyLand() public payable {
        uint256 price = getNextPrice(msg.sender);
        token.transferFrom(msg.sender, address(this), price);
        users[msg.sender].max++;
        emit BuyLand(price, users[msg.sender].max - 1, msg.sender);
    }

    function plantTree(uint256 _nftId, uint256 _index) public {
        require(nft.ownerOf(_nftId) == msg.sender, "Must be owner of NFT");
        (uint256 types, uint256 quality, , uint256 status) = gene.plants(
            _nftId
        );
        require(status == 1 && types == 2, "NFT must be available");
        User storage user = users[msg.sender];
        require(_index <= user.max, "Wrong land");
        Land storage land = user.land[_index];
        require(land.nftId == 0, "Must be available");
        land.nftId = _nftId;
        land.timeStart = block.timestamp;
        land.numberSpray = 1;
        land.lastSpray = block.timestamp;
        water.transferFrom(
            msg.sender,
            address(this),
            period[quality].waterPerDay
        );
        gene.change(_nftId, [0, 0, 0, uint256(2)]);
        emit PlantTree(
            msg.sender,
            _nftId,
            block.timestamp,
            _index,
            period[quality].waterPerDay
        );
    }

    function sprayTree(uint256 _landIndex) public {
        Land storage land = users[msg.sender].land[_landIndex];
        require(land.nftId != 0, "Must be use");
        (, uint256 quality, , ) = gene.plants(land.nftId);
        uint256 today = block.timestamp / timePeriod;
        require(
            today > (land.lastSpray / timePeriod),
            "Can't spray 2 time a day"
        );
        require(today < (land.lastSpray / timePeriod + 3), "Longer than 3 day");
        require(
            land.numberSpray <
                (period[quality].timeGrow + period[quality].timeHarvest),
            "Max spray"
        );
        land.lastSpray = block.timestamp;
        land.numberSpray++;
        water.transferFrom(
            msg.sender,
            address(this),
            period[quality].waterPerDay
        );
        if (land.numberSpray > period[quality].timeGrow) {
            if ((land.lastSpray / timePeriod) + 1 == today) {
                water.transfer(msg.sender, period[quality].output);
                emit WaterRewarded(period[quality].output, msg.sender);
            } else {
                water.transfer(msg.sender, period[quality].output / 2);
                emit WaterRewarded(period[quality].output / 2, msg.sender);
            }
        }
        emit SprayTree(
            msg.sender,
            land.nftId,
            _landIndex,
            block.timestamp,
            period[quality].waterPerDay
        );
    }

    function claimHarvest(uint256 _landIndex) public {
        Land storage land = users[msg.sender].land[_landIndex];
        require(land.nftId != 0, "Must be use");
        (, uint256 quality, uint256 performance, ) = gene.plants(land.nftId);
        if (
            land.numberSpray ==
            (period[quality].timeGrow + period[quality].timeHarvest)
        ) {
            require(
                land.lastSpray + timePeriod < block.timestamp,
                "Must be wait for 24hours"
            );
            gene.change(land.nftId, [1, 0, 0, uint256(1)]);
            for (uint256 i = 0; i < period[quality].seedOutput - 1; i++) {
                factory.generatorPlant(msg.sender, 1, quality, performance);
            }
        } else {
            require(land.lastSpray + 3 * timePeriod < block.timestamp, "!dead");
            gene.change(land.nftId, [1, 0, 0, uint256(10)]);
        }

        land.nftId = 0;
        emit CompletedHarvest(_landIndex, land.nftId, msg.sender);
    }

    function getLandInfo(address _user, uint256 _nftId)
        public
        view
        returns (
            uint256 nftId,
            uint256 timeStart,
            uint256 numberSpray,
            uint256 lastSpray,
            uint256 claimed
        )
    {
        Land memory land = users[_user].land[_nftId];
        return (
            land.nftId,
            land.timeStart,
            land.numberSpray,
            land.lastSpray,
            land.claimed
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFactory {
    function generatorPlant(
        address to,
        uint256 types,
        uint256 quality,
        uint256 performance
    ) external;
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