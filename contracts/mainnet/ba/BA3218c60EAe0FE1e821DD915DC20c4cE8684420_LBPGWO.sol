pragma solidity = 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address lpPair);

    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}


interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}



//--- Interface for ERC20 ---//
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//--- Contract v2 ---//
contract LBPGWO is Context, Ownable, IERC20 {

    function totalSupply() external pure override returns (uint256) {if (_totalSupply == 0) {revert();}
        return _totalSupply;}

    function decimals() external pure override returns (uint8) {if (_totalSupply == 0) {revert();}
        return _decimals;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function name() external pure override returns (string memory) {return _name;}

    function getOwner() external view override returns (address) {return owner();}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _noFee;
    mapping(address => bool) private liquidityAdd;
    mapping(address => bool) private isLpPair;
    mapping(address => bool) private isPresaleAddress;
    mapping(address => uint256) private balance;
    bool public IsCanClaim = false;
    bool public IsCanMint = true;

    uint256 constant public _totalSupply = 1_008_600_000_000 * 10 ** 9;
    uint256 constant public swapThreshold = _totalSupply / 10_000;
    uint256  public buyfee = 1_000;
    uint256  public sellfee = 1_000;
    uint256  public transferfee = 0;
    uint256  public fee_denominator = 1_000;
    bool private canSwapFees = true;
    address payable private marketingAddress;

    IRouter02 public swapRouter;
    string constant private _name = "LBPGWO";
    string constant private _symbol = "LBPGWO";
    uint8 constant private _decimals = 9;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool public isTradingEnabled = false;
    bool private inSwap;
    mapping(address => uint256) public usermint;
    mapping(address => bool) public userclaim;
    uint256 public userClaimedAmount;
    bytes32 private _merkleRoot = 0xae92f88c3e2ad76498d1526607eb1fdbd0add8036101e06a97ddfc980dc489fc;

    uint256 public MaxClaimAmount = 30000;
    uint256 public SingleClaimAmount = _totalSupply * 10 / MaxClaimAmount;
    uint256 public SingleMintAmount = 353_010_000_000 * 10 ** 9;
    uint256 public LBPGWOmintPrice = 0.0001 ether;

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }


    event _enableTrading();
    event _setPresaleAddress(address account, bool enabled);
    event _toggleCanSwapFees(bool enabled);
    event _changePair(address newLpPair);
    event _changeWallets(address marketing);


    constructor () {
        swapRouter = IRouter02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _noFee[msg.sender] = true;
        liquidityAdd[msg.sender] = true;
        marketingAddress = payable(msg.sender);
        balance[msg.sender] = _totalSupply * 10 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 10 / 100);
        balance[msg.sender] = _totalSupply * 10 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 10 / 100);
        balance[msg.sender] = _totalSupply * 10 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 10 / 100);
        balance[msg.sender] = _totalSupply * 5 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 5 / 100);
        balance[msg.sender] = _totalSupply * 30 / 100;
        emit Transfer(address(0), msg.sender, _totalSupply * 30 / 100);
        balance[address(this)] = _totalSupply * 35 / 100;
        emit Transfer(address(0), address(this), _totalSupply * 35 / 100);
        lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }


    function mintLBPGWO(uint256 _quantity) external payable {
        require(IsCanMint, "Not in the claim stage.");
        require(balanceOf(address(this)) > 0, "mint has ended.");
        require(usermint[msg.sender] + _quantity <= 200, "Invalid quantity");
        require(msg.value >= _quantity * LBPGWOmintPrice, "Ether is not enough");
        usermint[msg.sender] += _quantity;
        transfer(msg.sender, _quantity * SingleMintAmount);
    }

    function claimLBPGWO(bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(isWhitelistAddress(msg.sender, _merkleProof), "Caller is not in whitelist or invalid signature");
        require(IsCanClaim, "Not in the claim stage.");
        require(balanceOf(address(this)) > 0, "claim has ended.");
        require(!userclaim[msg.sender], "Invalid quantity");
        require(userClaimedAmount + 1 <= MaxClaimAmount, "Invalid quantity");
        userclaim[msg.sender] = true;
        userClaimedAmount++;
        transfer(msg.sender,  SingleClaimAmount);
    }

    function isWhitelistAddress(address _address, bytes32[] calldata _signature) public view returns (bool) {
        return MerkleProof.verify(_signature, _merkleRoot, keccak256(abi.encodePacked(_address)));
    }


    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transfer(sender, recipient, amount);
    }

    function isNoFeeWallet(address account) external view returns (bool) {
        return _noFee[account];
    }

    function setNoFeeWallet(address account, bool enabled) public onlyOwner {
        _noFee[account] = enabled;
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
        && out != owner() && msg.sender != owner()
        && !liquidityAdd[ins] && !liquidityAdd[out] && out != DEAD && out != address(0) && out != address(this);
        return isLimited;
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) {
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function canSwap(address ins, address out) internal view returns (bool) {
        bool canswap = canSwapFees && !isPresaleAddress[ins] && !isPresaleAddress[out];
        return canswap;
    }

    function changeLpPair(address newPair) external onlyOwner {
        isLpPair[newPair] = true;
        emit _changePair(newPair);
    }

    function toggleCanSwapFees(bool yesno) external onlyOwner {
        require(canSwapFees != yesno, "Bool is the same");
        canSwapFees = yesno;
        emit _toggleCanSwapFees(yesno);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isLimitedAddress(from, to)) {
            require(isTradingEnabled, "Trading is not enabled");
        }

        if (is_sell(from, to) && !inSwap && canSwap(from, to)) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= swapThreshold) {internalSwap(contractTokenBalance);}
        }

        if (_noFee[from] || _noFee[to]) {
            takeFee = false;
        }

        balance[from] -= amount;
        uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee;
        emit Transfer(from, to, amountAfterFee);

        return true;
    }

    function changeWallets(address marketing) external onlyOwner {
        marketingAddress = payable(marketing);
        emit _changeWallets(marketing);
    }

    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy) fee = buyfee; else if (issell) fee = sellfee; else fee = transferfee;
        if (fee == 0) return amount;
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);

        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }
        bool success;

        if (address(this).balance > 0) {(success,) = marketingAddress.call{value : address(this).balance}("");}

    }

    function enableTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading already enabled");
        isTradingEnabled = true;
        emit _enableTrading();
    }

    function changeLBPGWOmintPrice(uint256 LBPGWOmintPrice_) external onlyOwner {
        LBPGWOmintPrice = LBPGWOmintPrice_;
    }

    function changeSingleMintAmount(uint256 SingleMintAmount_) external onlyOwner {
        SingleMintAmount = SingleMintAmount_;
    }

    function changebuyfee(uint256 buyfee_) external onlyOwner {
        buyfee = buyfee_;
    }

    function changesellfee(uint256 sellfee_) external onlyOwner {
        sellfee = sellfee_;
    }

    function changetransferfee(uint256 transferfee_) external onlyOwner {
        transferfee = transferfee_;
    }

    function changeIsCanClaim(bool IsCanClaim_) external onlyOwner {
        IsCanClaim = IsCanClaim_;
    }


    function changeIsCanMint(bool _IsCanMint) external onlyOwner {
        IsCanMint = _IsCanMint;
    }

    function changeMaxClaimAmount(uint256 MaxClaimAmount_) external onlyOwner {
        MaxClaimAmount = MaxClaimAmount_;
    }

    function changeSingleClaimAmount(uint256 SingleClaimAmount_) external onlyOwner {
        SingleClaimAmount = SingleClaimAmount_;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function withdrawEth() external payable {
        require(msg.sender == marketingAddress, "Not correct address");
        (bool success,) = marketingAddress.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken() external payable {
        require(msg.sender == marketingAddress, "Not correct address");
        uint256 selfbalance = balanceOf(address(this));
        if (selfbalance > 0) {
            bool success = transfer(marketingAddress, selfbalance);
            require(success, "payMent  Transfer failed.");
        }
    }

}

// SPDX-License-Identifier: MIT
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