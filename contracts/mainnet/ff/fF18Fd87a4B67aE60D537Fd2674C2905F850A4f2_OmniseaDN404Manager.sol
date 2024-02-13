// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;

import "../util/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MintParams} from "../structs/dn404/DN404Structs.sol";
import "../interfaces/IOmniseaDN404.sol";
import "../interfaces/IOmniseaDN404Factory.sol";

contract OmniseaDN404Manager is ReentrancyGuard {
    event Minted(address collection, address minter, uint256 quantity, uint256 value);

    uint256 public fixedFee;
    uint256 public dynamicFee;
    IERC20 public osea;
    mapping (address => uint256) public collectionsOsea; // Overrides the "dynamicFee" if >= "minOseaPerCollection" OSEA present per Collection
    mapping (address => uint256) public collectionsOseaPerToken;
    uint256 public minOseaPerCollection;
    bool public isOseaEnabled;
    address private _revenueManager;
    address private _owner;
    bool private _isPaused;
    IOmniseaDN404Factory private _factory;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address factory_) {
        _owner = msg.sender;
        _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _factory = IOmniseaDN404Factory(factory_);
        dynamicFee = 0;
        fixedFee = 150000000000000;
    }

    function setOSEA(address _osea, uint256 _minOseaPerCollection, bool _isEnabled) external onlyOwner {
        if (address(osea) == address(0)) {
            osea = IERC20(_osea);
        }
        minOseaPerCollection = _minOseaPerCollection;
        isOseaEnabled = _isEnabled;
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_ <= 20);
        dynamicFee = fee_;
    }

    function setFixedFee(uint256 fee_) external onlyOwner {
        fixedFee = fee_;
    }

    function setRevenueManager(address _manager) external onlyOwner {
        _revenueManager = _manager;
    }

    function addOseaToCollection(address _collection, uint256 _oseaAmount, uint256 _oseaAmountPerToken) external {
        require(isOseaEnabled && _factory.drops(_collection));
        require(_oseaAmount > 0 && _oseaAmountPerToken > 0);
        uint256 collectionOsea = collectionsOsea[_collection];
        require(collectionOsea + _oseaAmount >= minOseaPerCollection);

        // If the collections already has added OSEA, only the owner can modify "collectionsOseaPerToken"
        if (collectionOsea > 0 && collectionsOseaPerToken[_collection] != _oseaAmountPerToken) {
            IOmniseaDN404 collection = IOmniseaDN404(_collection);
            require(msg.sender == collection.owner());
        }

        uint256 addAmount = _oseaAmount * 95 / 100;
        uint256 burnAmount = _oseaAmount - addAmount;
        require(osea.transferFrom(msg.sender, address(this), addAmount));
        require(osea.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), burnAmount));
        collectionsOsea[_collection] += addAmount;
        require(_oseaAmountPerToken <= collectionsOsea[_collection], ">oseaAmountPerToken");
        collectionsOseaPerToken[_collection] = _oseaAmountPerToken;
    }

    function mint(MintParams calldata _params) external payable nonReentrant {
        require(!_isPaused);
        require(_factory.drops(_params.collection));
        IOmniseaDN404 collection = IOmniseaDN404(_params.collection);
        address recipient = _params.to;

        uint256 price = collection.mintPrice(_params.phaseId);
        uint256 quantityPrice = price * _params.quantity;
        require(msg.value == quantityPrice + fixedFee, "!=price");

        uint256 collectionOsea = collectionsOsea[_params.collection];
        uint256 dynamicFee_ = dynamicFee;
        if (isOseaEnabled && collectionOsea > 0) {
            dynamicFee_ = 0;
            uint256 totalOsea = collectionsOseaPerToken[_params.collection] * _params.quantity;
            uint256 oseaAmount = collectionOsea > totalOsea ? totalOsea : collectionOsea;
            osea.transfer(recipient, oseaAmount);
            collectionsOsea[_params.collection] -= oseaAmount;
        }

        if (quantityPrice > 0) {
            uint256 paidToOwner = quantityPrice * (100 - dynamicFee_) / 100;
            (bool p1,) = payable(collection.owner()).call{value: paidToOwner}("");
            require(p1, "!p1");

            (bool p2,) = payable(_revenueManager).call{value: msg.value - paidToOwner}("");
            require(p2, "!p2");
        } else {
            (bool p3,) = payable(_revenueManager).call{value: msg.value}("");
            require(p3, "!p3");
        }

        collection.mint(recipient, _params.quantity, _params.merkleProof, _params.phaseId);
        emit Minted(_params.collection, recipient, _params.quantity, msg.value);
    }

    function setPause(bool isPaused_) external onlyOwner {
        _isPaused = isPaused_;
    }

    function withdraw() external onlyOwner {
        (bool p,) = payable(_owner).call{value: address(this).balance}("");
        require(p, "!p");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Reentrancy guard mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unauthorized reentrant call.
    error Reentrancy();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.
    /// 9 bytes is large enough to avoid collisions with lower slots,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      REENTRANCY GUARD                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards a function from reentrancy.
    modifier nonReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
            sstore(_REENTRANCY_GUARD_SLOT, address())
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_REENTRANCY_GUARD_SLOT, codesize())
        }
    }

    /// @dev Guards a view function from read-only reentrancy.
    modifier nonReadReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }
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
pragma solidity ^0.8.7;

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    uint24 royaltyAmount;
    uint256 endTime;
    bool isEdition;
    uint256 premintQuantity;
}

struct MintParams {
    address to;
    address collection;
    uint24 quantity;
    bytes32[] merkleProof;
    uint8 phaseId;
}

struct Phase {
    uint256 from;
    uint256 to;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
    address token;
    uint256 minToken;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404 {
    function initialize(CreateParams memory params, address _owner, address _manager, address _scheduler) external;
    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external returns (uint256);
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function owner() external view returns (address);
    function dropsManager() external view returns (address);
    function endTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/dn404/DN404Structs.sol";

interface IOmniseaDN404Factory {
    function create(CreateParams calldata params) external;
    function drops(address) external returns (bool);
}