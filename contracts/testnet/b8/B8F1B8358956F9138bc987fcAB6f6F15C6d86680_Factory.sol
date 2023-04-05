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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract Factory is Basic {
    event BuySeed(uint256 fee, uint256[] nfts);
    IERC721 public nft;
    IGene public gene;
    IERC20 public token;
    uint256 public counter = 1;
    uint256 public price;

    constructor(
        address _nft,
        address _gene,
        address _token,
        uint256 _initPrice
    ) {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        price = _initPrice;
        token = IERC20(_token);
    }

    function changeContract(
        address _nft,
        address _gene,
        address _token
    ) public onlyOwner {
        nft = IERC721(_nft);
        gene = IGene(_gene);
        token = IERC20(_token);
    }

    function _generatorPlant(
        address to,
        uint256 types,
        uint256 quality,
        uint256 performance
    ) internal returns (uint256) {
        nft.mint(to, counter);
        gene.change(counter, [types, quality, performance, 1]);
        counter++;
        return counter - 1;
    }

    function generatorPlant(
        address to,
        uint256 types,
        uint256 quality,
        uint256 performance
    ) public onlyMod {
        _generatorPlant(to, types, quality, performance);
    }

    function buySeed(uint256 _amount) public {
        require(_amount <= 10, "Can't buy more than 10");
        token.transferFrom(msg.sender, address(this), _amount * price);
        uint256[] memory nfts = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            nfts[i] = _generatorPlant(msg.sender, 1, 1, 100);
        }
        emit BuySeed(_amount * price, nfts);
    }

    function changePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function funds(uint256 _a, uint256 _c) public onlyOwner {
        if (_c == 0) payable(owner).transfer(_a);
        if (_c == 1) token.transfer(owner, _a);
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