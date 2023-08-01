// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../access/Governable.sol";

contract Faucet is Governable {
    IERC20 public GMX;
    IERC20 public sGLP;
    IERC20 public WrappedStakedEther;

    uint256 public GMXAmount = 100 ether;
    uint256 public FSGLPAmount = 1000 ether;
    uint256 public WrappedStakedEtherAmount = 3 ether;

    mapping(address => bool) public hasClaimedGMX;
    mapping(address => bool) public hasClaimedFSGLP;
    mapping(address => bool) public hasClaimedWrappedStakedEther;

    constructor(
        address _GMX,
        address _sGLP,
        address _WrappedStakedEther
    ) public {
        GMX = IERC20(_GMX);
        sGLP = IERC20(_sGLP);
        WrappedStakedEther = IERC20(_WrappedStakedEther);
    }

    function claimGMX() public {
        require(!hasClaimedGMX[msg.sender], "Already claimed GMX");
        hasClaimedGMX[msg.sender] = true;
        bool success = GMX.transfer(msg.sender, GMXAmount);
        require(success, "Transfer failed");
    }

    function claimFSGLP() public {
        require(!hasClaimedFSGLP[msg.sender], "Already claimed sGLP");
        hasClaimedFSGLP[msg.sender] = true;
        bool success = sGLP.transfer(msg.sender, FSGLPAmount);
        require(success, "Transfer failed");
    }

    function claimWSTETH() public {
        require(!hasClaimedWrappedStakedEther[msg.sender], "Already claimed Wrapped Staked Ether");
        hasClaimedWrappedStakedEther[msg.sender] = true;
        bool success = WrappedStakedEther.transfer(msg.sender, WrappedStakedEtherAmount);
        require(success, "Transfer failed");
    }

    function setGMXAmount(uint256 _amount) public onlyGov {
        GMXAmount = _amount;
    }

    function setFSGLPAmount(uint256 _amount) public onlyGov {
        FSGLPAmount = _amount;
    }

    function setWrappedStakedEtherAmount(uint256 _amount) public onlyGov {
        WrappedStakedEtherAmount = _amount;
    }
}