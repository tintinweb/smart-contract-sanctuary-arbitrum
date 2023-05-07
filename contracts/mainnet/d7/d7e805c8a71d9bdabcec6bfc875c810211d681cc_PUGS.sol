// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './SafeMath.sol';
import './Ownable.sol';
import './IERC20.sol';

pragma experimental ABIEncoderV2;

contract PUGS is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    address private constant exchangeAddr = 0x6fD706029c7402F08FB1cC06374A1B47c5F36223;
    address private constant airdropAddr = 0xE62D135a12F81Ad9c6572F93C07B26c27D4f4f85;

    address private constant ecologyAddr = 0xDa7096bd0F62668ccF5E234335CE3a6873483B3C;
    address private constant lpAddr = 0x4920f707354AfD37f65951F27eCb1D7eD74f9B11;
    address private constant holdingAddr = 0x15E65Dd777876495D469E60A5F1EBB09132036fF;
    
    uint256 public lpTotal;
    uint256 public holdingTotal;
    uint256 public currSeqNum;

    struct Record {
        uint256 baseAmount;
        uint256 withdrawn;
        uint256 undrawn;
        bool hasGet;
        uint256 lpShared;
        uint256 holdingShared;
        uint256 lpReward;
        uint256 holdingReward;
    }
    mapping(address => Record) private records;

    mapping(uint256 => bool) private saltUsed;

    mapping(address => mapping(address => bool)) private inviteRewards;

    address private lpAddress;

    string private constant DOMAIN_NAME = "PUGS Protocol";
    bytes32 private DOMAIN_SEPARATOR;

    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        abi.encodePacked("Permit(address inviter,address signer,address account,uint256 ranking,uint256 deadline,uint256 salt)")
    );

    address private authorizer;

    uint256 public currBlackSeq;
    mapping (address => bool) private blacklist;
    mapping (uint256 => address) private blacks;

    constructor(uint256 liquidityAmount,uint256 exchangeAmount) public {
        _name     = "PUGS";
        _symbol   = "PUGS";
        _decimals = 6;

        _mint(0x4d635751999e8b1B0038d75A56127f2771556046, liquidityAmount);
        _mint(exchangeAddr, exchangeAmount);
        _mint(airdropAddr, exchangeAmount);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,address verifyingContract)'),
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes('1')),
                address(this)
            )
        );
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function setAuthorizer(address _authorizer) public onlyOwner {
        require(_authorizer != address(0), "PUGS: invalid authorizer");
        authorizer = _authorizer;
    }

    function setBlack(address _black) public onlyOwner {
        require(!blacklist[_black], "Has been added to blacklist");
        blacklist[_black] = true;

        blacks[currBlackSeq] = _black;
        currBlackSeq++;
    }

    function removeBlack(address _black) public onlyOwner {
        require(blacklist[_black], "Not exist on the blacklist");
        blacklist[_black] = false;
    }

    function getBlack(uint256 _index) public view returns (address, bool)  {
        address _black = blacks[_index];
        return (_black, blacklist[_black]);
    }

    function setLpToken(address _lpAddr) public onlyOwner {
        lpAddress = _lpAddr;
    }

    function getRecordInfo(address account) public view returns (Record memory) {
        return records[account];
    }

    function getStatisticInfo(address account) public view returns (Record memory) {
        Record memory info = records[account];
        uint256 newLpShare = 0;
        uint256 newHoldingShare = 0;
        uint256 lpBal = 0;
        if(lpAddress != address(0)) {
            lpBal = IERC20(lpAddress).balanceOf(account);
        }
        if(lpBal>0&&lpTotal>0) {
            newLpShare = lpTotal.sub(info.lpShared).mul(lpBal).div(IERC20(lpAddress).totalSupply());
        }
        uint256 holdBal = this.balanceOf(account);
        if(holdBal>0&&holdingTotal>0) {
            newHoldingShare = holdingTotal.sub(info.holdingShared).mul(holdBal).div(totalSupply());
        }
        info.lpReward = newLpShare;
        info.holdingReward = newHoldingShare;

        return info;
    }

    function claim(address inviter,uint256 ranking,
    uint256 deadline,uint256 salt,
    uint8 v,bytes32 r,bytes32 s) external {
        require(!blacklist[msg.sender], "You have been blacklisted");

        Record storage info = records[msg.sender];
        require(!info.hasGet, "The airdrop has been claimed");

        permit(inviter,authorizer, msg.sender, ranking, deadline, salt, v, r, s);

        uint256 baseAmount = 10**uint256(_decimals);
        if(ranking==1) {
            currSeqNum++;
            if(currSeqNum<=5000) {
                baseAmount = baseAmount.mul(21).mul(10**10);
            } else {
                baseAmount = baseAmount.mul(10**8);
            }
        } else {
             baseAmount = baseAmount.mul(10**7);
        }

        if(inviter!=address(0)&&!inviteRewards[msg.sender][inviter]) {
            Record storage fatherInfo = records[inviter];
            fatherInfo.undrawn = fatherInfo.undrawn.add(baseAmount.div(10));
            inviteRewards[msg.sender][inviter] = true;
        }
        info.baseAmount = baseAmount;
        info.withdrawn = info.withdrawn.add(baseAmount);
        info.hasGet = true;

        _balances[airdropAddr] = _balances[airdropAddr].sub(baseAmount, "ERC20: transfer amount exceeds balance");
        _balances[msg.sender] = _balances[msg.sender].add(baseAmount);
        emit Transfer(airdropAddr, msg.sender, baseAmount);
    }

    function withdraw() external {
        require(!blacklist[msg.sender], "You have been blacklisted");
        Record storage info = records[msg.sender];
        
        uint256 newLpShare = 0;
        uint256 newHoldingShare = 0;
        uint256 lpBal = 0;
        if(lpAddress != address(0)) {
            lpBal = IERC20(lpAddress).balanceOf(msg.sender);
        }
        if(lpBal>0&&lpTotal>0) {
            newLpShare = lpTotal.sub(info.lpShared).mul(lpBal).div(IERC20(lpAddress).totalSupply());
        }
        uint256 holdBal = this.balanceOf(msg.sender);
        if(holdBal>0&&holdingTotal>0) {
            newHoldingShare = holdingTotal.sub(info.holdingShared).mul(holdBal).div(totalSupply());
        }
        require((info.undrawn>0||newLpShare>0||newHoldingShare>0), "No balance for withdrawal");

        uint256 amount = info.undrawn.add(newLpShare).add(newHoldingShare);

        if(info.undrawn>0) {
            emit Transfer(airdropAddr, msg.sender, info.undrawn);
        }
        if(newLpShare>0) {
            emit Transfer(lpAddr, msg.sender, newLpShare);
        }
        if(newHoldingShare>0) {
            emit Transfer(holdingAddr, msg.sender, newHoldingShare);
        }

        _balances[airdropAddr] = _balances[airdropAddr].sub(info.undrawn, "ERC20: not enough exceeds balance from airdrop");
        _balances[lpAddr] = _balances[lpAddr].sub(newLpShare, "ERC20: not enough balance from Lp Share");
        _balances[holdingAddr] = _balances[holdingAddr].sub(newHoldingShare, "ERC20: not enough balance from hold coin share");
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        info.withdrawn = info.withdrawn.add(amount);
        info.undrawn = 0;
        info.lpShared = lpTotal;
        info.holdingShared = holdingTotal;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(!blacklist[sender], "You have been blacklisted");
        require(!blacklist[recipient], "You have been blacklisted");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 ecologyCoins = amount.mul(199).div(10000);
        uint256 coins = amount.mul(100).div(10000);
        uint256 bal = amount.sub(ecologyCoins).sub(3*coins);

        _balances[ecologyAddr] = _balances[ecologyAddr].add(ecologyCoins);
        emit Transfer(sender, ecologyAddr, ecologyCoins);
        _balances[lpAddr] = _balances[lpAddr].add(coins);
        emit Transfer(sender, lpAddr, coins);
        _balances[holdingAddr] = _balances[holdingAddr].add(coins);
        emit Transfer(sender, holdingAddr, coins);

        lpTotal = lpTotal.add(coins);
        holdingTotal = holdingTotal.add(coins);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(bal);
        emit Transfer(sender, recipient, bal);

        _totalSupply = _totalSupply.sub(coins);
        emit Transfer(sender, address(0), coins);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function permit(
        address inviter,
        address signer,
        address account,
        uint256 ranking,
        uint256 deadline,
        uint256 salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(saltUsed[salt] == false, "PUGS: Salt has be used");
        require(deadline >= block.timestamp, "PUGS: Transaction expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, inviter, signer, account, ranking, deadline, salt))
            )
        );
        require(deadline == 0 || now <= deadline, "PUGS/permit-expired");
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == signer, "PUGS: invalid signatrue");

        saltUsed[salt] = true;
    }

}