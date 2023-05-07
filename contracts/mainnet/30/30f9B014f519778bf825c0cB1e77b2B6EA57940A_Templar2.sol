/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);

    constructor(){
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) external onlyOwner {
        require(account != address(0),"zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol



pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol


pragma solidity ^0.8.0;

interface IRandom {
    function requestRandomness(uint256 tokenId) external;
    function openRand(uint256 tokenId) external returns(bool,uint256);
    function fightRand(uint256 tokenId,uint256 energy) external returns(bool,uint256);
}
interface ILOS20Miner {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}
interface ILOS721 is IERC721 {
    function mint(address recipient_) external returns (uint256);
    function getTokens(address owner) external view returns(uint256[] memory);
}


contract Templar2 is Owner {

    struct TokenInfo {
        uint256 fightAt;            // last fight time
        uint256 energy;             // stamina left
        uint256 levelCode;          // 100、200、300、400、500...、600
        uint256 totalClaim;         // v2
    }
    struct AccountInfo {
        uint256 reward;
        uint256 claimAt;
        uint256 totalClaim;
    }
    struct Mission {
        uint256 winRate;
        uint256 reward;
    }
    struct Level {
        uint256 winRateAdd;         // %
        uint256 rewardAdd;          // %
        uint256 code;
        uint256 levelOffset;        // %
    }

    IERC20      public immutable LOS20;
    ILOS721     public immutable LOS721;
    ILOS20Miner public LOS20Miner;
    IRandom     public random;

    bool public contractCallable = false;

    uint256 public claimCD = 1 days;
    uint256 public claimFeeRate = 10;       // %
    address public feeAccount;
    uint256 public chestFee;
    uint256 public chestSupply;

    uint256 public maxEnergy = 8;
    uint256 public energyCD = 3 hours;

    uint256 public totalClaimFee;
    uint256 public totalChestFee;

    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => Mission) public missionInfo;
    mapping(uint256 => Level) public levelInfo;


    event Chest(address indexed account, uint256 fee, uint256 indexed  tokenId);
    event Open(address indexed account, uint256 indexed level, uint256 indexed tokenId,uint256 rand);
    event Fight(address indexed account, bool indexed win, uint256 indexed reward, uint256 boss, uint256 tokenId,uint256 rand);
    event Claim(address indexed account, uint256 indexed amount);

    event ReMint(address indexed account, uint fee, uint256 indexed tokenId);
    event ReOpen(address indexed account, uint256 indexed level, uint256 indexed tokenId);


    constructor(address LOS20_,address LOS721_,address LOS20Miner_){
        LOS20 = IERC20(LOS20_);
        LOS721 = ILOS721(LOS721_);
        LOS20Miner = ILOS20Miner(LOS20Miner_);

        feeAccount = msg.sender;

        setMissionInfo(1, 80, 0.5 * 1e18);
        setMissionInfo(2, 60, 1e18);
        setMissionInfo(3, 40, 2 * 1e18);
        setMissionInfo(4, 20, 5 * 1e18);

        setLevelInfo(1, 0, 0);
        setLevelInfo(2, 5, 0);
        setLevelInfo(3, 6, 50);
        setLevelInfo(4, 8, 250);
        setLevelInfo(5, 15, 1900);
        setLevelInfo(6, 15, 2900);

        setReMintInfo(1,19.9 * 1e18,[uint(50),uint(30),uint(7),uint(3),uint(10)]);
        setReMintInfo(2,19.9 * 1e18,[uint(0),uint(60),uint(20),uint(5),uint(15)]);
        setReMintInfo(3,19.9 * 1e18,[uint(0),uint(0),uint(70),uint(10),uint(20)]);

    }

    function chest() public returns (uint256 tokenId) {

        require(chestSupply >= 1,"no suppluy");
        chestSupply -= 1;

        LOS20.transferFrom(msg.sender,feeAccount,chestFee);
        tokenId = LOS721.mint(msg.sender);

        random.requestRandomness(tokenId);
        totalChestFee += chestFee;

        emit Chest(msg.sender, chestFee, tokenId);
        return tokenId;
    }

    function multiChest(uint256 nftAmount) external {
        require(nftAmount > 0,"multiple");
        for (uint256 index = 0; index < nftAmount; index++) {
            chest();
        }
    }

    function open(uint256 tokenId) external returns (uint256 levelCode) {
        //
        require(LOS721.ownerOf(tokenId) == msg.sender, "not yours");
        require(tokenInfo[tokenId].levelCode == 0 || tokenInfo[tokenId].levelCode == 10,"never retry");

        //
        (bool succ, uint r) = random.openRand(tokenId);
        require(succ,"try later");

        uint level = 0;
        uint offset = 0;
        do {
            level ++;
            offset = levelInfo[level].levelOffset;
            if (r < offset) {
                break;
            }
        }while(offset != 100);

        tokenInfo[tokenId].energy = maxEnergy;
        tokenInfo[tokenId].levelCode = levelInfo[level].code;

        emit Open(msg.sender,levelInfo[level].code,tokenId,r);
        return levelInfo[level].code;
    }

    function fight(uint256 tokenId, uint256 mission) public {

        if (isContract(msg.sender) && !contractCallable){
            require(false,"can not call");
        }

        require(LOS721.ownerOf(tokenId) == msg.sender, "not yours");

        (uint256 fightAt,uint256 energy, uint256 levelCode)= getTokenInfo(tokenId);
        require(energy > 0, "rest awhile");

        (uint256 winRate, uint256 rewards) = getWRR(mission, levelCode);
        (,uint256 r) = random.fightRand(tokenId,energy * 10);
        r = 100 -r;
        if (winRate > r) {
            accountInfo[msg.sender].reward += rewards;
            accountInfo[msg.sender].totalClaim += rewards;
            tokenInfo[tokenId].totalClaim += rewards;
            emit Fight(msg.sender,true,rewards, mission, tokenId,r);
        }else{
            emit Fight(msg.sender,false,0, mission, tokenId,r);
        }
        tokenInfo[tokenId].energy = energy - 1;
        tokenInfo[tokenId].fightAt = fightAt;
    }

    function multiFight(uint256 tokenId, uint256 mission, uint256 times) external {
        require(times > 0,"multiple");

        for (uint256 index = 0; index < times; index++) {
            fight(tokenId, mission);
        }
    }

    function claim() external returns (uint256 reward) {

        reward = accountInfo[msg.sender].reward;
        uint claimAt = accountInfo[msg.sender].claimAt;
        if (reward > 0) {
            require(claimAt == 0 || block.timestamp - claimAt >= claimCD, "not now");

            uint feePart = reward * claimFeeRate / 100;
            LOS20Miner.mint(feeAccount,feePart);
            LOS20Miner.mint(msg.sender, reward - feePart);
            totalClaimFee += feePart;

            accountInfo[msg.sender].claimAt = block.timestamp;
            accountInfo[msg.sender].reward = 0;
        }

        emit Claim(msg.sender, reward);
        return reward;
    }

    function getTokenInfo(uint256 tokenId) public view returns(uint256 fightAt, uint256 energy, uint256 levelCode) {

        TokenInfo memory token = tokenInfo[tokenId];
        if (token.energy != maxEnergy) {
            uint256 r = (block.timestamp - token.fightAt) / energyCD;
            if (token.energy + r < maxEnergy) {
                fightAt = token.fightAt + (r * energyCD);
                energy = token.energy + r;
                return (fightAt,energy,token.levelCode);
            }
        }
        return (block.timestamp,maxEnergy,token.levelCode);
    }

    function getWRR(uint256 mission, uint256 levelCode) public view returns(uint256 winRate, uint256 reward) {
        Level memory l = levelInfo[levelCode / 100];
        winRate = missionInfo[mission].winRate + l.winRateAdd;
        if (winRate > 100) {
            winRate = 100;
        }
        reward = missionInfo[mission].reward * (l.rewardAdd + 100) / 100;
        return (winRate,reward);
    }

    function getSupplyInfo() external view returns (uint256 fee, uint256 supply) {
        return (chestFee,chestSupply);
    }

    function setEnergyInfo(uint256 max,uint256 coolDown) external onlyOwner{
        maxEnergy = max;
        energyCD = coolDown;
    }

    function setFeeAccount(address account) external onlyOwner {
        require(account != address(0),"zero address");
        feeAccount = account;
    }
    function setContractCallable(bool enable) external onlyOwner {
        contractCallable = enable;
    }

    function setRandom(address r) public onlyOwner {
        random = IRandom(r);
    }

    function setClaimFeeInfo(uint256 rate, uint256 coolDown) external onlyOwner {
        claimFeeRate = rate;
        claimCD = coolDown;
    }
    function setChestSupply(uint256 supply, uint256 fee,uint256[] memory levelCode,uint256[] memory openRate) external onlyOwner {

        require(levelCode.length == openRate.length, "rewrite it");
        chestSupply = supply;
        chestFee = fee;
        uint levelOffset;
        for (uint256 i=0; i<levelCode.length; i++){

            levelOffset += openRate[i];
            require(levelCode[i] >= 100*(i+1) && levelCode[i] < 100*(i+2));
            levelInfo[i+1].code = levelCode[i];
            levelInfo[i+1].levelOffset = levelOffset;
        }
    }
    function setLevelInfo(uint256 level, uint256 winRateAdd, uint256 rewardAdd) public onlyOwner {
        levelInfo[level].winRateAdd = winRateAdd;
        levelInfo[level].rewardAdd = rewardAdd;
    }
    function setMissionInfo(uint256 mission, uint256 winRate, uint256 reward) public onlyOwner {
        missionInfo[mission].winRate = winRate;
        missionInfo[mission].reward = reward;
    }
    function setComptroller(address c) external onlyOwner {
        LOS20Miner = ILOS20Miner(c);
    }




    struct ReMintInfo {
        uint fee;
        uint offset1;
        uint offset2;
        uint offset3;
        uint offset4;
        uint offsetChest;
        uint count;
    }
    mapping(uint=>ReMintInfo) public reMintInfo;


    function reMint(uint256 tokenId) external {

        require(LOS721.ownerOf(tokenId) == msg.sender, "not yours");

        (,uint256 energy, uint256 levelCode)= getTokenInfo(tokenId);
        require(energy == maxEnergy, "rest awhile");
        require(levelCode >= 100,"wrong method");

        uint level = levelCode/100;
        uint reMintFee = reMintInfo[level].fee;
        require(reMintFee >= 0,"not allowed");

        LOS20.transferFrom(msg.sender,address(this),reMintFee);
        tokenInfo[tokenId].levelCode = level;

        random.requestRandomness(tokenId);
        reMintInfo[level].count += 1;

        emit ReMint(msg.sender,reMintFee,tokenId);
    }

    function reOpen(uint256 tokenId) external {

        uint levelCode = tokenInfo[tokenId].levelCode;

        require(LOS721.ownerOf(tokenId) == msg.sender, "not yours");
        require(levelCode > 0 && levelCode < 4, "wrong method");

        (bool succ, uint r) = random.openRand(tokenId);
        require(succ,"try later");

        ReMintInfo memory info = reMintInfo[levelCode];

        if (r < info.offset1) {
            levelCode = 100;
        }else if (r < info.offset2) {
            levelCode = 200;
        }else if (r < info.offset3) {
            levelCode = 300;
        }else if (r < info.offset4) {
            levelCode = 400;
        }else if (r <  info.offsetChest) {
            random.requestRandomness(tokenId);
            levelCode = 10;
        }else {
            require(false,"unexpected rand");
        }

        tokenInfo[tokenId].energy = maxEnergy;
        tokenInfo[tokenId].levelCode = levelCode;

        emit ReOpen(msg.sender,levelCode,tokenId);
    }

    function isContract(address account) view public returns(bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setReMintInfo(uint256 level, uint256 fee,uint[5] memory rate) public onlyOwner {

        require(rate.length == 5, "rewrite it");

        uint offset = rate[0];
        reMintInfo[level].fee = fee;
        reMintInfo[level].offset1 = offset;
        offset += rate[1];
        reMintInfo[level].offset2 = offset;
        offset += rate[2];
        reMintInfo[level].offset3 = offset;
        offset += rate[3];
        reMintInfo[level].offset4 = offset;
        offset += rate[4];
        reMintInfo[level].offsetChest = offset;
    }
}