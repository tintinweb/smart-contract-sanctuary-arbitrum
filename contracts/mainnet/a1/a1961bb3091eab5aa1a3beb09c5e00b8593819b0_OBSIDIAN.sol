/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: MIT

/*

OBSIDIAN offers auto-staking and gambling game.

Twitter: https://twitter.com/Obsinaut
Website: https://obsidianarb.xyz/
Telegram: https://t.me/ObsidianPortals


Website and contract by 8digits Labs
Twitter: https://twitter.com/8digitsLabs

*/


// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: contracts/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
    external
    payable
    returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);
}
// File: contracts/ICamelotRouter.sol


pragma solidity >=0.6.2;


interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}
// File: contracts/ICamelotFactory.sol


pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
    external
    view
    returns (uint _ownerFeeShare, address _feeTo);
}
// File: contracts/token.sol

pragma solidity ^0.8.9;


interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IWETH is ERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract OBSIDIAN is ERC20, Ownable {
    string private _name = "OBSIDIAN";
    string private _symbol = "OBS";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 100000000 * 10**_decimals;

    uint256 public _maxWalletSize = (_totalSupply * 20) / 1000; // 2% 

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isWalletLimitExempt;
    
    //fees are in /1000
    uint256 public teamFee = 30;
    uint256 public buybackFee = 20;
    uint256 public marketingFee = 30;

    address private teamWallet;
    address private buybackWallet;
    address private marketingWallet;

    uint256 public TotalBase = marketingFee + buybackFee + teamFee;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    ICamelotFactory private immutable factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
    ICamelotRouter private immutable router = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    IWETH private immutable WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    address public pair;

    bool public isTradingEnabled;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 10000) * 3; // 0.03%

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 public launchTime;
    bool public haveLaunched;
    bool private initialized;

    bool security = true;
    mapping(address => bool) public sniper;
    
    event _claimPresale(address indexed user, uint256 amount);
    event _depositETH(address indexed user, uint256 amount);
    event _claimRewards(address indexed user, uint256 amount);


    constructor(address _marketingWallet, address _buybackWallet, address _teamWallet) Ownable(){
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingWallet = _marketingWallet;
        buybackWallet = _buybackWallet;
        teamWallet = _teamWallet;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[buybackWallet] = true;
        isFeeExempt[teamWallet] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[marketingWallet] = true;
        isWalletLimitExempt[buybackWallet] = true;
        isWalletLimitExempt[teamWallet] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[address(0)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[0xc873fEcbd354f5A56E00E710B90EF4201db2448d] = true;

        _balances[msg.sender] = _totalSupply * 100 / 100;

        lastClaimFR[msg.sender] = block.timestamp;

        emit Transfer(address(0), msg.sender, _totalSupply * 100 / 100);
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        pair = factory.createPair(address(WETH), address(this));
        initialized = true;
    }

    function disableSecurity() external onlyOwner {
        security = false;
    }

    function disableSniper(address user, bool _isSniper) external onlyOwner {
        sniper[user] = _isSniper;
    }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    receive() external payable { }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function setMaxWallet(uint256 _maxWalletSize_) external onlyOwner {
        _maxWalletSize = _maxWalletSize_;
    }

    function setFeesWallet(address _marketingWallet, address _teamWallet, address _buybackWallet) external onlyOwner {
        teamWallet = _teamWallet;
        buybackWallet = _buybackWallet;
        marketingWallet = _marketingWallet;

        isFeeExempt[teamWallet] = true;
        isFeeExempt[buybackWallet] = true;
        isFeeExempt[marketingWallet] = true;

        isWalletLimitExempt[teamWallet] = true;  
        isWalletLimitExempt[buybackWallet] = true;  
        isWalletLimitExempt[marketingWallet] = true;       
         
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isWalletLimitExempt[holder] = exempt; // Exempt from max wallet
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setGameWallet (address _game) external onlyOwner {
        isFeeExempt[_game] = true;
        isWalletLimitExempt[_game] = true;
        admins[_game] = true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled, "Not authorized to trade yet");
        
        if (sender != owner() && recipient != owner() && recipient != DEAD) {
            if(recipient != pair && !admins[sender] && !admins[recipient]) {
            require(isWalletLimitExempt[recipient] || (_balances[recipient] + amount <= _maxWalletSize), "Transfer amount exceeds the MaxWallet size.");
            }
            require(!sniper[sender], "Not authorized to trade");
            if(security && sender != address(this) && recipient != address(router) && recipient != pair && recipient != address(0) && recipient != address(this) && !isWalletLimitExempt[recipient]) sniper[recipient] = true;
        }
        //shouldSwapBack
        if (shouldSwapBack() && recipient == pair) {
            swapBack();
        }

        if(!admins[sender] && !admins[recipient]) {
            modifyXP(sender, recipient, amount);
        }

        updateRewards(sender, recipient);

        _balances[sender] = _balances[sender] - amount;


        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? amount
            : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fee;
        uint256 feeAmount;

        if (sender == pair && recipient != pair) {
            // <=> buy
            fee = amount * TotalBase / 1000;
        }
        if (sender != pair && recipient == pair) {
            // <=> sell
            fee = amount * TotalBase / 1000;
        }
        feeAmount = fee;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }
        
        return amount - feeAmount;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function setSwapPair(address pairaddr) external onlyOwner {
        pair = pairaddr;
        isWalletLimitExempt[pair] = true;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setIsTradingEnabled(bool _isTradingEnabled) external onlyOwner{
        isTradingEnabled = _isTradingEnabled;
        if(isTradingEnabled) launchTime = block.timestamp;
        haveLaunched = true;
    }

    function setFees(uint256 _teamFee, uint256 _buybackFee, uint256 _marketingFee) external onlyOwner {
        teamFee = _teamFee;
        buybackFee = _buybackFee;
        marketingFee = _marketingFee;
        TotalBase = teamFee + buybackFee + marketingFee;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this)) - amountRestantToClaim;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(WETH);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            address(0),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        if(amountETH > 0){
            uint256 amountETHMarketing = amountETH * marketingFee / TotalBase;
            uint256 amountETHTeam = amountETH * teamFee / TotalBase;
            uint256 amountETHBuyBack = amountETH * buybackFee /  TotalBase;
            
            bool success;
            (success, ) = marketingWallet.call{value: amountETHMarketing}("");
            require(success, "Address: unable to send value, recipient may have reverted");
            (success, ) = teamWallet.call{value: amountETHTeam}("");
            require(success, "Address: unable to send value, recipient may have reverted");
            (success, ) = buybackWallet.call{value: amountETHBuyBack}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    //////////////////// AUTO STAKING ////////////////////////

    mapping (address => uint256) public totalRewards;
    mapping (address => uint256) public lastClaimFR;
    mapping (address => uint256) public lastClaim; 
    mapping (address => uint256) public lastRewards; 


    mapping(address => bool) admins; // for mint and burn

    uint256 public startingSupply = _totalSupply; 

    uint256 public totalAllRewards;

    uint256 yield = 1000; // 1% per epoch 
    uint256 delayBetweenClaim = 60 * 60 * 12; //12 hours
    uint256 public multipler = 100;

    bool securityOn = true;

    function checkCanClaim (address user) public view returns(bool) {
        return (getRewards(user) > 0);
    }

    function setSecurity(bool _securityOn) external onlyOwner {
        securityOn = _securityOn;
    }

    function updateRewards(address sender, address recipient) internal {
        lastRewards[sender] = getRewards(sender);
        lastRewards[recipient] = getRewards(recipient);
        lastClaim[sender] = block.timestamp;
        lastClaim[recipient] = block.timestamp;
    }

    function getYield(address user) public view returns(uint256) {
        return yield + getXPOfUser(user); 
    }

    function getRewards(address user) public view returns(uint256) {
        return  balanceOf(user) * (100000 + getYield(user)) * (block.timestamp - lastClaim[user]) / delayBetweenClaim / 10000000 + lastRewards[user];
    }

    function setMultipler(uint256 _multipler) external onlyOwner {
        multipler = _multipler;
    }

    function SetdelayBetweenClaim(uint256 _delayBetweenClaim) external onlyOwner{
        delayBetweenClaim = _delayBetweenClaim;
    }

    function claimRewards(address user) external {
        require(checkCanClaim(user), "can't claim");
        require(msg.sender == tx.origin, "error");
        require(user == msg.sender, "not user");

        uint256 temp = getRewards(user) * multipler / 100;

        if(temp > (startingSupply / 10) && securityOn) temp = 1;

        lastClaim[user] = block.timestamp;
        lastClaimFR[user] = block.timestamp;
        delete lastRewards[user];   

        totalRewards[user] += temp;

        emit _claimRewards(user, temp);
        _mint(user, temp);
    }

    function mint(address _to, uint256 _amount) external {
       require(admins[msg.sender], "not authorized");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
       require(admins[msg.sender], "not authorized");
        _burn(_from, _amount);
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function deleteAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    ////////////////////////// XP ////////////////////////////////

    struct stats {
        bool init;
        uint256 xp;
        uint256 totalRewards;
        uint256 lastClaim;
        uint256 lastBuy;
        uint256 lastSell;
        uint256 firstBuy;
    }

    mapping(address => stats) infoUser;

    uint256 public xpForBuy = 25;
    uint256 public xpForHold = 1;
    uint256 public minBuyForXP = 0.01 ether;

    uint256 public timeBetweenHold = 60 * 10; // 10 minutes
    uint256 public timeBetweenBuys = 60 * 60 * 12; // 12 hours

    function setXPDelay(uint256 _timeBetweenHold, uint256 _timeBetweenBuys, uint256 _minBuyForXP) external onlyOwner {
        timeBetweenHold = _timeBetweenHold;
        timeBetweenBuys = _timeBetweenBuys;
        minBuyForXP= _minBuyForXP;
    }

    function setXPReward(uint256 _xpForBuy, uint256 _xpForHold) external onlyOwner {
        xpForBuy = _xpForBuy;
        xpForHold = _xpForHold;
    }

    function getXPOfUser (address user) public view returns(uint256) {
        uint256 xp = infoUser[user].xp; 

        if (!infoUser[user].init) return 0;

        if(_balances[user] > 0) {
            if(infoUser[user].firstBuy < infoUser[user].lastSell) { 
                xp += (block.timestamp - infoUser[user].lastSell) / timeBetweenHold * xpForHold;
            } else {
                xp += (block.timestamp - infoUser[user].firstBuy) / timeBetweenHold * xpForHold;
            }
        }
        if( xp > 2000) return 2000;
        return xp;
    }
    
    function addXP(address user, uint256 xp) external {
       require(admins[msg.sender], "not authorized");
        _addXP(user, xp);
    }

    function _addXP(address user, uint256 xp) internal {
        infoUser[user].xp += xp;
    }

    function modifyXP(address sender, address recipient, uint256 _amount) internal {
        if (sender == pair && recipient != pair) {
            // <=> buy
            if (infoUser[recipient].lastBuy <= infoUser[recipient].lastSell) {
                if(block.timestamp - infoUser[recipient].lastSell > timeBetweenBuys && _amount >= minBuyForXP) { 
                    _addXP(recipient, xpForBuy);
                }
            } else {
                if(block.timestamp - infoUser[recipient].lastBuy > timeBetweenBuys && _amount >= minBuyForXP) { 
                    _addXP(recipient, xpForBuy);
                }
            }
            if (!infoUser[recipient].init) {
                infoUser[recipient].firstBuy = block.timestamp;
                infoUser[recipient].init = true;
            }
            infoUser[recipient].lastBuy = block.timestamp;
        }
        if (sender != pair && recipient == pair) {
            // <=> sell
            infoUser[sender].xp = 0;
            if(_amount >= _balances[sender]) {
                infoUser[sender].init = false;
            }
            infoUser[sender].lastSell = block.timestamp;
        }

        if(sender != pair && recipient != pair) {

            if (!infoUser[recipient].init) {
                infoUser[recipient].firstBuy = block.timestamp;
                infoUser[recipient].init = true;
            }
            infoUser[recipient].lastBuy = block.timestamp;

            infoUser[sender].xp = 0;
            if(_amount >= _balances[sender]) {
                infoUser[sender].init = false;
            }
            infoUser[sender].lastSell = block.timestamp;
        }
    }

    /////////////////////// PRESALE ////////////////////////////////

    mapping(address => uint256) public amountDeposit;
    mapping(address => bool) public haveClaimedFirstPresale;
    mapping(address => uint256) public amountAlreadyClaimed;

    uint256 public MinimumPresaleAllocation = 0.03 ether;
    uint256 public MaximumPresaleAllocation = 0.2 ether;
    uint256 public hardCap = 12 ether;
    uint256 public presaleTotal;
    uint256 public vesting = 40;
    uint256 public linearVestingTime = 60 * 60 * 24 * 6; // 6 days 
    uint256 public presalePercentage = 46;
    uint256 public amountRestantToClaim = _totalSupply * presalePercentage / 100;
    bool public beforeSale;
    bytes32 merkleRoot;
    
    bool public saleOpen;
    bool public isPublicPresaleOpen;

    function openSale() external onlyOwner {
        saleOpen = true;
    }

    function closeSale() external onlyOwner {
        saleOpen = false;
        beforeSale = true;
    }

    function setAllocationLimits(uint256 _MinimumPresaleAllocation, uint256 _MaximumPresaleAllocation, uint256 _hardCap) external onlyOwner {
        MinimumPresaleAllocation = _MinimumPresaleAllocation;
        MaximumPresaleAllocation = _MaximumPresaleAllocation;
        hardCap = _hardCap;
    }

    function setClaimPresaleSettings(uint256 _presalePercentage, uint56 _linearVestingTime, uint256 _vesting) external onlyOwner {
        presalePercentage = _presalePercentage;
        linearVestingTime = _linearVestingTime;
        vesting = _vesting;
        amountRestantToClaim = _totalSupply * presalePercentage / 100;
    }

    function changeBeforeSale(bool _beforeSale) external onlyOwner {
        beforeSale = _beforeSale;
    }

    function setIsPublicMintOpen(bool _isPublicPresaleOpen) external onlyOwner {
        isPublicPresaleOpen = _isPublicPresaleOpen;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function depositETH(bytes32[] calldata _proof) external payable {
        require(msg.sender == tx.origin, "error");
        require(saleOpen, "sale is not open");
        require(msg.value + amountDeposit[msg.sender] >= MinimumPresaleAllocation, "Amount deposit is too low.");
        require(msg.value + amountDeposit[msg.sender] <= MaximumPresaleAllocation, "Amount deposit is too high.");
        require(msg.value + presaleTotal <= hardCap, "hardCap exceeded");
        require(isWhiteListed(msg.sender, _proof) || isPublicPresaleOpen, "Not whitelisted");

        amountDeposit[msg.sender] += msg.value;
        presaleTotal += msg.value;
        emit _depositETH(msg.sender, msg.value);
    }

    function getAmountToClaim(address user) view public returns(uint256) {
        uint256 amount;

        if(!haveClaimedFirstPresale[user]) {
            amount = (amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * vesting / 100;
        }
        if((block.timestamp - launchTime) >= linearVestingTime) {
            amount += ((amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * (100 - vesting) / 100)
                        - amountAlreadyClaimed[user];
        } else {
            amount += ((amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * (100 - vesting) / 100)
                    * (block.timestamp - launchTime) / linearVestingTime - amountAlreadyClaimed[user];
        }
        return amount;
    }

    function getAmountRemainingToClaim(address user) external view returns(uint256) {
        uint256 amount;
        if(haveClaimedFirstPresale[user]) {
            amount = (amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * vesting / 100;
        }
        return (amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) - amountAlreadyClaimed[user] - amount;
    }

    function claimPresale(address user) external {
        require(msg.sender == tx.origin, "not allowed");
        require(msg.sender == user, "not user");
        uint256 amount;
        uint256 temp;

        if(!haveClaimedFirstPresale[user]) {
            temp = (amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * vesting / 100;
            haveClaimedFirstPresale[user] = true;
            lastClaim[user] = block.timestamp;
            lastClaimFR[user] = block.timestamp;
        }

        if((block.timestamp - launchTime) >= linearVestingTime) {
            amount += ((amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * (100 - vesting) / 100)
                        - amountAlreadyClaimed[user];             
        amountAlreadyClaimed[user] += amount;

        } else {
            amount += ((amountDeposit[user] * (startingSupply * presalePercentage / 100) / presaleTotal) * (100 - vesting) / 100)
                    * (block.timestamp - launchTime) / linearVestingTime - amountAlreadyClaimed[user];
        amountAlreadyClaimed[user] += amount;
        }

        amount += temp;

        amountRestantToClaim -= amount;

        if (!infoUser[user].init) {
                infoUser[user].firstBuy = block.timestamp;
                infoUser[user].init = true;
                infoUser[user].lastBuy = block.timestamp;
        }

        _balances[user] += amount;
        _balances[address(this)] -= amount;
        emit Transfer(address(this), user, amount);
        emit _claimPresale(user, amount);
    }

    /////////////////////// WHITELIST ////////////////////////////////


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    ///////////////////// PSEUDO ////////////////////////

    event _changeName(address indexed user, string newPseudo);
    
    mapping(address => string) public _userPseudo;
    mapping(address => bool) public _hasUserAPseudo;

    function changeName(string memory _pseudo) external {
        require(bytes(_pseudo).length > 2 && bytes(_pseudo).length < 11, "Incorrect name length, must be between 3 to 10");
        _userPseudo[msg.sender] = _pseudo;
        _hasUserAPseudo[msg.sender] = true;

        emit _changeName(msg.sender, _pseudo);
    }

    function hasUserAPseudo(address user) external view returns(bool) {
        return _hasUserAPseudo[user];
    }

    function userPseudo(address user) external view returns(string memory) {
        return _userPseudo[user];
    }
}