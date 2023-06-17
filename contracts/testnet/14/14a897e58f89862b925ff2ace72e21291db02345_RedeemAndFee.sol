/**
 *Submitted for verification at Arbiscan on 2023-06-17
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.11;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IFractionalNFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function _tokenIds() external view returns (uint256);
}

interface INodeNFT {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface ITopNFTLister {
    function balanceOf(address owner) external view returns (uint256 balance);
    function _tokenIds() external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RedeemAndFee is Ownable {
    uint public regularNFTFee = 2;
    uint public fractionNFTFee = 3;
    uint public privateNFTFee = 5;

    uint _marketplaceGenesisNFT_portion = 10;
    uint _fnft_wl_portion = 10;
    uint _nodenft_wl_portion = 10;
    uint _cheemsx_wl_portion = 10;
    uint _topNftLister_wl_portion = 10;
    uint _nftAngles_wl_portion = 10;
    uint _nftInfluencer_wl_portion = 10;

    uint node_total_supply = 10000;

    mapping (address=>uint) _marketplaceGenesisNFT_WL;
    mapping (address=>uint) _fnft_wl;
    mapping (address=>uint) _nodenft_wl;
    mapping (address=>uint) _cheemsx_wl;
    mapping (address=>uint) _topNftLister_wl;
    address[] _topNftLister;
    mapping (address=>uint) _nftAngles_wl;
    mapping (address=>uint) _nftInfluencer_wl;
    mapping (address=>bool) _blackList;
    mapping (address=>bool) _unclassifiedList;

    uint cnt_topNftLister_wl;
    uint cnt_nftAngles_wl;
    uint cnt_nftInfluencer_wl;
    uint cnt_fnft_wl;
    uint cnt_nodenft_wl;
    uint cnt_cheemsx_wl;
    uint cnt_marketplaceGenesisNFT_WL;

    bool isCheemsxAddress;
    bool isfNFT;
    bool isNodeNFT;

    address _marketplaceGenesisNFT;
    address _fNFT;
    address _nodeNFT;
    address _cheemsxAddress;
    address public marketPlace;
    address public FNFTmarketPlace;

    bool public _isDistribute;

    uint _threshold = 10 * 10 ** 18;
    uint _claimableThreshold = 20 * 10 ** 18;

    mapping(address=>bool) _MarketWideDiscountedTransactionFees;     // If trasnaction fee is usually 2%, for thses wallets transaction fee will be 50% less, that means 1%

    mapping(address=>bool) _MarketWideNoFEEforTransaction;       // no fee
    mapping(address => bool) _ableToCreatePrivateNFTforSale;

    uint public step = 1;
    uint currentVal;

    uint256 public flatFee = 15 * 10**16; // default fee 0.15 avax

    constructor() {
        // _fNFT = 0xAAF9591d9E62aCB8061599671f3788A875ced8D9;
        // _nodeNFT = 0x8138822fB2f421a25E4AE483D1570Bd2406f94aA;
        // _cheemsxAddress = 0x1F3fa5ba82eCfE38EB16d522377807Bc0F8C8519;
    }

    // ====================== get functions ===============

    function MarketWideDiscountedTransactionFees(address user) public view returns(bool) {
        return _MarketWideDiscountedTransactionFees[user];
    }

    function MarketWideNoFEEforTransaction(address user) public view returns(bool) {
        return _MarketWideNoFEEforTransaction[user];
    }

    // ============================ set functions =====================

    function setRegularNFTFee (uint _fee) public onlyOwner {
        regularNFTFee = _fee;
    }

    function setFractionNFTFee (uint _fee) public onlyOwner {
        fractionNFTFee = _fee;
    }

    function setPrivateNFTFee (uint _fee) public onlyOwner {
        privateNFTFee = _fee;
    }

    function setFlatFee(uint256 _fee) public onlyOwner {
        flatFee = _fee;
    }

    function add_marketplaceGenesisNFT_WL(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_marketplaceGenesisNFT_WL[user[i]] == 0) {
                    cnt_marketplaceGenesisNFT_WL++;
                }
                _marketplaceGenesisNFT_WL[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_marketplaceGenesisNFT_WL[user[i]] != 0) {
                    cnt_marketplaceGenesisNFT_WL--;
                }
            }
        }
        
    }

    function add_fnft_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_fnft_wl[user[i]] == 0) {
                    cnt_fnft_wl++;
                    if(user[i] == _fNFT){
                        isfNFT = true;
                    }
                }
                _fnft_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_fnft_wl[user[i]] != 0) {
                    cnt_fnft_wl--;
                    if(user[i] == _fNFT){
                        isfNFT = true;
                    }
                }
            }
        }
    }

    function add_nodenft_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nodenft_wl[user[i]] == 0) {
                    cnt_nodenft_wl++;
                    if(user[i] == _nodeNFT){
                        isNodeNFT = true;
                    }
                }
                _nodenft_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nodenft_wl[user[i]] != 0) {
                    cnt_nodenft_wl--;
                    if(user[i] == _nodeNFT){
                        isNodeNFT = true;
                    }
                }
            }
        }
    }

    function add_cheemsx_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_cheemsx_wl[user[i]] == 0) {
                    cnt_cheemsx_wl++;
                    if(user[i] == _cheemsxAddress){
                        isCheemsxAddress = true;
                    }
                }
                _cheemsx_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_cheemsx_wl[user[i]] != 0) {
                    cnt_cheemsx_wl--;
                    if(user[i] == _cheemsxAddress){
                        isCheemsxAddress = false;
                    }
                }
            }
        }
    }

    function add_topNftLister_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_topNftLister_wl[user[i]] == 0) {
                    cnt_topNftLister_wl++;
                    _topNftLister.push(user[i]);
                }
                _topNftLister_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_topNftLister_wl[user[i]] != 0) {
                    cnt_topNftLister_wl--;
                    for(uint j = 0; j < _topNftLister.length; j++) {
                        if (user[i] == _topNftLister[j]) {
                            _topNftLister[j] = _topNftLister[_topNftLister.length-1];
                            _topNftLister.pop();
                            break;
                        }
                    }

                }
            }
        }
    }

    function add_nftAngles_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nftAngles_wl[user[i]] == 0) {
                    cnt_nftAngles_wl++;
                }
                _nftAngles_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nftAngles_wl[user[i]] != 0) {
                    cnt_nftAngles_wl--;
                }
            }
        }
    }

    function add_nftInfluencer_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nftInfluencer_wl[user[i]] == 0) {
                    cnt_nftInfluencer_wl++;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = true;
                    // }
                }
                _nftInfluencer_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nftInfluencer_wl[user[i]] != 0) {
                    cnt_nftInfluencer_wl--;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = false;
                    // }
                }
            }
        }
    }

    function set_marketplaceGenesisNFT(address _contractAddress) public onlyOwner {
        _marketplaceGenesisNFT = _contractAddress;
    } 

    function set_fNFT(address _contractAddress) public onlyOwner {
        _fNFT = _contractAddress;
    } 

    function set_nodeNFT(address _contractAddress) public onlyOwner {
        _nodeNFT = _contractAddress;
    } 

    function set_cheemsxAddress(address _contractAddress) public onlyOwner {
        _cheemsxAddress = _contractAddress;
    } 

    function setDistribute (bool flag) public onlyOwner {
        _isDistribute = flag;
    }

    function set_MarketWideDiscountedTransactionFees(address user, bool flag) public onlyOwner {
        _MarketWideDiscountedTransactionFees[user] = flag;
    }

    function set_MarketWideNoFEEforTransaction(address user, bool flag) public onlyOwner {
        _MarketWideNoFEEforTransaction[user] = flag;
    }

    function setMarketPlace (address _maketAddr) public onlyOwner {
        marketPlace = _maketAddr;
    }

    function setFNFTMarketPlace (address _maketAddr) public onlyOwner {
        FNFTmarketPlace = _maketAddr;
    }

    function accumulateTransactionFee(address user, uint royaltyFee, uint amount) external returns(uint transactionFee, uint, uint income) {
        //require((marketPlace == msg.sender) || (FNFTmarketPlace == msg.sender), "REDEEM_AND_FEE: not permission");
        transactionFee = decisionTransactionFee(user) * amount / 100;
        currentVal += transactionFee;
        income = amount - transactionFee - amount * royaltyFee / 100;
        if (currentVal > _claimableThreshold) {
            step += currentVal / _claimableThreshold;
            currentVal = currentVal % _claimableThreshold;
        }
        return (transactionFee, amount * royaltyFee / 100, income);
    }

    function unCliamedReward(address user) external view returns(uint amount) {
        if(_marketplaceGenesisNFT_WL[user] < step && _marketplaceGenesisNFT_WL[user] > 0) {
            
        }
        
        if(isfNFT) {
            uint total = IFractionalNFT(_fNFT)._tokenIds();
            uint balance = IFractionalNFT(_fNFT).balanceOf(user);
            uint step_cnt = _fnft_wl[user] != 0 ? step - _fnft_wl[user] : step - _fnft_wl[_fNFT];
            if(total != 0 && step_cnt != 0) 
                amount += _claimableThreshold / 7 * balance / total * step_cnt;
        } else {
            if(_fnft_wl[user] < step && _fnft_wl[user] > 0) {
                uint step_cnt = step - _fnft_wl[user];
                amount += _claimableThreshold / 7 / cnt_fnft_wl * step_cnt;
            }
        }

        if(isNodeNFT) {
            uint balance = INodeNFT(_nodeNFT).balanceOf(user);
            uint step_cnt = _nodenft_wl[user] != 0 ? step - _nodenft_wl[user] : step - _nodenft_wl[_nodeNFT];
            if(step_cnt != 0)
                amount += _claimableThreshold / 7 * balance / node_total_supply * step_cnt;
        } else {
            if(_nodenft_wl[user] < step && _nodenft_wl[user] > 0) {
                uint step_cnt = step - _nodenft_wl[user];
                amount += _claimableThreshold / 7 / cnt_nodenft_wl * step_cnt;
            }
        }

        if(isCheemsxAddress) {
            uint balance = IERC20(_cheemsxAddress).balanceOf(user);
            uint total = IERC20(_cheemsxAddress).totalSupply();
            uint step_cnt = _cheemsx_wl[user] != 0 ? step - _cheemsx_wl[user] : step - _cheemsx_wl[_cheemsxAddress];
            if(step_cnt != 0)
                amount += _claimableThreshold / 7 * balance / total * step_cnt;
        } else {
            if(_cheemsx_wl[user] < step && _cheemsx_wl[user] > 0) {
                uint step_cnt = step - _cheemsx_wl[user];
                amount += _claimableThreshold / 7 / cnt_cheemsx_wl * step_cnt;
            }
        }

        uint _bal;
        uint[] memory _stepList = new uint[](_topNftLister.length);
        uint[] memory _totalList = new uint[](_topNftLister.length);
        uint[] memory _balanceList = new uint[](_topNftLister.length);
        uint index = 0;
        for(uint i = 0 ; i < _topNftLister.length; i++) {
            if(isContract(_topNftLister[i])) {
                if(ITopNFTLister(_topNftLister[i]).balanceOf(user) > 0) {
                    _stepList[index] = _topNftLister_wl[_topNftLister[i]] < _topNftLister_wl[user] ? _topNftLister_wl[user] : _topNftLister_wl[_topNftLister[i]];
                    _totalList[index] = ITopNFTLister(_topNftLister[i])._tokenIds();
                    _balanceList[index++] = ITopNFTLister(_topNftLister[i]).balanceOf(user);
                }
            }
            if(_topNftLister[i] == user) {
                _bal++;
            }
        }

        if(_topNftLister_wl[user] < step && _topNftLister_wl[user] > 0) {
            amount += _claimableThreshold / 7 / _topNftLister.length * _bal * (step - _topNftLister_wl[user]) ;
        }

        for(uint i = 0; i < index; i++) {
            amount += _claimableThreshold / 7 / _topNftLister.length * _bal * _balanceList[i] / _totalList[i] * (step - _stepList[i]);
        }
        
        if(_nftAngles_wl[user] < step && _nftAngles_wl[user] > 0) {
            uint step_cnt = step - _nftAngles_wl[user];
            amount += _claimableThreshold / 7 / cnt_nftAngles_wl * step_cnt;
        }
        if(_nftInfluencer_wl[user] < step && _nftInfluencer_wl[user] > 0) {
            uint step_cnt = step - _nftInfluencer_wl[user];
            amount += _claimableThreshold / 7 / cnt_nftInfluencer_wl * step_cnt;
        }
        return amount;
    }

    function claim(address user) external {
        require(_isDistribute, "REDEEM_AND_FEE: not config");
        require((marketPlace == msg.sender) || (FNFTmarketPlace == msg.sender), "REDEEM_AND_FEE: not permission");
        if(_marketplaceGenesisNFT_WL[user] < step && _marketplaceGenesisNFT_WL[user] > 0) {
            
        }
        
        if(isfNFT) {
            uint total = IFractionalNFT(_fNFT)._tokenIds();
            uint balance = IFractionalNFT(_fNFT).balanceOf(user);
            uint step_cnt = _fnft_wl[user] != 0 ? step - _fnft_wl[user] : step - _fnft_wl[_fNFT];
            uint amount = _claimableThreshold / 7 * balance / total * step_cnt;
            if(amount > 0) _fnft_wl[user] = step;
        } else {
            if(_fnft_wl[user] < step && _fnft_wl[user] > 0) {
                uint step_cnt = step - _fnft_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_fnft_wl * step_cnt;
                if(amount > 0) _fnft_wl[user] = step;
            }
        }

        if(isNodeNFT) {
            uint balance = INodeNFT(_nodeNFT).balanceOf(user);
            uint step_cnt = _nodenft_wl[user] != 0 ? step - _nodenft_wl[user] : step - _nodenft_wl[_nodeNFT];
            uint amount = _claimableThreshold / 7 * balance / node_total_supply * step_cnt;
            if(amount > 0) _nodenft_wl[user] =step;
        } else {
            if(_nodenft_wl[user] < step && _nodenft_wl[user] > 0) {
                uint step_cnt = step - _nodenft_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_nodenft_wl * step_cnt;
                if(amount > 0) _nodenft_wl[user] =step;
            }
        }

        if(isCheemsxAddress) {
            uint balance = IERC20(_cheemsxAddress).balanceOf(user);
            uint total = IERC20(_cheemsxAddress).totalSupply();
            uint step_cnt = _cheemsx_wl[user] != 0 ? step - _cheemsx_wl[user] : step - _cheemsx_wl[_cheemsxAddress];
            uint amount = _claimableThreshold / 7 * balance / total * step_cnt;
            if(amount > 0) _cheemsx_wl[user] = step;
        } else {
            if(_cheemsx_wl[user] < step && _cheemsx_wl[user] > 0) {
                uint step_cnt = step - _cheemsx_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_cheemsx_wl * step_cnt;
                if(amount > 0) _cheemsx_wl[user] = step;
            }
        }
        
        uint _bal;
        uint[] memory _stepList = new uint[](_topNftLister.length);
        uint[] memory _totalList = new uint[](_topNftLister.length);
        uint[] memory _balanceList = new uint[](_topNftLister.length);
        uint index = 0;
        uint _amount;
        for(uint i = 0 ; i < _topNftLister.length; i++) {
            if(isContract(_topNftLister[i])) {
                if(ITopNFTLister(_topNftLister[i]).balanceOf(user) > 0) {
                    _stepList[index] = _topNftLister_wl[_topNftLister[i]];
                    _totalList[index] = ITopNFTLister(_topNftLister[i])._tokenIds();
                    _balanceList[index++] = ITopNFTLister(_topNftLister[i]).balanceOf(user);
                }
            }
            if(_topNftLister[i] == user) {
                _bal++;
            }
        }

        if(_topNftLister_wl[user] < step && _topNftLister_wl[user] > 0) {
            _amount += _claimableThreshold / 7 / _topNftLister.length * _bal * (step - _topNftLister_wl[user]) ;
        }

        for(uint i = 0; i < index; i++) {
            _amount += _claimableThreshold / 7 / _topNftLister.length * _bal * _balanceList[i] / _totalList[i] * (step - _stepList[i]);
        }

        if(_amount > 0) _topNftLister_wl[user] = step;

        if(_nftAngles_wl[user] < step && _nftAngles_wl[user] > 0) {
            uint step_cnt = step - _nftAngles_wl[user];
            uint amount = _claimableThreshold / 7 / cnt_nftAngles_wl * step_cnt;
            if(amount > 0) _nftAngles_wl[user] = step;
        }
        if(_nftInfluencer_wl[user] < step && _nftInfluencer_wl[user] > 0) {
            uint step_cnt = step - _nftInfluencer_wl[user];
            uint amount = _claimableThreshold / 7 / cnt_nftInfluencer_wl * step_cnt;
            if(amount > 0) _nftInfluencer_wl[user] = step;
        }
    }

    function decisionTransactionFee(address user) private view returns(uint) {
        uint fee = regularNFTFee;
        if(_MarketWideDiscountedTransactionFees[user]) fee = fee / 2;
        if(_MarketWideNoFEEforTransaction[user]) fee = 0;
        return fee;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setBlackList(address user, bool flag) external onlyOwner {
        _blackList[user] = flag;
    }

    function getBlackList (address user) external view returns(bool) {
        return _blackList[user];
    }

    function ableToCreatePrivateNFTforSale(address user) external view returns (bool) {
        return _ableToCreatePrivateNFTforSale[user];
    }

    function setAbleToCreatePrivateNFTforSale(address user, bool flag) external onlyOwner {
        _ableToCreatePrivateNFTforSale[user] = flag;
    }

    function ableToViewALLPrivateMetadata(address user) external view returns (bool) {
        return _nftAngles_wl[user] > 0 ? true : false;
    }

    function setUnclassifiedList(address user, bool flag) external onlyOwner {
        _unclassifiedList[user] = flag;
    }

    function unclassifiedList(address user) external view returns (bool) {
        return _unclassifiedList[user];
    }

}